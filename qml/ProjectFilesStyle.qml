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
/** @file ProjectFilesStyle.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0

QtObject {

	function absoluteSize(rel)
	{
		return systemPointSize + rel;
	}

	property QtObject general: QtObject {
		property int leftMargin: 25
	}

	property QtObject title: QtObject {
		property string color: "#808080"
		property string background: "#f0f0f0"
		property int height: 40
		property int fontSize: absoluteSize(7);// 18
	}

	property QtObject documentsList: QtObject {
		property string background: "#f7f7f7"
		property string color: "#4d4d4d"
		property string sectionColor: "#808080"
		property string selectedColor: "white"
		property string highlightColor: "#accbf2"
		property int height: 30
		property int fileNameHeight: 25
		property int fontSize: absoluteSize(2)// 13
		property int sectionFontSize: absoluteSize(2)// 13
	}
}
