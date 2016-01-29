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
/** @file ErrorLocationFormatter.js
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

function formatLocation(raw, shortMessage)
{
	var splitted = raw.split(':');
	if (!shortMessage)
		return qsTr("Error in line ") + splitted[1] + ", " + qsTr("character ") + splitted[2];
	else
		return "L" + splitted[1] + "," + "C" + splitted[2];
}

function extractErrorInfo(raw, shortMessage)
{
	var _return = {};
	var detail = raw.split('\n')[0];
	var reg = detail.match(/:\d+:\d+:/g);
	if (reg !== null)
	{
		_return.errorLocation = ErrorLocationFormater.formatLocation(reg[0], shortMessage);
		_return.errorDetail = detail.replace(reg[0], "");
		_return.line = reg[0].split(':')[1];
		_return.column = reg[0].split(':')[2];
	}
	else
	{
		_return.errorLocation = "";
		_return.errorDetail = detail;
		_return.line = "";
		_return.column = "";
	}
	return _return;
}
