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

FileIo::FileIo(): m_watcher(new QFileSystemWatcher(this))
{
	connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &FileIo::fileChanged);
}

void FileIo::openFileBrowser(QString const& _dir)
{
	QDesktopServices::openUrl(QUrl(_dir));
}

QString FileIo::pathFromUrl(QString const& _url)
{
	QUrl url(_url);
	QString path(url.path());
	if (url.scheme() == "qrc")
		path = ":" + path;
#ifdef WIN32
	if (url.scheme() == "file")
	{
		if (path.startsWith("/"))
			path = path.right(path.length() - 1);
		if (!url.host().isEmpty())
			path = url.host() + ":/" + path;
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return QString();
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return QString();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return QString();
	}
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
	}
}

bool FileIo::fileExists(QString const& _url)
{
	try
	{
		QFile file(pathFromUrl(_url));
		return file.exists();
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return false;
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return false;
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return false;
	}
}

QStringList FileIo::makePackage(QString const& _deploymentFolder)
{
	try
	{
		Json::Value manifest;
		Json::Value entries(Json::arrayValue);

		QDir deployDir = QDir(pathFromUrl(_deploymentFolder));
		dev::RLPStream rlpStr;
		int k = 1;
		std::vector<bytes> files;
		QMimeDatabase mimeDb;
		for (auto item: deployDir.entryInfoList(QDir::Files))
		{
			QFile qFile(item.filePath());
			if (qFile.open(QIODevice::ReadOnly))
			{
				k++;
				QFileInfo fileInfo = QFileInfo(qFile.fileName());
				Json::Value jsonValue;
				std::string path = fileInfo.fileName() == "index.html" ? "/" : fileInfo.fileName().toStdString();
				jsonValue["path"] = path; //TODO: Manage relative sub folder
				jsonValue["file"] = "/" + fileInfo.fileName().toStdString();
				jsonValue["contentType"] = mimeDb.mimeTypeForFile(qFile.fileName()).name().toStdString();
				QByteArray a = qFile.readAll();
				bytes data = bytes(a.begin(), a.end());
				files.push_back(data);
				jsonValue["hash"] = toHex(dev::sha3(data).ref());
				entries.append(jsonValue);
			}
			qFile.close();
		}
		rlpStr.appendList(k);

		manifest["entries"] = entries;
		std::stringstream jsonStr;
		jsonStr << manifest;
		QByteArray b =  QString::fromStdString(jsonStr.str()).toUtf8();
		rlpStr.append(bytesConstRef((const unsigned char*)b.data(), b.size()));

		for (unsigned int k = 0; k < files.size(); k++)
			rlpStr.append(files.at(k));

		bytes dapp = rlpStr.out();
		dev::h256 dappHash = dev::sha3(dapp);
		//encrypt
		KeyPair key((Secret(dappHash)));
		Secp256k1PP::get()->encrypt(key.pub(), dapp);

		QUrl url(_deploymentFolder + "package.dapp");
		QFile compressed(url.path());
		QByteArray qFileBytes((char*)dapp.data(), static_cast<int>(dapp.size()));
		if (compressed.open(QIODevice::WriteOnly | QIODevice::Truncate))
		{
			compressed.write(qFileBytes);
			compressed.flush();
		}
		else
			error(tr("Error creating package.dapp"));
		compressed.close();
		QStringList ret;
		ret.append(QString::fromStdString(toHex(dappHash.ref())));
		ret.append(qFileBytes.toBase64());
		ret.append(url.toString());
		return ret;
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return QStringList();
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return QStringList();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return QStringList();
	}
}

void FileIo::watchFileChanged(QString const& _path)
{
	try
	{
		m_watcher->addPath(pathFromUrl(_path));
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
	}
}

void FileIo::stopWatching(QString const& _path)
{
	try
	{
		m_watcher->removePath(pathFromUrl(_path));
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
	}
}

void FileIo::deleteFile(QString const& _path)
{
	try
	{
		QFile file(pathFromUrl(_path));
		file.remove();
	}
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
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
	catch (boost::exception const& _e)
	{
		std::cerr << boost::diagnostic_information(_e);
		return QUrl();
	}
	catch (std::exception const& _e)
	{
		std::cerr << _e.what();
		return QUrl();
	}
	catch (...)
	{
		std::cerr << boost::current_exception_diagnostic_information();
		return QUrl();
	}
}
