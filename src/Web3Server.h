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
/** @file Web3Server.h
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

#pragma once

#include <map>
#include <string>
#include <QObject>
#include <libweb3jsonrpc/AccountHolder.h>
#include <libweb3jsonrpc/Eth.h>

namespace dev
{

namespace mix
{

class Web3Server: public QObject, public rpc::Eth
{
	Q_OBJECT

public:
	Web3Server(eth::Interface& _client, eth::AccountHolder& _ethAccounts);
	virtual ~Web3Server();

signals:
	void newTransaction();

protected:
	virtual Json::Value eth_getFilterChanges(std::string const& _filterId) override;
	virtual std::string eth_sendTransaction(Json::Value const& _json) override;
	virtual std::string eth_call(Json::Value const& _json, std::string const& _blockNumber) override;
};

}
}
