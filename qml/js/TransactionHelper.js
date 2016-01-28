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
/** @file TransactionHelper.js
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

Qt.include("QEtherHelper.js")

function defaultTransaction()
{
	return {
		value: createEther("0", QEther.Wei),
		functionId: "",
		gas: createBigInt("250000"),
		gasAuto: true,
		gasPrice: createEther("100000", QEther.Wei),
		parameters: {},
		stdContract: false,
		isContractCreation: true,
		label: "",
		isFunctionCall: true,
		saveStatus: true
	};
}

function rpcCall(requests, callBack, error)
{
	var jsonRpcUrl = appSettings.nodeAddress;
	var rpcRequest = JSON.stringify(requests);
	console.log(rpcRequest);
	var httpRequest = new XMLHttpRequest();
	httpRequest.open("POST", jsonRpcUrl, true);
	httpRequest.setRequestHeader("Content-type", "application/json");
	httpRequest.setRequestHeader("Content-length", rpcRequest.length);
	httpRequest.setRequestHeader("Connection", "close");
	httpRequest.onreadystatechange = function() {
		if (httpRequest.readyState === XMLHttpRequest.DONE) {
			if (httpRequest.status !== 200 || httpRequest.responseText === "")
			{
				var errorText = qsTr("Unable to initiate request to the live network. Please verify your ethereum node is up.") + qsTr(" Error status: ")  + httpRequest.status;
				console.log(errorText);
				console.log(httpRequest.responseText);
				if (error)
					error(errorText);
			}
			else
			{
				console.log(httpRequest.responseText);
				callBack(httpRequest.status, httpRequest.responseText)
			}
		}
	}
	httpRequest.send(rpcRequest);
}

function contractFromToken(token)
{
	if (token.indexOf('<') === 0)
		return token.replace("<", "").replace(">", "").split(" - ")[0];
	return token;
}

