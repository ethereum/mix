import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.3
import "."

Dialog {
	id: modalTransactionDialog
	modality: Qt.ApplicationModal
	width: 680
	height: 300
	visible: false
	contentItem: Rectangle {
		id: containerRect
		anchors.fill: parent
		implicitHeight: modalTransactionDialog.height
		implicitWidth: modalTransactionDialog.width
		RowLayout
		{
			anchors.fill: parent
			spacing: 0
			Item
			{
				Layout.preferredHeight: parent.height
				Layout.preferredWidth: 300
				Image {
					source: "qrc:/res/Mix-1024.png"
					sourceSize.height: 300
				}
			}

			ColumnLayout
			{
				Layout.preferredWidth: 380
				anchors.top: parent.top
				anchors.topMargin: 20
				DefaultLabel
				{
					text: Qt.application.name + " " + Qt.application.version
					font.pointSize: appSettings.getFormattedPointSize() + 10
					anchors.horizontalCenter: parent.horizontalCenter
				}

				DefaultLabel
				{
					text: Qt.application.organization
					anchors.horizontalCenter: parent.horizontalCenter
				}

				RowLayout
				{
					DefaultLabel
					{
						text: qsTr("<a href='https://github.com/ethereum/mix'>source</a>")
						onLinkActivated: Qt.openUrlExternally(link)
					}

					DefaultLabel
					{
						text: qsTr("<a href='http://forum.ethereum.org/categories/mix'>forum</a>")
						onLinkActivated: Qt.openUrlExternally(link)
					}
				}
			}
		}
	}
}
