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

	function update()
	{
		if (value)
		{
			etherValueEdit.text = value.value;
			readonlytxt.text = value.value
			selectUnit(value.unit);
		}
	}

	function selectUnit(unit)
	{
		units.currentIndex = unit;
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
		Layout.preferredWidth:
		{
			return inputWidth ? inputWidth : 350
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

	ComboBox
	{
		Layout.preferredWidth: 100
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
		Layout.preferredWidth: 100
		visible: displayFormattedValue
		id: formattedValue
	}
}
