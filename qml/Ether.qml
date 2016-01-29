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
/** @file Ether.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

/*
 * Display a row containing :
 *  - The amount of Ether.
 *  - The unit used.
 *  - User-friendly string representation of the amout of Ether (if displayFormattedValue == true).
 * 'value' has to be a QEther obj.
*/
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.1

RowLayout {
	id: etherEdition
	property bool displayFormattedValue
	property bool edit
	property bool readOnly
	property variant value;
	property bool displayUnitSelection
	onValueChanged: update()
	Component.onCompleted: update()
	signal amountChanged
	signal unitChanged
	property int inputWidth

	onReadOnlyChanged:
	{
		readonlytxt.visible = readOnly
		etherValueEdit.visible = !readOnly
		readonlytxt.text = etherValueEdit.text
		units.enabled = !readOnly
	}

	function toHexWei()
	{
		var wei = value.toWei()
		if (wei !== null)
			return "0x" + wei.hexValue()
		else
			return "0x"
	}

	function update()
	{
		if (value)
		{
			etherValueEdit.text = value.value;
			readonlytxt.text = value.value
			selectUnit(value.unit);
			units.updateCombobox()
		}
	}

	function selectUnit(unit)
	{
		units.currentIndex = unit;
		units.updateCombobox()
	}

	function formatInput()
	{
		if (value !== undefined)
		{
			var v = value.format()
			var ether = v.split(" ")
			etherValueEdit.text = ether[0]
			readonlytxt.text = ether[0]
			for (var k = 0; k < unitsModel.count; k++)
			{
				if (unitsModel.get(k).text === ether[1])
				{
					units.currentIndex = k
					break;
				}
			}
		}
	}

	Rectangle
	{
		anchors.left: parent.left
		Layout.preferredWidth:
		{
			if (inputWidth)
				return inputWidth
			else
			{
				var w = parent.width
				if (displayUnitSelection)
					w = w - units.width - 5
				if (displayFormattedValue)
					w = w - formattedValue.width - 5
				return w
			}
		}
		visible: edit
		DefaultTextField
		{
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			anchors.left: parent.left
			onTextChanged:
			{
				if (value !== undefined)
				{
					value.setValue(text)
					formattedValue.text = value.format();
					amountChanged()
				}
			}
			readOnly: etherEdition.readOnly
			visible: edit
			id: etherValueEdit;
		}

		DefaultTextField
		{
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			anchors.left: parent.left
			id: readonlytxt
			readOnly: true
			visible: false
			style: TextFieldStyle {
				background: Rectangle
				{
					color: "#cccccc"
					radius: 4
					width: etherValueEdit.width
				}
			}
		}
	}

	DefaultCombobox
	{
		rootItem: etherEdition
		anchors.verticalCenter: parent.verticalCenter
		Layout.minimumWidth: 100
		id: units
		visible: displayUnitSelection;
		onCurrentTextChanged:
		{
			if (value)
			{
				value.setUnit(currentText);
				formattedValue.text = value.format();
				unitChanged()
			}
			updateCombobox()
		}

		onModelChanged:
		{
			updateCombobox()
		}

		model: ListModel {
			id: unitsModel
			ListElement { text: "Uether"; }
			ListElement { text: "Vether"; }
			ListElement { text: "Dether"; }
			ListElement { text: "Nether"; }
			ListElement { text: "Yether"; }
			ListElement { text: "Zether"; }
			ListElement { text: "Eether"; }
			ListElement { text: "Pether"; }
			ListElement { text: "Tether"; }
			ListElement { text: "Gether"; }
			ListElement { text: "Mether"; }
			ListElement { text: "grand"; }
			ListElement { text: "ether"; }
			ListElement { text: "finney"; }
			ListElement { text: "szabo"; }
			ListElement { text: "Gwei"; }
			ListElement { text: "Mwei"; }
			ListElement { text: "Kwei"; }
			ListElement { text: "wei"; }
		}
	}

	DefaultLabel
	{
		Layout.minimumWidth: 100
		visible: displayFormattedValue
		id: formattedValue
	}
}
