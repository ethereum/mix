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
/** @file MixClient.cpp
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

#include <boost/filesystem.hpp>
#include <QDir>
#include "MixClient.h"
#include <vector>
#include <utility>
#include <QtGlobal>
#include <libdevcore/Exceptions.h>
#include <libethcore/ChainOperationParams.h>
#include <libethcore/BasicAuthority.h>
#include <libethereum/BlockChain.h>
#include <libethereum/Transaction.h>
#include <libethereum/Executive.h>
#include <libethereum/ExtVM.h>
#include <libethereum/BlockChain.h>
#include <libevm/VM.h>
#include "Exceptions.h"
using namespace std;
using namespace dev;
using namespace dev::eth;
using namespace std;

namespace dev
{
namespace mix
{

u256 const c_mixGenesisDifficulty = 131072; //TODO: make it lower for Mix somehow

namespace
{
}

MixBlockChain::MixBlockChain(string const& _path, AccountMap const& _pre):
	BlockChain(createParams(_pre), _path, WithExisting::Kill)
{
}

ChainParams MixBlockChain::createParams(AccountMap const& _pre)
{
	ChainParams ret;
	ret.accountStartNonce = 0;
	ret.author = Address();
	ret.blockReward = 5000 * ether;
	ret.difficulty = 0;
	ret.gasLimit = 3141592;
	ret.gasUsed = 0;
	ret.genesisState = _pre;
	ret.maximumExtraDataSize = 1024;
	ret.parentHash = h256();
	ret.sealEngineName = "NoProof";
	ret.sealFields = 0;
	ret.timestamp = 0;
	return ret;
}

MixClient::MixClient(string const& _dbPath):
	m_preSeal(Block::Null),
	m_postSeal(Block::Null),
	m_dbPath(_dbPath)
{
	resetState(AccountMap());
}

MixClient::~MixClient()
{
}

void MixClient::resetState(unordered_map<Address, Account> const& _accounts, Secret const& _miner)
{
	WriteGuard l(x_state);
	Guard fl(x_filtersWatches);

	m_filters.clear();
	for (auto& i: m_specialFilters)
		i.second.clear();
	m_watches.clear();

	QDir dir(QString::fromStdString(m_dbPath));
	dir.removeRecursively();

	m_bc.reset();
	m_bc.reset(new MixBlockChain(m_dbPath + "/bc", _accounts));

	m_preSeal = Block(Block::NullType::Null);
	m_postSeal = Block(Block::NullType::Null);
	m_stateDB = OverlayDB();
	m_stateDB = State::openDB(m_dbPath + "/state", m_bc->genesisHash(), WithExisting::Kill);
	SecureTrieDB<Address, MemoryDB> accountState(&m_stateDB);
	accountState.init();
	dev::eth::commit(_accounts, accountState);

	Block b(*m_bc, m_stateDB, BaseState::Empty, KeyPair(_miner).address());
	b.sync(bc());
	m_preSeal = b;
	m_postSeal = b;

	DEV_WRITE_GUARDED(x_executions)
		m_executions.clear();
}

Transaction MixClient::replaceGas(Transaction const& _t, u256 const& _gas, Secret const& _secret)
{
	Transaction ret;
	if (_secret)
	{
		if (_t.isCreation())
			ret = Transaction(_t.value(), _t.gasPrice(), _gas, _t.data(), _t.nonce(), _secret);
		else
			ret = Transaction(_t.value(), _t.gasPrice(), _gas, _t.receiveAddress(), _t.data(), _t.nonce(), _secret);
	}
	else
	{
		if (_t.isCreation())
			ret = Transaction(_t.value(), _t.gasPrice(), _gas, _t.data(), _t.nonce());
		else
			ret = Transaction(_t.value(), _t.gasPrice(), _gas, _t.receiveAddress(), _t.data(), _t.nonce());
		ret.forceSender(_t.safeSender());
	}
	return ret;
}

// TODO: prototype changed - will need rejigging.
ExecutionResult MixClient::debugTransaction(Transaction const& _t, State const& _state, EnvInfo const& _envInfo, bool _call)
{
	State execState = _state;
	execState.addBalance(_t.sender(), _t.gas() * _t.gasPrice()); //give it enough balance for gas estimation
	eth::ExecutionResult er;
	Executive execution(execState, _envInfo, m_bc->sealEngine());
	execution.setResultRecipient(er);

	ExecutionResult d;
	d.address = _t.receiveAddress();
	d.sender = _t.sender();
	d.value = _t.value();
	d.inputParameters = _t.data();
	d.executonIndex = m_executions.size();
	if (!_call)
		d.transactionIndex = m_postSeal.pending().size();

	try
	{
		execution.initialize(_t);
		execution.execute();
	}
	catch (Exception const& _e)
	{
		d.excepted = toTransactionException(_e);
		d.transactionData.push_back(_t.data());
		return d;
	}

	vector<MachineState> machineStates;
	vector<unsigned> levels;
	vector<MachineCode> codes;
	map<bytes const*, unsigned> codeIndexes;
	vector<bytes> data;
	map<bytesConstRef const*, unsigned> dataIndexes;
	bytes const* lastCode = nullptr;
	bytesConstRef const* lastData = nullptr;
	unsigned codeIndex = 0;
	unsigned dataIndex = 0;
	auto onOp = [&](uint64_t steps, Instruction inst, bigint newMemSize, bigint gasCost, bigint gas, void* voidVM, void const* voidExt)
	{
		VM& vm = *static_cast<VM*>(voidVM);
		ExtVM const& ext = *static_cast<ExtVM const*>(voidExt);
		if (lastCode == nullptr || lastCode != &ext.code)
		{
			auto const& iter = codeIndexes.find(&ext.code);
			if (iter != codeIndexes.end())
				codeIndex = iter->second;
			else
			{
				codeIndex = codes.size();
				codes.push_back(MachineCode({ext.myAddress, ext.code}));
				codeIndexes[&ext.code] = codeIndex;
			}
			lastCode = &ext.code;
		}

		if (lastData == nullptr || lastData != &ext.data)
		{
			auto const& iter = dataIndexes.find(&ext.data);
			if (iter != dataIndexes.end())
				dataIndex = iter->second;
			else
			{
				dataIndex = data.size();
				data.push_back(ext.data.toBytes());
				dataIndexes[&ext.data] = dataIndex;
			}
			lastData = &ext.data;
		}

		if (levels.size() < ext.depth)
			levels.push_back(machineStates.size() - 1);
		else
			levels.resize(ext.depth);

		machineStates.push_back(MachineState{
			steps,
			vm.curPC(),
			inst,
			newMemSize,
			static_cast<u256>(gas),
			vm.stack(),
			vm.memory(),
			gasCost,
			ext.state().storage(ext.myAddress),
			move(levels),
			codeIndex,
			dataIndex
		});
	};

	execution.go(onOp);
	execution.finalize();

	d.excepted = er.excepted;
	d.result = er;
	d.machineStates = machineStates;
	d.executionCode = move(codes);
	d.transactionData = move(data);
	EVMSchedule schedule; // TODO: make relevant to supposed context.
	d.gasUsed = er.gasUsed;
	d.gasRequired = _t.gasRequired(schedule);
	d.gasRefunded = er.gasRefunded;
	if (_t.isCreation())
		d.contractAddress = right160(sha3(rlpList(_t.sender(), _t.nonce())));
	return d;
}

void MixClient::executeTransaction(Transaction const& _t, Block& _block, bool _call, bool _gasAuto, Secret const& _secret)
{
	Transaction t = _gasAuto ? replaceGas(_t, m_postSeal.gasLimitRemaining()) : _t;
	// do debugging run first
	EnvInfo envInfo(bc().info(), bc().lastHashes());
	ExecutionResult d = debugTransaction(t, _block.state(), envInfo, _call);

	// execute on a state
	if (!_call && d.excepted == TransactionException::None)
	{
		t = _gasAuto ? replaceGas(_t, _block.gasLimitRemaining(), _secret) : _t;
		eth::ExecutionResult const& er = _block.execute(envInfo.lastHashes(), t);
		if (t.isCreation() && _block.state().code(d.contractAddress).empty())
			BOOST_THROW_EXCEPTION(OutOfGas() << errinfo_comment("Not enough gas for contract deployment"));
		EVMSchedule schedule;	// TODO: make relevant to supposed context.
		d.gasUsed = er.gasUsed;
		d.gasRequired = _t.gasRequired(schedule);
		d.gasRefunded = er.gasRefunded;
		LocalisedLogEntries logs;
		TransactionReceipt const& tr = _block.receipt(_block.pending().size() - 1);

		LogEntries le = tr.log();
		if (le.size())
			for (unsigned j = 0; j < le.size(); ++j)
				logs.insert(logs.begin(), LocalisedLogEntry(le[j]));
		d.logs =  logs;
	}
	WriteGuard l(x_executions);
	m_executions.emplace_back(move(d));
}

unordered_map<u256, u256> MixClient::contractStorage(Address _contract)
{
	return m_preSeal.state().storage(_contract);
}

void MixClient::mine()
{
	WriteGuard l(x_state);
	NoProof sealer;
	m_postSeal.commitToSeal(bc());
	Notified<bytes> sealed;
	sealer.onSealGenerated([&](bytes const& sealedHeader){ sealed = sealedHeader; });
	sealer.generateSeal(m_postSeal.info());
	m_postSeal.sealBlock(sealed);
	bc().import(m_postSeal.blockData(), m_postSeal.state().db(), (ImportRequirements::Everything & ~ImportRequirements::ValidSeal) != 0);
	m_postSeal.sync(bc());
	m_preSeal = m_postSeal;
}

ExecutionResult MixClient::lastExecution() const
{
	ReadGuard l(x_executions);
	return m_executions.empty() ? ExecutionResult() : m_executions.back();
}

ExecutionResult MixClient::execution(unsigned _index) const
{
	ReadGuard l(x_executions);
	return m_executions.size() > _index ? m_executions.at(_index) : ExecutionResult();
}

Block MixClient::asOf(h256 const& _block) const
{
	ReadGuard l(x_state);
	Block ret(*m_bc, m_stateDB);
	ret.populateFromChain(bc(), _block);
	return ret;
}

pair<h256, Address> MixClient::submitTransaction(eth::TransactionSkeleton const& _ts, Secret const& _secret, bool _gasAuto)
{
	TransactionSkeleton ts = _ts;
	ts.from = toAddress(_secret);
	ts.nonce = postSeal().transactionsFrom(ts.from);
	if (ts.nonce == Invalid256)
		ts.nonce = max<u256>(postSeal().transactionsFrom(ts.from), m_tq.maxNonce(ts.from));
	if (ts.gasPrice == Invalid256)
		ts.gasPrice = gasBidPrice();
	if (ts.gas == Invalid256)
		ts.gas = min<u256>(gasLimitRemaining() / 5, balanceAt(ts.from) / ts.gasPrice);
	WriteGuard l(x_state);
	eth::Transaction t(ts, _secret);
	executeTransaction(t, m_postSeal, false, _gasAuto, _secret);
	return make_pair(t.sha3(), toAddress(ts.from, ts.nonce));
}

dev::eth::ExecutionResult MixClient::call(
	Address const& _from,
	u256 _value,
	Address _dest,
	bytes const& _data,
	u256 _gas,
	u256 _gasPrice,
	BlockNumber _blockNumber,
	bool _gasAuto,
	FudgeFactor _ff
)
{
	(void)_blockNumber;
	Block block = asOf(eth::PendingBlock);
	u256 n = block.transactionsFrom(_from);
	u256 gas = _gas == Invalid256 ? gasLimitRemaining() : _gas;
	u256 gasPrice = _gasPrice == Invalid256 ? gasBidPrice() : _gasPrice;
	Transaction t(_value, gasPrice, gas, _dest, _data, n);
	t.forceSender(_from);
	if (_ff == FudgeFactor::Lenient)
		block.mutableState().addBalance(_from, (u256)(t.gasRequired(EVMSchedule()) * t.gasPrice() + t.value()));
	WriteGuard lw(x_state); //TODO: lock is required only for last execution state
	executeTransaction(t, block, true, _gasAuto);
	return lastExecution().result;
}

dev::eth::ExecutionResult MixClient::call(
	Address const& _from,
	u256 _value,
	Address _dest,
	bytes const& _data,
	u256 _gas, u256 _gasPrice,
	BlockNumber _blockNumber,
	eth::FudgeFactor _ff
)
{
	return call(_from, _value, _dest, _data, _gas, _gasPrice, _blockNumber, false, _ff);
}

dev::eth::ExecutionResult MixClient::create(
	Address const& _from,
	u256 _value,
	bytes const& _data,
	u256 _gas,
	u256 _gasPrice,
	BlockNumber _blockNumber,
	eth::FudgeFactor _ff
)
{
	(void)_blockNumber;
	u256 n;
	Block temp(Block::Null);
	{
		ReadGuard lr(x_state);
		temp = asOf(eth::PendingBlock);
		n = temp.transactionsFrom(_from);
	}
	Transaction t(_value, _gasPrice, _gas, _data, n);
	t.forceSender(_from);
	if (_ff == FudgeFactor::Lenient)
		temp.mutableState().addBalance(_from, (u256)(t.gasRequired(EVMSchedule()) * t.gasPrice() + t.value()));
	WriteGuard lw(x_state); //TODO: lock is required only for last execution state
	executeTransaction(t, temp, true, false);
	return lastExecution().result;
}

pair<h256, Address> MixClient::submitTransaction(const TransactionSkeleton& _ts, const Secret& _secret)
{
	return submitTransaction(_ts, _secret, false);
}

eth::BlockHeader MixClient::blockInfo() const
{
	ReadGuard l(x_state);
	return BlockHeader(bc().block());
}

void MixClient::setAuthor(Address const& _us)
{
	WriteGuard l(x_state);
	m_postSeal.setAuthor(_us);
}

}
}
