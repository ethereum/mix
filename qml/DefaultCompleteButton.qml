import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0

DefaultImgButton {
	id: completeButton
	property var imageSource
	property var labelText
	style: ButtonStyle {
		background: Rectangle {
			color: welcomeViewStyleId.bgColor
			implicitWidth: 48
			implicitHeight: 48
			//border.color: color.transparent
		}
		label: RowLayout {
			Image {
			   source: imageSource
			   width: 48
			   height: 48
			   id: openProjectImg
			   anchors.top: parent.top
			}
			Label
			{
			   text: labelText
			   font.pixelSize: 22
			   font.italic: true
			   color: welcomeViewStyleId.fontColor
			}
		}
	}
}
