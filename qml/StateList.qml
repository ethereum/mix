import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import "."

Dialog {
	id: stateListContainer
	modality: Qt.WindowModal
	width: 640
	height: 480
	visible: false
	contentItem: Rectangle {
		anchors.fill: parent
		ColumnLayout
		{
			anchors.fill: parent
			anchors.margins: 10
			Label
			{
				text: qsTr("Scenarios Management:")
				anchors.horizontalCenter: parent.horizontalCenter
			}

			TableView {
				id: list
				Layout.fillHeight: true
				Layout.fillWidth: true
				model: projectModel.stateListModel
				itemDelegate: renderDelegate
				headerDelegate: null
				frameVisible: false
				TableViewColumn {
					role: "title"
					title: qsTr("Scenario")
					width: list.width
				}
			}

			Row{
				spacing: 5
				anchors.bottom: parent.bottom
				anchors.right: parent.right
				anchors.rightMargin: 10
				Button {
					action: closeAction
				}
			}
		}
	}

	Component {
		id: renderDelegate
		Item {
			RowLayout {
				anchors.fill: parent
				Text {
					Layout.fillWidth: true
					Layout.fillHeight: true
					text: styleData.value
					verticalAlignment: Text.AlignBottom
				}
				ToolButton {
					text: qsTr("Edit Genesis...");
					Layout.fillHeight: true
					onClicked: list.model.editState(styleData.row);
				}
				ToolButton {
					visible: list.model.defaultStateIndex !== styleData.row
					text: qsTr("Delete");
					Layout.fillHeight: true
					onClicked: deleteScenario.open()
				}
				MessageDialog
				{
					id: deleteScenario
					onYes: list.model.deleteState(styleData.row);
					standardButtons: StandardButton.Yes | StandardButton.No
					text: qsTr("Are you sure to delete this scenario?")
				}
			}
		}
	}

	Row
	{
		Action {
			id: closeAction
			text: qsTr("Close")
			onTriggered: stateListContainer.close();
		}
	}
}

