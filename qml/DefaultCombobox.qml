import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3

ComboBox {
	style: ComboBoxStyle
	{
	label:
		Rectangle {
		anchors.fill: parent
		color: "transparent"
		DefaultLabel {
			anchors.verticalCenter: parent.verticalCenter
			text: currentText
		}
	}
}
}

