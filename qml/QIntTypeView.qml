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
/** @file QIntTypeView.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Controls 1.1
import "js/ScientificNumber.js" as ScientificNumber

Item
{
	property string value
	property alias readOnly: textinput.readOnly
	id: editRoot
	width: 350

	function init()
	{
		if (value !== "")
		{
			textinput.text = ScientificNumber.shouldConvertToScientific(value) ? ScientificNumber.toScientificNumber(value) : value
			textinput.cursorPosition = 0
		}
	}

	DefaultTextField {
		anchors.verticalCenter: parent.verticalCenter
		id: textinput
		selectByMouse: true
		implicitWidth: 350
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			hoverEnabled: true
			onClicked: textinput.forceActiveFocus()
		}
		onTextChanged:
		{
			if (ScientificNumber.isScientificNumber(textinput.text))
				value = ScientificNumber.toFlatNumber(textinput.text)
			else
				value = textinput.text
		}		
	}
}
