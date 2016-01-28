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
/** @file LogsPaneStyle.qml
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

	property QtObject generic: QtObject {
		property QtObject layout: QtObject {
			property string backgroundColor: "#f7f7f7"
			property int headerHeight: 30
			property int headerButtonSpacing: 0
			property int leftMargin: 10
			property int headerButtonHeight: 30
			property string logLabelColor: "#4a4a4a"
			property string logLabelFont: "sans serif"
			property int headerInputWidth: 200
			property int dateWidth: 100
			property int typeWidth: 100
			property int contentWidth: 560
			property string logAlternateColor: "#f6f5f6"
			property string errorColor: "#fffcd5"
			property string buttonSeparatorColor1: "#d3d0d0"
			property string buttonSeparatorColor2: "#f2f1f2"
			property string buttonSelected: "#d9d9d9"
		}
	}
}
