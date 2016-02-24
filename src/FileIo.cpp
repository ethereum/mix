/*
	This file is part of cpp-ethereum.

	cpp-ethereum is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	cpp-ethereum is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with cpp-ethereum.  If not, see <http://www.gnu.org/licenses/>.
*/
/** @file FileIo.cpp
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

#include <QFileSystemWatcher>
#include <QFileSystemModel>
#include <QDebug>
#include <QDesktopServices>
#include <QMimeDatabase>
#include <QDirIterator>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QUrl>
#include <json/json.h>
#include <libdevcrypto/CryptoPP.h>
#include <libdevcrypto/Common.h>
#include <libdevcore/RLP.h>
#include <libdevcore/SHA3.h>
#include "FileIo.h"

using namespace dev;
using namespace dev::crypto;
using namespace dev::mix;
using namespace std;

FileIo::FileIo(): m_watcher(new QFileSystemWatcher(this))
{
	connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &FileIo::fileChanged);
}

void FileIo::manageException()
{
	try
	{
		throw;
	}
	catch (boost::exception const& _e)
	{
		cerr << boost::diagnostic_information(_e);
		emit fileIOInternalError("Internal error: " + QString::fromStdString(boost::diagnostic_information(_e)));
	}
	catch (exception const& _e)
	{
		cerr << _e.what();
		emit fileIOInternalError("Internal error: " + QString::fromStdString(_e.what()));
	}
	catch (...)
	{
		cerr << boost::current_exception_diagnostic_information();
		emit fileIOInternalError("Internal error: " + QString::fromStdString(boost::current_exception_diagnostic_information()));
	}
}

void FileIo::openFileBrowser(QString const& _dir)
{
	QDesktopServices::openUrl(QUrl(_dir));
}

QString FileIo::pathFromUrl(QString const& _url)
{
	QUrl url(_url);
	QString path(url.path());
#if defined(_WIN32)
	if (_url.midRef(1, 1) == ":")
		path = _url.mid(0, 2).toUpper() + "\\" + path;
#endif

	if (url.scheme() == "qrc")
		path = ":" + path;
#if defined(_WIN32)
	if (url.scheme() == "file")
	{
		if (path.startsWith("/"))
		{
			path = path.remove(0, 1);
			if (path.startsWith("/"))
				path = path.remove(0, 1);
		}
		if (!url.host().isEmpty())
			path = url.host().toUpper() + ":/" + path;
	}
#endif
	return path;
}

void FileIo::makeDir(QString const& _url)
{
	try
	{
		QDir dirPath(pathFromUrl(_url));
		if (dirPath.exists())
			dirPath.removeRecursively();
		dirPath.mkpath(dirPath.path());
	}
	catch (...)
	{
		manageException();
	}
}

bool FileIo::dirExists(QString const& _url)
{
	try
	{
		QDir dirPath(pathFromUrl(_url));
		return dirPath.exists();
	}
	catch (...)
	{
		manageException();
		return false;
	}
}

void FileIo::deleteDir(QString const& _url)
{
	try
	{
		QDir dirPath(pathFromUrl(_url));
		if (dirPath.exists())
			dirPath.removeRecursively();
	}
	catch (...)
	{
		manageException();
	}
}

QString FileIo::readFile(QString const& _url)
{
	try
	{
		QFile file(pathFromUrl(_url));
		if (file.open(QIODevice::ReadOnly | QIODevice::Text))
		{
			QTextStream stream(&file);
			QString data = stream.readAll();
			return data;
		}
		else
			error(tr("Error reading file %1").arg(_url));
		return QString();
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

int FileIo::getFileSize(QString const& _url)
{
	try
	{
		QString path = pathFromUrl(_url);
		QFile file(path);
		return file.size();
	}
	catch (...)
	{
		manageException();
	}

	return 0;
}

void FileIo::writeFile(QString const& _url, QString const& _data)
{
	try
	{
		QString path = pathFromUrl(_url);
		m_watcher->removePath(path);
		QFile file(path);
		if (file.open(QIODevice::WriteOnly | QIODevice::Text))
		{
			QTextStream stream(&file);
			stream << _data;
		}
		else
			error(tr("Error writing file %1").arg(_url));
		file.close();
		m_watcher->addPath(path);
	}
	catch (...)
	{
		manageException();
	}
}

void FileIo::copyFile(QString const& _sourceUrl, QString const& _destUrl)
{
	try
	{
		if (QUrl(_sourceUrl).scheme() == "qrc")
		{
			writeFile(_destUrl, readFile(_sourceUrl));
			return;
		}

		if (!QFile::copy(pathFromUrl(_sourceUrl), pathFromUrl(_destUrl)))
			error(tr("Error copying file %1 to %2").arg(_sourceUrl).arg(_destUrl));
	}
	catch (...)
	{
		manageException();
	}
}

QString FileIo::getHomePath() const
{
	return QDir::homePath();
}

void FileIo::moveFile(QString const& _sourceUrl, QString const& _destUrl)
{
	try
	{
		if (!QFile::rename(pathFromUrl(_sourceUrl), pathFromUrl(_destUrl)))
			error(tr("Error moving file %1 to %2").arg(_sourceUrl).arg(_destUrl));
	}
	catch (...)
	{
		manageException();
	}
}

bool FileIo::fileExists(QString const& _url)
{
	try
	{
		QFile file(pathFromUrl(_url));
		return file.exists();
	}
	catch (...)
	{
		manageException();
		return false;
	}
}

Json::Value FileIo::generateManifest(QString const& _rootPath, QString const& _path)
{
	QMimeDatabase mimeDb;
	Json::Value entries(Json::arrayValue);
	for (auto f: files(_path))
	{
		QVariantMap map = f.toMap();
		QFile qFile(map["path"].toString());
		if (qFile.open(QIODevice::ReadOnly))
		{
			QFileInfo fileInfo = QFileInfo(qFile.fileName());
			Json::Value jsonValue;
			QString path = fileInfo.fileName() == "index.html" ? "" : fileInfo.fileName().replace(_rootPath, "");
			jsonValue["path"] = "/" + path.toStdString();
			jsonValue["file"] = fileInfo.fileName().toStdString();
			jsonValue["contentType"] = mimeDb.mimeTypeForFile(qFile.fileName()).name().toStdString();
			QByteArray a = qFile.readAll();
			bytes data = bytes(a.begin(), a.end());
			jsonValue["hash"] = toHex(dev::sha3(data).ref());
			entries.append(jsonValue);
		}
		qFile.close();
	}
	for (auto path: directories(_path))
	{
		QVariantMap map = path.toMap();
		if (map["fileName"] != ".." && map["fileName"] != ".")
		{
			Json::Value pathEntries = generateManifest(_rootPath, map["path"].toString());
			entries.append(pathEntries);
		}
	}
	return entries;
}


QStringList FileIo::makePackage(QString const& _deploymentFolder)
{
	QStringList ret;
	try
	{
		Json::Value manifest;
		QUrl url(_deploymentFolder);

		Json::Value entries = generateManifest(url.path(), url.path());

		manifest["entries"] = entries;
		stringstream jsonStr;
		jsonStr << manifest;

		writeFile(url.path() + "/manifest.json", QString::fromStdString(jsonStr.str()));

		/*
		bytes dapp = rlpStr.out();
		dev::h256 dappHash = dev::sha3(dapp);
		//encrypt
		KeyPair key((Secret(dappHash)));
		Secp256k1PP::get()->encrypt(key.pub(), dapp);
		*/

		ret.append(url.toString());
	}
	catch (...)
	{
		manageException();
	}
	return ret;
}

void FileIo::watchFileChanged(QString const& _path)
{
	try
	{
		m_watcher->addPath(pathFromUrl(_path));
	}
	catch (...)
	{
		manageException();
	}
}

void FileIo::stopWatching(QString const& _path)
{
	try
	{
		m_watcher->removePath(pathFromUrl(_path));
	}
	catch (...)
	{
		manageException();
	}
}

void FileIo::deleteFile(QString const& _path)
{
	try
	{
		QFile file(pathFromUrl(_path));
		file.remove();
	}
	catch (...)
	{
		manageException();
	}
}

QUrl FileIo::pathFolder(QString const& _path)
{
	try
	{
		QFileInfo info(_path);
		if (info.exists() && info.isDir())
			return QUrl::fromLocalFile(_path);
		return QUrl::fromLocalFile(QFileInfo(_path).absolutePath());
	}
	catch (...)
	{
		manageException();
		return QUrl();
	}
}

QVariantList FileIo::files(QString const& _root)
{
	return createSortedList(_root, QDir::Files);
}

QVariantList FileIo::directories(QString const& _root)
{
	return createSortedList(_root, QDir::AllDirs);
}

QVariantList FileIo::createSortedList(QString const& _root, QDir::Filter _filter)
{
	QDir dir = QDir(pathFromUrl(_root));
	dir.setFilter(_filter);
	dir.setSorting(QDir::Name);
	dir.setSorting(QDir::IgnoreCase);

	QFileInfoList fileInfoList = dir.entryInfoList();
	QVariantList ret;

	foreach(QFileInfo fileInfo, fileInfoList)
	{
		QVariantMap file;
		file["path"] = fileInfo.absoluteFilePath();
		file["fileName"] = fileInfo.fileName();
		ret.append(file);
	}
	return ret;
}
