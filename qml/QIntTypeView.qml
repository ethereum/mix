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
			textinput.text = ScientificNumber.shouldConvertToScientific ? ScientificNumber.toScientificNumber(value) : value
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
