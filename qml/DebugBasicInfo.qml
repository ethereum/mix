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
/** @file DebugBasicInfo.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1

RowLayout {
	property string titleStr

	function update(_value)
	{
		currentStepValue.text = _value;
	}

	Rectangle {
		Layout.minimumWidth: 120
		height: parent.height
		color: "#e5e5e5"
		id: row
		Component.onCompleted:
		{
			updateLayout()
		}

		function updateLayout()
		{
			if (mainApplication.systemPointSize >= appSettings.systemPointSize)
			{
				row.Layout.minimumWidth = 120
			}
			else
			{
				row.Layout.minimumWidth = 120 + (appSettings.systemPointSize * 6)
			}
		}

		Connections
		{
			target: appSettings
			onSystemPointSizeChanged:
			{
				row.updateLayout()
			}
		}

		DefaultLabel
		{
			id: title
			anchors.centerIn: parent
			color: "#a2a2a2"
			font.family: "Sans Serif"
			text: titleStr
		}
	}
	DefaultLabel
	{
		id: currentStepValue
	}
}
