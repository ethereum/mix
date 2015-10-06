import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Button {
	id: root
	property string text
	style: ButtonStyle {
		label: DefaultText
		{
			text: root.text
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignHCenter
			font.pixelSize: 10
		}
	}
}

