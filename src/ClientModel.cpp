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
/** @file ClientModel.cpp
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

// Make sure boost/asio.hpp is included before windows.h.
#include <boost/asio.hpp>

#include "ClientModel.h"
#include <QtConcurrent/QtConcurrent>
#include <QDebug>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <jsonrpccpp/server.h>
#include <libethcore/CommonJS.h>
#include <libethcore/KeyManager.h>
#include <libsolidity/ast/Types.h>
#include <libethereum/Transaction.h>
#include <libwebthree/WebThree.h>
#include <libdevcore/FixedHash.h>
#include <libweb3jsonrpc/MemoryDB.h>
#include <libweb3jsonrpc/Web3.h>
#include "DebuggingStateWrapper.h"
#include "Exceptions.h"
#include "QContractDefinition.h"
#include "QVariableDeclaration.h"
#include "ContractCallDataEncoder.h"
#include "CodeModel.h"
#include "QEther.h"
#include "Web3Server.h"
#include "MixClient.h"

using namespace dev;
using namespace dev::eth;
using namespace dev::solidity;
using namespace std;

namespace dev
{
namespace mix
{

class RpcConnector: public jsonrpc::AbstractServerConnector
{
public:
	virtual bool StartListening() override { return true; }
	virtual bool StopListening() override { return true; }
	virtual bool SendResponse(string const& _response, void*) override
	{
		m_response = QString::fromStdString(_response);
		return true;
	}
	QString response() const { return m_response; }

private:
	QString m_response;
};

ClientModel::ClientModel():
	m_running(false)
{
	qRegisterMetaType<QBigInt*>("QBigInt*");
	qRegisterMetaType<QList<QVariableDeclaration*>>("QList<QVariableDeclaration*>");
	qRegisterMetaType<QVariableDeclaration*>("QVariableDeclaration*");
	qRegisterMetaType<QSolidityType*>("QSolidityType*");
	qRegisterMetaType<QMachineState*>("QMachineState");
	qRegisterMetaType<QInstruction*>("QInstruction");
	qRegisterMetaType<QCode*>("QCode");
	qRegisterMetaType<QCallData*>("QCallData");
	qRegisterMetaType<RecordLogEntry*>("RecordLogEntry*");
}

ClientModel::~ClientModel()
{
	m_runFuture.waitForFinished();
	QString tempDir = (
		m_dbpath != QString() ?
		QStandardPaths::writableLocation(QStandardPaths::TempLocation) + m_dbpath :
		QStandardPaths::writableLocation(QStandardPaths::TempLocation)
	);
	QDir dir(tempDir);
	dir.removeRecursively();
}

void ClientModel::manageException() const
{
	try
	{
		throw;
	}
	catch (boost::exception const& _e)
	{
		cerr << boost::diagnostic_information(_e);
		emit internalError("Internal error: " + QString::fromStdString(boost::diagnostic_information(_e)));
	}
	catch (exception const& _e)
	{
		cerr << _e.what();
		emit internalError("Internal error: " + QString::fromStdString(_e.what()));
	}
	catch (...)
	{
		cerr << boost::current_exception_diagnostic_information();
		emit internalError("Internal error: " + QString::fromStdString(boost::current_exception_diagnostic_information()));
	}
}

void ClientModel::init(QString _dbpath)
{
	try
	{
		m_dbpath = _dbpath;
		if (m_dbpath.isEmpty())
			m_client.reset(new MixClient(QStandardPaths::writableLocation(QStandardPaths::TempLocation).toStdString()));
		else
			m_client.reset(new MixClient(QStandardPaths::writableLocation(QStandardPaths::TempLocation).toStdString() + m_dbpath.toStdString()));

		m_ethAccounts = make_shared<FixedAccountHolder>([=](){return m_client.get();}, vector<KeyPair>());
		auto ethFace = new Web3Server(*m_client.get(), *m_ethAccounts.get());
		m_web3Server.reset(new ModularServer<rpc::EthFace, rpc::DBFace, rpc::Web3Face>(ethFace, new rpc::MemoryDB(), new rpc::Web3()));
		m_rpcConnectorId = m_web3Server->addConnector(new RpcConnector());
		connect(ethFace, &Web3Server::newTransaction, this, [=]() {
			onNewTransaction(RecordLogEntry::TxSource::Web3);
		}, Qt::DirectConnection);
	}
	catch (...)
	{
		manageException();
	}
}

QString ClientModel::apiCall(QString const& _message)
{
	try
	{
		auto connector = static_cast<RpcConnector*>(m_web3Server->connector(m_rpcConnectorId));
		connector->OnRequest(_message.toStdString(), nullptr);
		return connector->response();
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

void ClientModel::mine()
{
	try
	{
		if (m_mining)
			return;
		m_mining = true;
		emit miningStarted();
		emit miningStateChanged();
		m_runFuture = QtConcurrent::run([=]()
		{
			try
			{
				this_thread::sleep_for(chrono::seconds(1)); //ensure not future time
				m_client->mine();
				m_mining = false;
				emit newBlock();
				emit miningComplete();
			}
			catch (...)
			{
				m_mining = false;
				cerr << boost::current_exception_diagnostic_information();
				emit runFailed(QString::fromStdString(boost::current_exception_diagnostic_information()));
				return;
			}
			emit miningStateChanged();
		});
	}
	catch (...)
	{
		manageException();
		m_mining = false;
	}
}

QString ClientModel::newSecret()
{
	try
	{
		KeyPair a = KeyPair::create();
		return QString::fromStdString(dev::toHex(a.secret().ref()));
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

QString ClientModel::address(QString const& _secret)
{
	try
	{
		return QString::fromStdString(dev::toHex(KeyPair(Secret(_secret.toStdString())).address().ref()));
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

QString ClientModel::toHex(QString const& _int)
{
	try
	{
		return QString::fromStdString(dev::toHex(dev::u256(_int.toStdString())));
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

QString ClientModel::encodeAbiString(QString _string)
{
	try
	{
		ContractCallDataEncoder encoder;
		return QString::fromStdString(dev::toHex(encoder.encodeBytes(_string)));
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

QString ClientModel::encodeStringParam(QString const& _param)
{
	try
	{
		ContractCallDataEncoder encoder;
		return QString::fromStdString(dev::toHex(encoder.encodeStringParam(_param, 32)));
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

QStringList ClientModel::encodeParams(QVariant const& _param, QString const& _contract, QString const& _function)
{
	QStringList ret;
	try
	{
		CompiledContract const* compilerRes = m_codeModel->contract(_contract);
		QList<QVariableDeclaration*> paramsList;
		shared_ptr<QContractDefinition> contractDef = compilerRes->sharedContract();
		if (_contract == _function)
			paramsList = contractDef->constructor()->parametersList();
		else
			for (QFunctionDefinition* tf: contractDef->functionsList())
				if (tf->name() == _function)
				{
					paramsList = tf->parametersList();
					break;
				}
		if (paramsList.length() > 0)
			for (QVariableDeclaration* var: paramsList)
			{
				ContractCallDataEncoder encoder;
				QSolidityType const* type = var->type();
				QVariant value = _param.toMap().value(var->name());
				encoder.encode(value, type->type());
				ret.push_back(QString::fromStdString(dev::toHex(encoder.encodedData())));
			}
	}
	catch (...)
	{
		manageException();
	}
	return ret;
}

QVariantMap ClientModel::contractAddresses() const
{
	QVariantMap res;
	try
	{
		for (auto const& c: m_contractAddresses)
		{
			res.insert(serializeToken(c.first), QString::fromStdString(toJS(c.second))); //key will be like <Contract - 0>
			res.insert(c.first.first, QString::fromStdString(toJS(c.second))); //we keep name like Contract (compatibility with old projects)
		}
	}
	catch (...)
	{
		manageException();
	}
	return res;
}

QVariantList ClientModel::gasCosts() const
{
	QVariantList res;
	try
	{
		for (auto const& c: m_gasCosts)
			res.append(QVariant::fromValue(static_cast<int>(c)));
	}
	catch (...)
	{
		manageException();
	}
	return res;
}

void ClientModel::addAccount(QString const& _secret)
{
	try
	{
		KeyPair key(Secret(_secret.toStdString()));
		m_accountsSecret.push_back(key);
		Address address = key.address();
		m_accounts[address] = Account(u256(0), Account::NormalCreation);
		m_ethAccounts->setAccounts(m_accountsSecret);
	}
	catch (...)
	{
		manageException();
	}
}

QString ClientModel::resolveAddress(QString const& _secret)
{
	try
	{
		KeyPair key(Secret(_secret.toStdString()));
		return "0x" + QString::fromStdString(key.address().hex());
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

void ClientModel::setupScenario(QVariantMap _scenario)
{
	try
	{
		setupStarted();
		onStateReset();
		WriteGuard(x_queueTransactions);
		m_running = true;

		QVariantList blocks = _scenario.value("blocks").toList();
		QVariantList stateAccounts = _scenario.value("accounts").toList();
		QVariantList stateContracts = _scenario.value("contracts").toList();

		m_accounts.clear();
		m_accountsSecret.clear();
		for (auto const& b: stateAccounts)
		{
			QVariantMap account = b.toMap();
			Address address = {};
			if (account.contains("secret"))
			{
				KeyPair key(Secret(account.value("secret").toString().toStdString()));
				m_accountsSecret.push_back(key);
				address = key.address();
			}
			else if (account.contains("address"))
				address = Address(fromHex(account.value("address").toString().toStdString()));
			if (!address)
				continue;

			m_accounts[address] = Account(0, qvariant_cast<QEther*>(account.value("balance"))->toU256Wei(), Account::NormalCreation);
		}

		m_ethAccounts->setAccounts(m_accountsSecret);

		auto ethFace = new Web3Server(*m_client.get(), *m_ethAccounts.get());
		m_web3Server.reset(new ModularServer<rpc::EthFace, rpc::DBFace, rpc::Web3Face>(ethFace, new rpc::MemoryDB(), new rpc::Web3()));
		m_rpcConnectorId = m_web3Server->addConnector(new RpcConnector());
		connect(ethFace, &Web3Server::newTransaction, this, [=]() {
			onNewTransaction(RecordLogEntry::TxSource::Web3);
		}, Qt::DirectConnection);

		for (auto const& c: stateContracts)
		{
			QVariantMap contract = c.toMap();
			Address address = Address(fromHex(contract.value("address").toString().toStdString()));
			Account account(0, qvariant_cast<QEther*>(contract.value("balance"))->toU256Wei(), Account::ContractConception);
			bytes code = fromHex(contract.value("code").toString().toStdString());
			account.setCode(move(code));
			QVariantMap storageMap = contract.value("storage").toMap();
			for(auto s = storageMap.cbegin(); s != storageMap.cend(); ++s)
				account.setStorage(fromBigEndian<u256>(fromHex(s.key().toStdString())), fromBigEndian<u256>(fromHex(s.value().toString().toStdString())));

			m_accounts[address] = account;
		}

		bool trToExecute = false;
		for (auto const& b: blocks)
		{
			QVariantList transactions = b.toMap().value("transactions").toList();
			if (transactions.size() > 0)
			{
				m_queueTransactions.push_back(transactions);
				trToExecute = true;
			}
		}
		m_client->resetState(m_accounts, Secret(_scenario.value("miner").toMap().value("secret").toString().toStdString()));
		if (m_queueTransactions.count() > 0 && trToExecute)
		{
			m_executionCtx = ExecutionCtx::Rebuild;
			setupExecutionChain();
			processNextTransactions();
		}
		else
		{
			m_running = false;
			setupFinished();
		}
	}
	catch (...)
	{
		manageException();
		m_running = false;
	}
}

void ClientModel::setupExecutionChain()
{
	connect(this, &ClientModel::newBlock, this, &ClientModel::processNextTransactions, Qt::QueuedConnection);
	connect(this, &ClientModel::runFailed, this, &ClientModel::stopExecution, Qt::QueuedConnection);
	connect(this, &ClientModel::runStateChanged, this, &ClientModel::finalizeBlock, Qt::QueuedConnection);
}

void ClientModel::stopExecution()
{
	disconnect(this, &ClientModel::newBlock, this, &ClientModel::processNextTransactions);
	disconnect(this, &ClientModel::runStateChanged, this, &ClientModel::finalizeBlock);
	disconnect(this, &ClientModel::runFailed, this, &ClientModel::stopExecution);
	m_running = false;
	if (m_executionCtx == ExecutionCtx::Rebuild)
		setupFinished();
	m_executionCtx = ExecutionCtx::Idle;
}

void ClientModel::finalizeBlock()
{
	if (m_queueTransactions.size() > 0)
		m_queueTransactions.pop_front();// pop last execution group. The last block is never mined (pending block)
	if (m_queueTransactions.size() > 0)
		mine();
	else
	{
		stopExecution();
		emit runComplete();
	}
}

TransactionSettings ClientModel::transaction(QVariant const& _tr) const
{
	QVariantMap transaction = _tr.toMap();
	QString contractId = transaction.value("contractId").toString();
	QString functionId = transaction.value("functionId").toString();
	bool gasAuto = transaction.value("gasAuto").toBool();
	u256 gas = 0;
	if (transaction.value("gas").data())
		gas = boost::get<u256>(qvariant_cast<QBigInt*>(transaction.value("gas"))->internalValue());
	else
		gasAuto = true;

	u256 value = (qvariant_cast<QEther*>(transaction.value("value")))->toU256Wei();
	u256 gasPrice = (qvariant_cast<QEther*>(transaction.value("gasPrice")))->toU256Wei();
	QString sender = transaction.value("sender").toString();
	bool isContractCreation = transaction.value("isContractCreation").toBool();
	bool isFunctionCall = transaction.value("isFunctionCall").toBool();
	if (contractId.isEmpty() && m_codeModel->hasContract()) //TODO: This is to support old project files, remove later
		contractId = m_codeModel->contracts().keys()[0];
	Secret f = Secret(sender.toStdString());
	TransactionSettings transactionSettings(contractId, functionId, value, gas, gasAuto, gasPrice, f, isContractCreation, isFunctionCall);
	transactionSettings.parameterValues = transaction.value("parameters").toMap();
	if (contractId == functionId || functionId == "Constructor")
		transactionSettings.functionId.clear();
	return transactionSettings;
}

void ClientModel::processNextTransactions()
{
	WriteGuard(x_queueTransactions);
	vector<TransactionSettings> transactionSequence;
	for (auto const& t: m_queueTransactions.front())
	{
		TransactionSettings transactionSettings = transaction(t);
		transactionSequence.push_back(transactionSettings);
	}
	executeSequence(transactionSequence);
}

void ClientModel::executeSequence(vector<TransactionSettings> const& _sequence)
{
	if (m_running)
	{
		qWarning() << "Waiting for current execution to complete";
		m_runFuture.waitForFinished();
	}
	emit runStarted();
	//run sequence
	m_runFuture = QtConcurrent::run([=]()
	{
		try
		{
			for (TransactionSettings const& transaction: _sequence)
			{
				pair<QString, int> ctrInstance = resolvePair(transaction.contractId);
				QString address = resolveToken(ctrInstance);
				if (!transaction.isFunctionCall)
				{
					callAddress(Address(address.toStdString()), bytes(), transaction);
					m_gasCosts.append(m_client->lastExecution().gasUsed);
					onNewTransaction(RecordLogEntry::TxSource::MixGui);
					continue;
				}
				ContractCallDataEncoder encoder;
				//encode data
				CompiledContract const* compilerRes = m_codeModel->contract(ctrInstance.first);
				QFunctionDefinition const* f = nullptr;
				shared_ptr<QContractDefinition> contractDef = compilerRes->sharedContract();
				if (transaction.functionId.isEmpty())
					f = contractDef->constructor();
				else
					for (QFunctionDefinition const* tf: contractDef->functionsList())
						if (tf->name() == transaction.functionId)
						{
							f = tf;
							break;
						}
				if (!f)
				{
					emit runFailed("Function '" + transaction.functionId + tr("' not found. Please check transactions or the contract code."));
					return;
				}
				if (!transaction.functionId.isEmpty())
					encoder.encode(f);
				for (QVariableDeclaration const* p: f->parametersList())
				{
					QSolidityType const* type = p->type();
					QVariant value = transaction.parameterValues.value(p->name());
					if (type->type().type == SolidityType::Type::Address)
					{
						if (type->array())
						{
							QJsonArray jsonDoc = QJsonDocument::fromJson(value.toString().toUtf8()).array();
							int k = 0;
							for (QJsonValue const& item: jsonDoc)
							{
								if (item.toString().startsWith("<"))
								{
									pair<QString, int> ctrParamInstance = resolvePair(item.toString());
									jsonDoc.replace(k, resolveToken(ctrParamInstance));
								}
								k++;
							}
							QJsonDocument doc(jsonDoc);
							value = QVariant(doc.toJson(QJsonDocument::Compact));
						}
						else if (value.toString().startsWith("<"))
						{
							pair<QString, int> ctrParamInstance = resolvePair(value.toString());
							value = QVariant(resolveToken(ctrParamInstance));
						}
					}
					encoder.encode(value, type->type());
				}

				if (transaction.functionId.isEmpty() || transaction.functionId == ctrInstance.first)
				{
					bytes param = encoder.encodedData();
					m_codeModel->linkLibraries(ctrInstance.first, m_deployedLibraries);
					eth::LinkerObject object = m_codeModel->contract(ctrInstance.first)->linkerObject();
					bytes contractCode = object.bytecode;
					if (!object.linkReferences.empty())
					{
						for (auto const& ref: object.linkReferences)
							emit runFailed(QString::fromStdString(ref.second));
						emit runFailed(ctrInstance.first + " deployment. Cannot link referenced libraries:");
					}
					contractCode.insert(contractCode.end(), param.begin(), param.end());
					Address newAddress = deployContract(contractCode, transaction);					
					if (compilerRes->contract()->isLibrary())
						m_deployedLibraries[ctrInstance.first] = QString::fromStdString(newAddress.hex());
					else
					{
						pair<QString, int> contractToken = retrieveToken(transaction.contractId);
						m_contractAddresses[contractToken] = newAddress;
						m_contractNames[newAddress] = contractToken.first;
						contractAddressesChanged();
					}
				}
				else
				{
					auto contractAddressIter = m_contractAddresses.find(ctrInstance);
					if (contractAddressIter == m_contractAddresses.end())
					{
						emit runFailed("Contract '" + transaction.contractId + tr(" not deployed.") + "' " + tr(" Cannot call ") + transaction.functionId);
						return;
					}
					else
						callAddress(contractAddressIter->second, encoder.encodedData(), transaction);
				}
				m_gasCosts.append(m_client->lastExecution().gasUsed);
				gasCostsChanged();
				onNewTransaction(RecordLogEntry::TxSource::MixGui);
				TransactionException exception = m_client->lastExecution().excepted;
				if (exception != TransactionException::None)
					return;
			}
			emit runComplete();
		}
		catch(boost::exception const&)
		{
			cerr << boost::current_exception_diagnostic_information();
			emit runFailed(QString::fromStdString(boost::current_exception_diagnostic_information()));
			return;
		}
		catch(exception const& e)
		{
			cerr << boost::current_exception_diagnostic_information();
			emit runFailed(e.what());
			return;
		}
		catch(...)
		{
			cerr << boost::current_exception_diagnostic_information();
			emit runFailed("Unknown Error");
			return;
		}
		emit runStateChanged();
	});
}

void ClientModel::executeTr(QVariantMap _tr)
{
	try
	{
		WriteGuard(x_queueTransactions);
		QVariantList trs;
		trs.push_back(_tr);
		m_queueTransactions.push_back(trs);
		if (!m_running)
		{
			m_running = true;
			m_executionCtx = ExecutionCtx::ExecuteTx;
			setupExecutionChain();
			processNextTransactions();
		}
	}
	catch (...)
	{
		manageException();
		m_running = false;
	}
}

pair<QString, int> ClientModel::resolvePair(QString const& _contractId)
{
	pair<QString, int> ret = make_pair(_contractId, 0);
	if (_contractId.startsWith("<") && _contractId.endsWith(">"))
	{
		QStringList values = ret.first.remove("<").remove(">").split(" - ");
		ret = make_pair(values[0], values[1].toUInt());
	}
	if (_contractId.startsWith("0x"))
		ret = make_pair(_contractId, -2);
	return ret;
}

QString ClientModel::resolveToken(pair<QString, int> const& _value)
{
	if (_value.second == -2) //-2: first contains a real address
		return _value.first;
	else if (m_contractAddresses.size() > 0 && m_contractAddresses.find(_value) != m_contractAddresses.end())
		return QString::fromStdString("0x" + dev::toHex(m_contractAddresses[_value].ref()));
	else
		return _value.first;
}

pair<QString, int> ClientModel::retrieveToken(QString const& _value)
{
	pair<QString, int> ret;
	ret.first = _value;
	ret.second = m_contractAddresses.size();
	return ret;
}

QString ClientModel::serializeToken(pair<QString, int> const& _value) const
{
	return "<" + _value.first + " - " + QString::number(_value.second) + ">";
}

void ClientModel::showDebugger()
{
	ExecutionResult last = m_client->lastExecution();
	showDebuggerForTransaction(last);
}

QVariantMap ClientModel::contractStorageByIndex(unsigned _index, QString const& _contractAddress)
{
	try
	{
		ExecutionResult e = m_client->execution(_index);
		if (!e.machineStates.empty())
		{
			MachineState state = e.machineStates.back();
			auto nameIter = m_contractNames.find(Address(_contractAddress.toStdString()));
			CompiledContract const* compilerRes = m_codeModel->contract(nameIter->second);
			return contractStorageByMachineState(state, compilerRes);
		}
		else
			return QVariantMap();
	}
	catch (...)
	{
		manageException();
		return QVariantMap();
	}
}

QVariantMap ClientModel::contractStorage(unordered_map<u256, u256> _storage, CompiledContract const* _contract)
{
	QVariantMap storage;
	try
	{
		QVariantList storageDeclarationList;
		QVariantMap storageValues;
		for (auto const& slot: _contract->storage())
		{
			for (auto const& stateVar: slot)
			{
				if (stateVar.type.name.startsWith("mapping"))
					continue; //mapping type not yet managed

				auto storageDec = new QVariableDeclaration(0, stateVar.name.toStdString(), stateVar.type);
				storageDeclarationList.push_back(QVariant::fromValue(storageDec));
				storageValues[storageDec->name()] = formatStorageValue(storageDec->type()->type(), _storage, stateVar.offset, stateVar.slot);
			}
		}
		storage["variables"] = storageDeclarationList;
		storage["values"] = storageValues;
	}
	catch (...)
	{
		manageException();
	}
	return storage;
}

QVariantMap ClientModel::contractStorageByMachineState(MachineState const& _state, CompiledContract const* _contract)
{
	try
	{
		return contractStorage(_state.storage, _contract);
	}
	catch (...)
	{
		manageException();
		return QVariantMap();
	}
}

void ClientModel::showDebuggerForTransaction(ExecutionResult const& _t, QString const& _label)
{
	try
	{
		//we need to wrap states in a QObject before sending to QML.
		QDebugData* debugData = new QDebugData(_label);
		QQmlEngine::setObjectOwnership(debugData, QQmlEngine::JavaScriptOwnership);
		QList<QCode*> codes;
		QList<QHash<int, int>> codeMaps;
		QList<AssemblyItems> codeItems;
		QList<CompiledContract const*> contracts;
		for (MachineCode const& code: _t.executionCode)
		{
			QHash<int, int> codeMap;
			codes.push_back(QMachineState::getHumanReadableCode(debugData, code.address, code.code, codeMap));
			codeMaps.push_back(move(codeMap));
			//try to resolve contract for source level debugging
			auto nameIter = m_contractNames.find(code.address);
			CompiledContract const* compilerRes = m_codeModel->contract(nameIter->second); //returned object is guaranteed to live till the end of event handler in main thread
			if (nameIter != m_contractNames.end() && compilerRes)
			{
				eth::AssemblyItems assemblyItems = !_t.isConstructor() ? compilerRes->assemblyItems() : compilerRes->constructorAssemblyItems();
				codes.back()->setDocument(compilerRes->documentId());
				codeItems.push_back(move(assemblyItems));
				contracts.push_back(compilerRes);
			}
			else
			{
				codeItems.push_back(AssemblyItems());
				contracts.push_back(nullptr);
			}
		}

		QList<QCallData*> data;
		for (bytes const& d: _t.transactionData)
			data.push_back(QMachineState::getDebugCallData(debugData, d));

		QVariantList states;
		QVariantList solCallStack;
		map<int, QVariableDeclaration*> solLocals; //<stack pos, decl>
		map<QString, SolidityDeclaration> localDecl; //<name, solDecl>
		unsigned prevInstructionIndex = 0;

		for (MachineState const& s: _t.machineStates)
		{
			int instructionIndex = codeMaps[s.codeIndex][static_cast<unsigned>(s.curPC)];
			QSolState* solState = nullptr;
			if (!codeItems[s.codeIndex].empty() && contracts[s.codeIndex])
			{
				CompiledContract const* contract = contracts[s.codeIndex];
				AssemblyItem const& instruction = codeItems[s.codeIndex][instructionIndex];

				if (instruction.type() == eth::Push)
				{
					//register new local variable initialization
					auto localIter = contract->locals().find(LocationPair(instruction.location().start, instruction.location().end));
					if (localIter != contract->locals().end())
					{
						if (localDecl.find(localIter.value().name) == localDecl.end())
						{
							localDecl[localIter.value().name] = localIter.value();
							solLocals[s.stack.size()] = new QVariableDeclaration(debugData, localIter.value().name.toStdString(), localIter.value().type);
						}
					}
				}

				if (instruction.type() == eth::Tag)
				{
					//track calls into functions
					AssemblyItem const& prevInstruction = codeItems[s.codeIndex][prevInstructionIndex];
					QString functionName = m_codeModel->resolveFunctionName(instruction.location());
					if (!functionName.isEmpty() && ((prevInstruction.getJumpType() == AssemblyItem::JumpType::IntoFunction) || solCallStack.empty()))
						solCallStack.push_front(QVariant::fromValue(functionName));
					else if (prevInstruction.getJumpType() == AssemblyItem::JumpType::OutOfFunction && !solCallStack.empty())
					{
						solCallStack.pop_front();
						solLocals.clear();
						localDecl.clear();
					}
				}

				//format solidity context values
				QVariantMap locals;
				QVariantList localDeclarations;
				QVariantMap localValues;
				for (auto l: solLocals)
					if (l.first < (int)s.stack.size())
					{
						if (l.second->type()->name().startsWith("mapping"))
							break; //mapping type not yet managed
						localDeclarations.push_back(QVariant::fromValue(l.second));
						DataLocation loc = l.second->dataLocation();
						if (loc == DataLocation::Memory)
						{
							u256 pos = s.stack[l.first];
							u256 offset = pos;
							localValues[l.second->name()] = formatMemoryValue(l.second->type()->type(), s.memory, offset);
						}
						else if (loc == DataLocation::Storage)
							localValues[l.second->name()] = formatStorageValue(
								l.second->type()->type(),
								s.storage,
								localDecl[l.second->name()].offset,
								localDecl[l.second->name()].slot
							);
						else
						{
							ContractCallDataEncoder decoder;
							u256 pos = 0;
							bytes val = toBigEndian(s.stack[l.first]);
							localValues[l.second->name()] = decoder.decodeType(l.second->type()->type(), val, pos);
						}
					}
				locals["variables"] = localDeclarations;
				locals["values"] = localValues;

				QVariantMap storage = contractStorageByMachineState(s, contract);
				prevInstructionIndex = instructionIndex;

				// filter out locations that match whole function or contract
				SourceLocation instructionLocation = instruction.location();
				QString source;
				if (instructionLocation.sourceName)
					source = QString::fromUtf8(instructionLocation.sourceName->c_str());
				if (m_codeModel->isContractOrFunctionLocation(instructionLocation))
					instructionLocation = dev::SourceLocation(-1, -1, instructionLocation.sourceName);

				solState = new QSolState(debugData, move(storage), move(solCallStack), move(locals), instructionLocation.start, instructionLocation.end, source);
			}
			states.append(QVariant::fromValue(new QMachineState(debugData, instructionIndex, s, codes[s.codeIndex], data[s.dataIndex], solState)));
		}

		debugData->setStates(move(states));
		debugDataReady(debugData);
	}
	catch (...)
	{
		manageException();
	}
}

QVariant ClientModel::formatMemoryValue(SolidityType const& _type, bytes const& _value, u256& _offset)
{
	ContractCallDataEncoder decoder;
	return decoder.formatMemoryValue(_type, _value, _offset);
}

QVariant ClientModel::formatStorageValue(SolidityType const& _type, unordered_map<u256, u256> const& _storage, unsigned const& _offset, u256 const& _slot)
{
	ContractCallDataEncoder decoder;
	u256 endSlot;
	return decoder.formatStorageValue(_type, _storage, _offset, _slot, endSlot);
}

void ClientModel::emptyRecord()
{
	try
	{
		debugDataReady(new QDebugData());
	}
	catch (...)
	{
		manageException();
	}
}

void ClientModel::debugRecord(unsigned _index, QString const& _label)
{
	try
	{
		ExecutionResult e = m_client->execution(_index);
		showDebuggerForTransaction(e, _label);
	}
	catch (...)
	{
		manageException();
	}
}

Address ClientModel::deployContract(bytes const& _code, TransactionSettings const& _ctrTransaction)
{
	eth::TransactionSkeleton ts;
	ts.creation = true;
	ts.value = _ctrTransaction.value;
	ts.data = _code;
	ts.gas = _ctrTransaction.gas;
	ts.gasPrice = _ctrTransaction.gasPrice;
	ts.from = toAddress(_ctrTransaction.sender);
	return m_client->submitTransaction(ts, _ctrTransaction.sender, _ctrTransaction.gasAuto).second;
}

void ClientModel::callAddress(Address const& _contract, bytes const& _data, TransactionSettings const& _tr)
{
	eth::TransactionSkeleton ts;
	ts.creation = false;
	ts.value = _tr.value;
	ts.to = _contract;
	ts.data = _data;
	ts.gas = _tr.gas;
	ts.gasPrice = _tr.gasPrice;
	ts.from = toAddress(_tr.sender);
	m_client->submitTransaction(ts, _tr.sender, _tr.gasAuto);
}

RecordLogEntry* ClientModel::lastBlock() const
{
	try
	{
		eth::BlockHeader blockInfo = m_client->blockInfo();
		stringstream strGas;
		strGas << blockInfo.gasUsed();
		stringstream strNumber;
		strNumber << blockInfo.number();
		RecordLogEntry* record =  new RecordLogEntry(
			0,
			QString::fromStdString(strNumber.str()),
			tr(" - Block - "),
			tr("Hash: ") + QString(QString::fromStdString(dev::toHex(blockInfo.hash().ref()))),
			QString(),
			QString(),
			QString(),
			false,
			RecordLogEntry::RecordType::Block,
			QString::fromStdString(strGas.str()),
			"0",
			"0",
			QString(),
			tr("Block"),
			QVariantMap(),
			QVariantMap(),
			QVariantList(),
			RecordLogEntry::TxSource::MixGui,
			RecordLogEntry::TransactionException::None
		);
		QQmlEngine::setObjectOwnership(record, QQmlEngine::JavaScriptOwnership);
		return record;
	}
	catch (...)
	{
		manageException();
		return nullptr;
	}
}

QString ClientModel::lastTransactionIndex() const
{
	return m_lastTransactionIndex;
}

void ClientModel::onStateReset()
{
	try
	{
		m_contractAddresses.clear();
		m_contractNames.clear();
		m_stdContractAddresses.clear();
		m_stdContractNames.clear();
		m_queueTransactions.clear();
		m_gasCosts.clear();
		m_deployedLibraries.clear();
		m_mining = false;
		m_running = false;
		emit stateCleared();
	}
	catch (...)
	{
		manageException();
	}
}

void ClientModel::onNewTransaction(RecordLogEntry::TxSource _source)
{
	try
	{
		ExecutionResult const& tr = m_client->lastExecution();

		RecordLogEntry::TransactionException exception = RecordLogEntry::TransactionException::None;
		switch (tr.excepted)
		{
		case TransactionException::None:
			break;
		case TransactionException::NotEnoughCash:
		{
			exception = RecordLogEntry::TransactionException::NotEnoughCash;
			emit runFailed("Insufficient balance");
			return;
		}
		case TransactionException::OutOfGasIntrinsic:
		case TransactionException::OutOfGasBase:
		case TransactionException::OutOfGas:
		{
			exception = RecordLogEntry::TransactionException::OutOfGas;
			emit runFailed("Not enough gas");
			return;
		}
		case TransactionException::BlockGasLimitReached:
		{
			exception = RecordLogEntry::TransactionException::BlockGasLimitReached;
			emit runFailed("Block gas limit reached");
			return;
		}
		case TransactionException::BadJumpDestination:
		{
			exception = RecordLogEntry::TransactionException::BadJumpDestination;
			emit runFailed("Solidity exception (bad jump)");
			return;
		}
		case TransactionException::OutOfStack:
		{
			exception = RecordLogEntry::TransactionException::OutOfStack;
			emit runFailed("Out of stack");
			return;
		}

		case TransactionException::StackUnderflow:
		{
			exception = RecordLogEntry::TransactionException::StackUnderflow;
			emit runFailed("Stack underflow");
			return;
		}
			//these should not happen in mix
		case TransactionException::Unknown:
		case TransactionException::BadInstruction:
		case TransactionException::InvalidSignature:
		case TransactionException::InvalidNonce:
		case TransactionException::InvalidFormat:
		case TransactionException::BadRLP:
		{
			exception = RecordLogEntry::TransactionException::Unknown;
			emit runFailed("Internal execution error");
			return;
		}

		}


		unsigned block = m_client->number() + 1;
		unsigned recordIndex = tr.executonIndex;
		QString transactionIndex = tr.isCall() ? QObject::tr("Call") : QString("%1:%2").arg(block).arg(tr.transactionIndex);

		QString address = QString::fromStdString(toJS(tr.address));
		QString value = QString::fromStdString(toString(tr.value));
		QString contract = address;
		QString function;
		QString returned;
		QString gasUsed;
		QString gasRequired;
		QString gasRefunded;

		bool creation = (bool)tr.contractAddress;

		if (!tr.isCall())
		{
			gasUsed = QString::fromStdString(toString(tr.gasUsed));
			gasRequired = QString::fromStdString(toString(tr.gasRequired));
			gasRefunded = QString::fromStdString(toString(tr.gasRefunded));
		}

		//TODO: handle value transfer
		FixedHash<4> functionHash;
		bool abi = false;
		if (creation)
		{
			//contract creation
			function = QObject::tr("Constructor");
			address = QObject::tr("(Create contract)");
		}
		else
		{
			//transaction/call
			if (tr.inputParameters.size() >= 4)
			{
				functionHash = FixedHash<4>(tr.inputParameters.data(), FixedHash<4>::ConstructFromPointer);
				function = QString::fromStdString(toJS(functionHash));
				abi = true;
			}
			else
				function = QObject::tr("<none>");
		}

		if (creation)
			returned = QString::fromStdString(toJS(tr.contractAddress));

		Address contractAddress = (bool)tr.address ? tr.address : tr.contractAddress;
		auto contractAddressIter = m_contractNames.find(contractAddress);
		QVariantMap inputParameters;
		QVariantMap returnParameters;
		QVariantList logs;
		if (contractAddressIter != m_contractNames.end())
		{
			ContractCallDataEncoder encoder;
			CompiledContract const* compilerRes = m_codeModel->contract(contractAddressIter->second);
			const QContractDefinition* def = compilerRes->contract();
			contract = def->name();
			if (creation)
				function = contract;
			if (abi)
			{
				QFunctionDefinition const* funcDef = def->getFunction(functionHash);
				if (funcDef)
				{
					function = funcDef->name();
					QStringList returnValues = encoder.decode(funcDef->returnParameters(), tr.result.output);
					returned += "(";
					returned += returnValues.join(", ");
					returned += ")";

					QStringList returnParams = encoder.decode(funcDef->returnParameters(), tr.result.output);
					for (int k = 0; k < returnParams.length(); ++k)
						returnParameters.insert(funcDef->returnParameters().at(k)->name(), returnParams.at(k));

					bytes data = tr.inputParameters;
					data.erase(data.begin(), data.begin() + 4);
					QStringList parameters = encoder.decode(funcDef->parametersList(), data);
					for (int k = 0; k < parameters.length(); ++k)
						inputParameters.insert(funcDef->parametersList().at(k)->name(), parameters.at(k));
				}
			}

			// Fill generated logs and decode parameters
			for (auto const& log: tr.logs)
			{
				QVariantMap l;
				l.insert("address",  QString::fromStdString(log.address.hex()));
				ostringstream s;
				s << log.data;
				l.insert("data", QString::fromStdString(s.str()));
				ostringstream streamTopic;
				streamTopic << log.topics;
				l.insert("topic", QString::fromStdString(streamTopic.str()));
				auto const& sign = log.topics.front(); // first hash supposed to be the event signature. To check
				int topicDataIndex = 1;
				for (auto const& event: def->eventsList())
				{
					if (sign == event->fullHash())
					{
						QVariantList paramsList;
						l.insert("name", event->name());
						for (auto const& e: event->parametersList())
						{
							bytes data;
							QVariant param;
							u256 pos = 0;
							if (!e->isIndexed())
								param = encoder.decodeType(e->type()->type(), log.data, pos);
							else
							{
								data = log.topics.at(topicDataIndex).asBytes();
								topicDataIndex++;
								param = encoder.decodeType(e->type()->type(), data, pos);
							}

							QVariantMap p;
							p.insert("indexed", e->isIndexed());
							p.insert("value", param.toString());
							p.insert("name", e->name());
							paramsList.push_back(p);
						}
						l.insert("param", paramsList);
						break;
					}
				}
				logs.push_back(l);
			}
		}

		QString sender;
		for (auto const& secret: m_accountsSecret)
		{
			if (secret.address() == tr.sender)
			{
				sender = QString::fromStdString(dev::toHex(secret.secret().ref()));
				break;
			}
		}

		if (!creation)
			for (auto const& ctr: m_contractAddresses)
			{
				if (ctr.second == tr.address)
				{
					contract = serializeToken(ctr.first);
					break;
				}
			}

		QString label;
		if (function != QObject::tr("<none>"))
			label = contract + "." + function + "()";
		else
			label = address;

		RecordLogEntry* log = new RecordLogEntry(
			recordIndex,
			transactionIndex,
			contract,
			function,
			value,
			address,
			returned,
			tr.isCall(),
			RecordLogEntry::RecordType::Transaction,
			gasUsed,
			gasRequired,
			gasRefunded,
			sender,
			label,
			inputParameters,
			returnParameters,
			logs,
			_source,
			exception
		);
		if (transactionIndex != QObject::tr("Call"))
			m_lastTransactionIndex = transactionIndex;

		QQmlEngine::setObjectOwnership(log, QQmlEngine::JavaScriptOwnership);

		// retrieving all accounts balance
		QVariantMap state;
		QVariantMap contractsStorage;
		QVariantMap accountBalances;
		for (auto const& ctr : m_contractAddresses)
		{
			u256 wei = m_client->balanceAt(ctr.second, PendingBlock);
			auto contractAddressIter = m_contractNames.find(ctr.second);
			CompiledContract const* compilerRes = m_codeModel->contract(contractAddressIter->second);
			QVariantMap sto = contractStorage(m_client->storageAt(ctr.second, PendingBlock), compilerRes);
			contractsStorage.insert(contractAddressIter->second + " - " + QString::fromStdString(ctr.second.hex()) + " - " + QEther(wei, QEther::Wei).format(), sto);
		}
		for (auto const& account : m_accounts)
		{
			u256 wei = m_client->balanceAt(account.first, PendingBlock);
			accountBalances.insert("0x" + QString::fromStdString(account.first.hex()),  QEther(wei, QEther::Wei).format());
		}
		state.insert("accounts", accountBalances);
		state.insert("contractsStorage", contractsStorage);
		emit newState(recordIndex, state);
		emit newRecord(log);
	}
	catch (...)
	{
		manageException();
	}
}

}
}
