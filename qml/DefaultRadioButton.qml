import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3

RadioButton {
	id: root
	style: RadioButtonStyle {
		label:DefaultLabel {
			anchors.verticalCenter: parent.verticalCenter
			text: root.text
		}
		spacing: 5
	}
}

