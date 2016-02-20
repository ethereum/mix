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
/** @file CodeModel.cpp
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2014
 * Ethereum IDE client.
 */

#include <sstream>
#include <memory>
#include <QDebug>
#include <QApplication>
#include <QtQml>
#include <libdevcore/Common.h>
#include <libevmasm/SourceLocation.h>
#include <libsolidity/ast/AST.h>
#include <libsolidity/ast/Types.h>
#include <libsolidity/ast/ASTVisitor.h>
#include <libsolidity/interface/CompilerStack.h>
#include <libsolidity/interface/SourceReferenceFormatter.h>
#include <libsolidity/interface/InterfaceHandler.h>
#include <libsolidity/interface/GasEstimator.h>
#include <libsolidity/interface/SourceReferenceFormatter.h>
#include <libevmcore/Instruction.h>
#include <libethcore/CommonJS.h>
#include "QContractDefinition.h"
#include "QFunctionDefinition.h"
#include "QVariableDeclaration.h"
#include "CodeHighlighter.h"
#include "FileIo.h"
#include "CodeModel.h"

using namespace dev::mix;
using namespace std;

const set<string> c_predefinedContracts =
{ "Config", "Coin", "CoinReg", "coin", "service", "owned", "mortal", "NameReg", "named", "std", "configUser" };


namespace
{
using namespace dev::eth;
using namespace dev::solidity;

class CollectLocalsVisitor: public ASTConstVisitor
{
public:
	CollectLocalsVisitor(QHash<LocationPair, SolidityDeclaration>* _locals):
		m_locals(_locals), m_functionScope(false) {}

private:
	LocationPair nodeLocation(ASTNode const& _node)
	{
		return LocationPair(_node.location().start, _node.location().end);
	}

	virtual bool visit(FunctionDefinition const&) override
	{
		m_functionScope = true;
		return true;
	}

	virtual void endVisit(FunctionDefinition const&) override
	{
		m_functionScope = false;
	}

	virtual bool visit(VariableDeclaration const& _node) override
	{
		SolidityDeclaration decl;
		decl.type = CodeModel::nodeType(_node.type().get());
		decl.name = QString::fromStdString(_node.name());
		decl.slot = 0;
		decl.offset = 0;
		if (m_functionScope)
			m_locals->insert(nodeLocation(_node), decl);
		return true;
	}

private:
	QHash<LocationPair, SolidityDeclaration>* m_locals;
	bool m_functionScope;
};

class CollectLocationsVisitor: public ASTConstVisitor
{
public:
	CollectLocationsVisitor(SourceMap* _sourceMap):
		m_sourceMap(_sourceMap) {}

private:
	LocationPair nodeLocation(ASTNode const& _node)
	{
		return LocationPair(_node.location().start, _node.location().end);
	}

	virtual bool visit(FunctionDefinition const& _node) override
	{
		m_sourceMap->functions.insert(nodeLocation(_node), QString::fromStdString(_node.name()));
		return true;
	}

	virtual bool visit(ContractDefinition const& _node) override
	{
		m_sourceMap->contracts.insert(nodeLocation(_node), QString::fromStdString(_node.name()));
		return true;
	}

private:
	SourceMap* m_sourceMap;
};

QHash<unsigned, SolidityDeclarations> collectStorage(dev::solidity::ContractDefinition const& _contract)
{
	QHash<unsigned, SolidityDeclarations> result;
	dev::solidity::ContractType contractType(_contract);

	for (auto v : contractType.stateVariables())
	{
		dev::solidity::VariableDeclaration const* declaration = get<0>(v);
		dev::u256 slot = get<1>(v);
		unsigned offset = get<2>(v);
		result[static_cast<unsigned>(slot)].push_back(SolidityDeclaration { QString::fromStdString(declaration->name()), CodeModel::nodeType(declaration->type().get()), slot, offset });
	}
	return result;
}

} //namespace

void BackgroundWorker::queueCodeChange(int _jobId)
{
	m_model->runCompilationJob(_jobId);
}

CompiledContract::CompiledContract(const dev::solidity::CompilerStack& _compiler, QString const& _contractName, QString const& _source):
	QObject(nullptr),
	m_sourceHash(qHash(_source))
{
	string name = _contractName.toStdString();
	ContractDefinition const& contractDefinition = _compiler.contractDefinition(name);
	m_contract.reset(new QContractDefinition(nullptr, &contractDefinition));
	QQmlEngine::setObjectOwnership(m_contract.get(), QQmlEngine::CppOwnership);
	m_contract->moveToThread(QApplication::instance()->thread());
	m_linkerObject = _compiler.object(_contractName.toStdString());

	dev::solidity::InterfaceHandler interfaceHandler;
	m_contractInterface = QString::fromStdString(interfaceHandler.abiInterface(contractDefinition));
	m_contractInterface = m_contractInterface.replace("\n", "");
	if (m_contractInterface.isEmpty())
		m_contractInterface = "[]";
	if (contractDefinition.location().sourceName.get())
		m_documentId = QString::fromStdString(*contractDefinition.location().sourceName);

	CollectLocalsVisitor visitor(&m_locals);
	m_storage = collectStorage(contractDefinition);
	contractDefinition.accept(visitor);
	m_assemblyItems = *_compiler.runtimeAssemblyItems(name);
	m_constructorAssemblyItems = *_compiler.assemblyItems(name);
}

void CompiledContract::linkLibraries(QVariantMap const& _deployedLibraries, QVariantMap _compiledItems)
{
	map<string, h160> toLink;
	for (auto const& linkRef: m_linkerObject.linkReferences)
	{
		QString refName = QString::fromStdString(linkRef.second);
		if (_deployedLibraries.find(refName) != _deployedLibraries.cend())
		{
			CompiledContract* ctr = qvariant_cast<CompiledContract*>(_compiledItems.value(refName));
			toLink[ctr->contract()->name().toStdString()] = Address(_deployedLibraries.value(refName).toString().toStdString());
		}
	}
	m_linkerObject.link(toLink);
}

QString CompiledContract::codeHex() const
{
	return QString::fromStdString(toJS(m_linkerObject.bytecode));
}

CodeModel::CodeModel():
	m_compiling(false),
	m_codeHighlighterSettings(new CodeHighlighterSettings()),
	m_backgroundWorker(this),
	m_backgroundJobId(0)
{
	m_backgroundThread.start();
	m_backgroundWorker.moveToThread(&m_backgroundThread);
	connect(this, &CodeModel::scheduleCompilationJob, &m_backgroundWorker, &BackgroundWorker::queueCodeChange, Qt::QueuedConnection);
	qRegisterMetaType<CompiledContract*>("CompiledContract*");
	qRegisterMetaType<QContractDefinition*>("QContractDefinition*");
	qRegisterMetaType<QFunctionDefinition*>("QFunctionDefinition*");
	qRegisterMetaType<QVariableDeclaration*>("QVariableDeclaration*");
	qmlRegisterType<QFunctionDefinition>("org.ethereum.qml", 1, 0, "QFunctionDefinition");
	qmlRegisterType<QVariableDeclaration>("org.ethereum.qml", 1, 0, "QVariableDeclaration");
}

CodeModel::~CodeModel()
{
	stop();
	disconnect(this);
	releaseContracts();
	if (m_gasCostsMaps)
		delete m_gasCostsMaps;
}

void CodeModel::manageException() const
{
	try
	{
		throw;
	}
	catch (boost::exception const& _e)
	{
		cerr << boost::diagnostic_information(_e);
		emit compilationInternalError("Internal error: " + QString::fromStdString(boost::diagnostic_information(_e)));
	}
	catch (exception const& _e)
	{
		cerr << _e.what();
		emit compilationInternalError("Internal error: " + QString::fromStdString(_e.what()));
	}
	catch (...)
	{
		cerr << boost::current_exception_diagnostic_information();
		emit compilationInternalError("Internal error: " + QString::fromStdString(boost::current_exception_diagnostic_information()));
	}
}

void CodeModel::stop()
{
	///@todo: cancel bg job
	m_backgroundThread.exit();
	m_backgroundThread.wait();
}

void CodeModel::reset()
{
	try
	{
		///@todo: cancel bg job
		Guard l(x_contractMap);
		releaseContracts();
		Guard pl(x_pendingContracts);
		m_pendingContracts.clear();
		emit stateChanged();
	}
	catch (...)
	{
		manageException();
	}
}

void CodeModel::unregisterContractSrc(QString const& _documentId)
{
	try
	{
		{
			Guard pl(x_pendingContracts);
			m_pendingContracts.erase(_documentId);
		}

		// launch the background thread
		m_compiling = true;
		emit stateChanged();
		emit scheduleCompilationJob(++m_backgroundJobId);
	}
	catch (...)
	{
		manageException();
	}
}

void CodeModel::registerCodeChange(QString const& _documentId, QString const& _code)
{
	try
	{
		{
			Guard pl(x_pendingContracts);
			m_pendingContracts[_documentId] = _code;
		}

		// launch the background thread
		m_compiling = true;
		emit stateChanged();
		emit scheduleCompilationJob(++m_backgroundJobId);
	}
	catch (...)
	{
		manageException();
	}
}

QVariantMap CodeModel::contracts() const
{
	QVariantMap result;
	try
	{
		Guard l(x_contractMap);
		for (ContractMap::const_iterator c = m_contractMap.cbegin(); c != m_contractMap.cend(); ++c)
			result.insert(c.key(), QVariant::fromValue(c.value()));
	}
	catch (...)
	{
		manageException();
	}
	return result;
}

CompiledContract* CodeModel::contractByDocumentId(QString const& _documentId) const
{
	try
	{
		Guard l(x_contractMap);
		for (ContractMap::const_iterator c = m_contractMap.cbegin(); c != m_contractMap.cend(); ++c)
			if (c.value()->m_documentId == _documentId)
				return c.value();
		return nullptr;
	}
	catch (...)
	{
		manageException();
		return nullptr;
	}
}

void CodeModel::linkLibraries(QString const& _contractName, QVariantMap const& _deployedLibraries)
{
	auto contract = m_contractMap.value(_contractName);
	contract->linkLibraries(_deployedLibraries, contracts());
}

CompiledContract* CodeModel::contract(QString const& _name)
{
	CompiledContract* res = nullptr;
	try
	{
		Guard l(x_contractMap);
		res = m_contractMap.value(_name);		
	}
	catch (...)
	{
		manageException();		
	}
	if (res == nullptr)
		BOOST_THROW_EXCEPTION(dev::Exception() << dev::errinfo_comment("Contract not found: " + _name.toStdString()));
	return res;
}

void CodeModel::releaseContracts()
{
	for (ContractMap::iterator c = m_contractMap.begin(); c != m_contractMap.end(); ++c)
		c.value()->deleteLater();
	m_contractMap.clear();
	m_sourceMaps.clear();
}

void CodeModel::runCompilationJob(int _jobId)
{
	if (_jobId != m_backgroundJobId)
		return; //obsolete job
	solidity::CompilerStack cs(true);
	try
	{
		cs.addSource("configUser", R"(contract configUser{function configAddr()constant returns(address a){ return 0xf025d81196b72fba60a1d4dddad12eeb8360d828;}})");
		vector<string> sourceNames;
		{
			Guard l(x_pendingContracts);
			FileIo f;
			for (auto const& c: m_pendingContracts)
			{
				if (f.fileExists(c.first))
				{
					cs.addSource(c.first.toStdString(), c.second.toStdString());
					sourceNames.push_back(c.first.toStdString());
				}
			}
		}
		cs.compile(m_optimizeCode);
		if (!cs.errors().empty())
		{
			for (auto const& error: cs.errors())
			{
				// This code is duplicated below for a transition period until we switch away from
				// exceptions for error reporting.
				stringstream errorStr;
				solidity::SourceReferenceFormatter::printExceptionInformation(errorStr, *error, (error->type() == solidity::Error::Type::Warning) ? "Warning" : "Error", cs);
				QString message = QString::fromStdString(errorStr.str());
				QVariantMap firstLocation;
				QVariantList secondLocations;
				if (SourceLocation const* first = boost::get_error_info<solidity::errinfo_sourceLocation>(*error))
					firstLocation = resolveCompilationErrorLocation(cs, *first);
				if (SecondarySourceLocation const* second = boost::get_error_info<solidity::errinfo_secondarySourceLocation>(*error))
				{
					for (auto const& c: second->infos)
						secondLocations.push_back(resolveCompilationErrorLocation(cs, c.second));
				}
				compilationError(message, firstLocation, secondLocations);
				//break; // @TODO provide a way to display multiple errors.
			}
		}
		else
			collectContracts(cs, sourceNames, gasEstimation(cs));
	}
	catch (dev::Exception const& _exception)
	{
		// TODO REMOVE
		// This code is duplicated above for a transition period until we switch away from
		// exceptions for error reporting.
		stringstream error;
		solidity::SourceReferenceFormatter::printExceptionInformation(error, _exception, "Error", cs);
		QString message = QString::fromStdString(error.str());
		QVariantMap firstLocation;
		QVariantList secondLocations;
		if (SourceLocation const* first = boost::get_error_info<solidity::errinfo_sourceLocation>(_exception))
			firstLocation = resolveCompilationErrorLocation(cs, *first);
		if (SecondarySourceLocation const* second = boost::get_error_info<solidity::errinfo_secondarySourceLocation>(_exception))
		{
			for (auto const& c: second->infos)
				secondLocations.push_back(resolveCompilationErrorLocation(cs, c.second));
		}
		compilationError(message, firstLocation, secondLocations);
	}
	m_compiling = false;
	emit stateChanged();
}

QVariantMap CodeModel::resolveCompilationErrorLocation(CompilerStack const& _compiler, SourceLocation const& _location)
{
	tuple<int, int, int, int> pos = _compiler.positionFromSourceLocation(_location);
	QVariantMap startError;
	startError.insert("line", get<0>(pos) > 1 ? (get<0>(pos) - 1) : 1);
	startError.insert("column", get<1>(pos) > 1 ? (get<1>(pos) - 1) : 1);
	QVariantMap endError;
	endError.insert("line", get<2>(pos) > 1 ? (get<2>(pos) - 1) : 1);
	endError.insert("column", get<3>(pos) > 1 ? (get<3>(pos) - 1) : 1);
	QVariantMap error;
	error.insert("start", startError);
	error.insert("end", endError);
	QString sourceName;
	if (_location.sourceName)
		sourceName = QString::fromStdString(*_location.sourceName);
	error.insert("source", sourceName);
	if (!sourceName.isEmpty())
		if (CompiledContract* contract = contractByDocumentId(sourceName))
			sourceName = contract->contract()->name(); //substitute the location to match our contract names
	error.insert("contractName", sourceName);
	return error;
}

GasMapWrapper* CodeModel::gasEstimation(solidity::CompilerStack const& _cs)
{
	GasMapWrapper* gasCostsMaps = new GasMapWrapper;
	try
	{
		for (string n: _cs.contractNames())
		{
			ContractDefinition const& contractDefinition = _cs.contractDefinition(n);
			QString sourceName = QString::fromStdString(*contractDefinition.location().sourceName);

			if (!gasCostsMaps->contains(sourceName))
				gasCostsMaps->insert(sourceName, QVariantList());

			if (!contractDefinition.annotation().isFullyImplemented)
				continue;

			auto gasToString = [](GasMeter::GasConsumption const& _gas)
			{
				if (_gas.isInfinite)
					return QString("0");
				else
					return QString::fromStdString(toString(_gas.value));
			};

			dev::solidity::SourceUnit const& sourceUnit = _cs.ast(*contractDefinition.location().sourceName);
			AssemblyItems const* items = _cs.runtimeAssemblyItems(n);
			map<ASTNode const*, GasMeter::GasConsumption> gasCosts = GasEstimator::breakToStatementLevel(
				GasEstimator::structuralEstimation(*items, vector<ASTNode const*>({&sourceUnit})),
				{&sourceUnit}
			);

			AssemblyItems const* constructorItems = _cs.assemblyItems(n);
			map<ASTNode const*, GasMeter::GasConsumption> constructorGasCosts =
				GasEstimator::breakToStatementLevel(GasEstimator::structuralEstimation(*constructorItems, vector<ASTNode const*>({&sourceUnit})),
				{&sourceUnit}
			);

			// Structural gas costs (per opcode)
			for (auto gasItem = gasCosts.begin(); gasItem != gasCosts.end(); ++gasItem)
			{
				SourceLocation const& itemLocation = gasItem->first->location();
				GasMeter::GasConsumption cost = gasItem->second;
				gasCostsMaps->push(sourceName, itemLocation.start, itemLocation.end, gasToString(cost), cost.isInfinite, GasMap::type::Statement);
			}
			// Structural gas costs for constructor
			if (contractDefinition.constructor())
			{
				SourceLocation const& constructorLocation = contractDefinition.constructor()->location();
				for (auto gasItem = constructorGasCosts.begin(); gasItem != constructorGasCosts.end(); ++gasItem)
				{
					SourceLocation const& itemLocation = gasItem->first->location();
					// check whether the location of the item is in constructor scope
					if (itemLocation.start >= constructorLocation.start && itemLocation.end <= constructorLocation.end)
					{
						GasMeter::GasConsumption cost = gasItem->second;
						gasCostsMaps->push(sourceName, itemLocation.start, itemLocation.end, gasToString(cost), cost.isInfinite, GasMap::type::Statement);
					}
				}
			}

			eth::AssemblyItems const& runtimeAssembly = *_cs.runtimeAssemblyItems(n);
			QString contractName = QString::fromStdString(contractDefinition.name());
			// Functional gas costs (per function, but also for accessors)
			for (auto it: contractDefinition.interfaceFunctions())
			{
				if (!it.second->hasDeclaration())
					continue;
				SourceLocation loc = it.second->declaration().location();
				GasMeter::GasConsumption cost = GasEstimator::functionalEstimation(runtimeAssembly, it.second->externalSignature());
				gasCostsMaps->push(
					sourceName,
					loc.start,
					loc.end,
					gasToString(cost),
					cost.isInfinite,
					GasMap::type::Function,
					contractName,
					QString::fromStdString(it.second->declaration().name())
				);
			}
			if (auto const* fallback = contractDefinition.fallbackFunction())
			{
				SourceLocation loc = fallback->location();
				GasMeter::GasConsumption cost = GasEstimator::functionalEstimation(runtimeAssembly, "INVALID");
				gasCostsMaps->push(
					sourceName,
					loc.start,
					loc.end,
					gasToString(cost),
					cost.isInfinite,
					GasMap::type::Function,
					contractName,
					"fallback"
				);
			}
			for (auto const& it: contractDefinition.definedFunctions())
			{
				if (it->isPartOfExternalInterface() || it->isConstructor())
					continue;
				SourceLocation loc = it->location();
				size_t entry = _cs.functionEntryPoint(n, *it);
				GasEstimator::GasConsumption cost = GasEstimator::GasConsumption::infinite();
				if (entry > 0)
					cost = GasEstimator::functionalEstimation(runtimeAssembly, entry, *it);
				gasCostsMaps->push(
					sourceName,
					loc.start,
					loc.end,
					gasToString(cost),
					cost.isInfinite,
					GasMap::type::Function,
					contractName,
					QString::fromStdString(it->name())
				);
			}
			if (auto const* constructor = contractDefinition.constructor())
			{
				SourceLocation loc = constructor->location();
				GasMeter::GasConsumption cost = GasEstimator::functionalEstimation(*_cs.assemblyItems(n));
				gasCostsMaps->push(
					sourceName,
					loc.start,
					loc.end,
					gasToString(cost),
					cost.isInfinite,
					GasMap::type::Constructor,
					contractName,
					contractName
				);
			}
		}
	}
	catch (...)
	{
		manageException();
	}
	return gasCostsMaps;
}

QVariantList CodeModel::gasCostByDocumentId(QString const& _documentId) const
{
	try
	{
		if (m_gasCostsMaps)
			return m_gasCostsMaps->gasCostsByDocId(_documentId);
		else
			return QVariantList();
	}
	catch (...)
	{
		manageException();
		return QVariantList();
	}
}

QVariantList CodeModel::gasCostBy(QString const& _contractName, QString const& _functionName) const
{
	try
	{
		if (m_gasCostsMaps)
			return m_gasCostsMaps->gasCostsBy(_contractName, _functionName);
		else
			return QVariantList();
	}
	catch (...)
	{
		manageException();
		return QVariantList();
	}
}

void CodeModel::collectContracts(dev::solidity::CompilerStack const& _cs, vector<string> const& _sourceNames, GasMapWrapper* _gas)
{
	try
	{
		Guard pl(x_pendingContracts);
		Guard l(x_contractMap);
		ContractMap result;
		SourceMaps sourceMaps;
		if (m_gasCostsMaps)
			m_gasCostsMaps->deleteLater();
		m_gasCostsMaps = _gas;
		for (string const& sourceName: _sourceNames)
		{
			dev::solidity::SourceUnit const& source = _cs.ast(sourceName);
			SourceMap sourceMap;
			CollectLocationsVisitor collector(&sourceMap);
			source.accept(collector);
			sourceMaps.insert(QString::fromStdString(sourceName), move(sourceMap));
		}
		for (string n: _cs.contractNames())
		{
			if (c_predefinedContracts.count(n) != 0)
				continue;
			QString name = QString::fromStdString(n);
			ContractDefinition const& contractDefinition = _cs.contractDefinition(n);
			if (!contractDefinition.annotation().isFullyImplemented)
				continue;
			QString sourceName = QString::fromStdString(*contractDefinition.location().sourceName);
			auto sourceIter = m_pendingContracts.find(sourceName);
			QString source = sourceIter != m_pendingContracts.end() ? sourceIter->second : QString();
			CompiledContract* contract = new CompiledContract(_cs, name, source);
			QQmlEngine::setObjectOwnership(contract, QQmlEngine::CppOwnership);
			result[name] = contract;
			CompiledContract* prevContract = nullptr;
			// find previous contract by name
			for (ContractMap::const_iterator c = m_contractMap.cbegin(); c != m_contractMap.cend(); ++c)
				if (c.value()->contract()->name() == contract->contract()->name())
					prevContract = c.value();

			// if not found, try by documentId
			if (!prevContract)
			{
				for (ContractMap::const_iterator c = m_contractMap.cbegin(); c != m_contractMap.cend(); ++c)
					if (c.value()->documentId() == contract->documentId())
					{
						//make sure there are no other contracts in the same source, otherwise it is not a rename
						if (!any_of(result.begin(),result.end(), [=](ContractMap::const_iterator::value_type _v) { return _v != contract && _v->documentId() == contract->documentId(); }))
							prevContract = c.value();
					}
			}
			if (prevContract != nullptr && prevContract->contractInterface() != result[name]->contractInterface())
				emit contractInterfaceChanged(name);
			if (prevContract == nullptr)
				emit newContractCompiled(name);
			else if (prevContract->contract()->name() != name)
				emit contractRenamed(contract->documentId(), prevContract->contract()->name(), name);
		}
		releaseContracts();
		m_contractMap.swap(result);
		m_sourceMaps.swap(sourceMaps);
		emit codeChanged();
		emit compilationComplete();
	}
	catch (...)
	{
		manageException();
	}
}

bool CodeModel::hasContract() const
{
	try
	{
		Guard l(x_contractMap);
		return m_contractMap.size() != 0;
	}
	catch (...)
	{
		manageException();
		return false;
	}
}

void CodeModel::retrieveSubType(SolidityType& _wrapperType, dev::solidity::Type const* _type)
{
	if (_type->category() == Type::Category::Array)
	{
		ArrayType const* arrayType = dynamic_cast<ArrayType const*>(_type);
		_wrapperType.baseType = make_shared<dev::mix::SolidityType const>(nodeType(arrayType->baseType().get()));
	}
}

SolidityType CodeModel::nodeType(dev::solidity::Type const* _type)
{
	SolidityType r
	{
		SolidityType::Type::UnsignedInteger,
		32,
		1,
		false,
		false,
		QString::fromStdString(_type->canonicalName(true)),
		vector<SolidityDeclaration>(),
		vector<QString>(),
		nullptr,
		DataLocation::CallData
	};
	auto ref = static_cast<ReferenceType const*>(_type);
	if (ref)
		r.dataLocation = ref->location();
	if (!_type)
		return r;
	switch (_type->category())
	{
	case Type::Category::Integer:
	{
		IntegerType const* it = dynamic_cast<IntegerType const*>(_type);
		r.size = it->numBits() / 8;
		r.type = it->isAddress() ? SolidityType::Type::Address : it->isSigned() ? SolidityType::Type::SignedInteger : SolidityType::Type::UnsignedInteger;
	}
		break;
	case Type::Category::Bool:
		r.type = SolidityType::Type::Bool;
		break;
	case Type::Category::FixedBytes:
	{
		FixedBytesType const* b = dynamic_cast<FixedBytesType const*>(_type);
		r.type = SolidityType::Type::Bytes;
		r.size = static_cast<unsigned>(b->numBytes());
	}
		break;
	case Type::Category::Contract:
		r.type = SolidityType::Type::Address;
		break;
	case Type::Category::Array:
	{
		ArrayType const* array = dynamic_cast<ArrayType const*>(_type);
		if (array->isString())
			r.type = SolidityType::Type::String;
		else if (array->isByteArray())
			r.type = SolidityType::Type::Bytes;
		else
		{
			SolidityType elementType = nodeType(array->baseType().get());
			elementType.name = r.name;
			elementType.dataLocation = r.dataLocation;
			r = elementType;
		}
		r.count = static_cast<unsigned>(array->length());
		r.dynamicSize = _type->isDynamicallySized();
		r.array = true;
		retrieveSubType(r, _type);
	}
		break;
	case Type::Category::Enum:
	{
		r.type = SolidityType::Type::Enum;
		EnumType const* e = dynamic_cast<EnumType const*>(_type);
		for(auto const& enumValue: e->enumDefinition().members())
			r.enumNames.push_back(QString::fromStdString(enumValue->name()));
	}
		break;
	case Type::Category::Struct:
	{
		r.type = SolidityType::Type::Struct;
		StructType const* s = dynamic_cast<StructType const*>(_type);
		for(auto const& structMember: s->members(nullptr))
		{
			auto slotAndOffset = s->storageOffsetsOfMember(structMember.name);
			r.members.push_back(SolidityDeclaration { QString::fromStdString(structMember.name), nodeType(structMember.type.get()), slotAndOffset.first, slotAndOffset.second });
		}
	}
		break;
	case Type::Category::Function:
	case Type::Category::IntegerConstant:
	case Type::Category::StringLiteral:
	case Type::Category::Magic:
	case Type::Category::Mapping:
	case Type::Category::Modifier:
	case Type::Category::Real:
	case Type::Category::TypeType:
	case Type::Category::Tuple:
	default:
		break;
	}
	return r;
}

QVariantMap CodeModel::locationOf(QString _contract)
{
	QVariantMap ret;
	try
	{
		ret["source"] = "-1";
		ret["startlocation"] = "-1";
		for (auto const& s: m_sourceMaps.keys())
		{
			LocationMap map = m_sourceMaps.find(s).value().contracts;
			for (auto const& loc: map.keys())
			{
				QString ctr = map.find(loc).value();
				if (ctr == _contract)
				{
					ret["startlocation"] = map.find(loc).key().first;
					ret["endlocation"] = map.find(loc).key().second;
					ret["source"] = s;
					break;
				}
			}
		}
	}
	catch (...)
	{
		manageException();
	}
	return ret;
}


bool CodeModel::isContractOrFunctionLocation(dev::SourceLocation const& _location)
{
	try
	{
		if (!_location.sourceName)
			return false;
		Guard l(x_contractMap);
		auto sourceMapIter = m_sourceMaps.find(QString::fromStdString(*_location.sourceName));
		if (sourceMapIter != m_sourceMaps.cend())
		{
			LocationPair location(_location.start, _location.end);
			return sourceMapIter.value().contracts.contains(location) || sourceMapIter.value().functions.contains(location);
		}
		return false;
	}
	catch (...)
	{
		manageException();
		return false;
	}
}

QString CodeModel::resolveFunctionName(dev::SourceLocation const& _location)
{
	try
	{
		if (!_location.sourceName)
			return QString();
		Guard l(x_contractMap);
		auto sourceMapIter = m_sourceMaps.find(QString::fromStdString(*_location.sourceName));
		if (sourceMapIter != m_sourceMaps.cend())
		{
			LocationPair location(_location.start, _location.end);
			auto functionNameIter = sourceMapIter.value().functions.find(location);
			if (functionNameIter != sourceMapIter.value().functions.cend())
				return functionNameIter.value();
		}
		return QString();
	}
	catch (...)
	{
		manageException();
		return QString();
	}
}

void CodeModel::setOptimizeCode(bool _value)
{
	try
	{
		m_optimizeCode = _value;
		emit scheduleCompilationJob(++m_backgroundJobId);
	}
	catch (...)
	{
		manageException();
	}
}

void GasMapWrapper::push(QString _source, int _start, int _end, QString _value, bool _isInfinite, GasMap::type _type, QString _contractName, QString _functionName)
{
	GasMap* gas = new GasMap(_start, _end, _value, _isInfinite, _type, _contractName, _functionName, this);
	m_gasMaps.find(_source).value().push_back(QVariant::fromValue(gas));
}

bool GasMapWrapper::contains(QString _key)
{
	return m_gasMaps.contains(_key);
}

void GasMapWrapper::insert(QString _source, QVariantList _variantList)
{
	m_gasMaps.insert(_source, _variantList);
}

QVariantList GasMapWrapper::gasCostsByDocId(QString _source)
{
	auto gasIter = m_gasMaps.find(_source);
	if (gasIter != m_gasMaps.end())
		return gasIter.value();
	else
		return QVariantList();
}

QVariantList GasMapWrapper::gasCostsBy(QString _contractName, QString _functionName)
{
	QVariantList gasMap;
	for (auto const& map: m_gasMaps)
	{
		for (auto const& gas: map)
		{
			if (gas.value<GasMap*>()->contractName() == _contractName && (_functionName.isEmpty() || gas.value<GasMap*>()->functionName() == _functionName))
				gasMap.push_back(gas);
		}
	}
	return gasMap;
}
