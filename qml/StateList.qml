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
/** @file StateList.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

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
	width: 480
	height: 480
	visible: false
	onVisibleChanged:
	{
		if (visible)
			if (mainApplication.systemPointSize >= appSettings.systemPointSize)
			{
				width = 480
				height = 480
			}
			else
			{
				width = 480 + (11 * appSettings.systemPointSize)
				height = 480 + (3 * appSettings.systemPointSize)
			}
	}

	title: qsTr("Scenarios Management")
	contentItem: Rectangle {
		implicitHeight: stateListContainer.height
		implicitWidth: stateListContainer.width
		ColumnLayout
		{
			anchors.fill: parent
			anchors.margins: 10
			TableView {
				id: list
				Layout.fillHeight: true
				Layout.fillWidth: true
				model: projectModel.stateListModel
				itemDelegate: renderDelegate
				headerDelegate: null
				flickableItem.interactive: false
				frameVisible: false
				TableViewColumn {
					role: "title"
					title: qsTr("Scenario")
					width: list.width
				}
				rowDelegate: Rectangle {

					Component.onCompleted:
					{
						rect.updateLayout()
					}

					function updateLayout()
					{
						if (mainApplication.systemPointSize >= appSettings.systemPointSize)
							rect.height = 35
						else
							rect.height = 35 + appSettings.systemPointSize
					}

					Connections
					{
						target: appSettings
						onSystemPointSizeChanged:
						{
							rect.updateLayout()
						}
					}
					id: rect
					height: 35
					color: styleData.alternate ? "transparent" : "#cccccc"
				}
			}

			Row{
				spacing: 5
				anchors.bottom: parent.bottom
				anchors.right: parent.right
				anchors.rightMargin: 10
				DefaultButton {
					text: qsTr("Close")
					onClicked: stateListContainer.close();
				}
			}
		}
	}

	Component {
		id: renderDelegate
		Item {
			RowLayout {
				anchors.fill: parent
				anchors.margins: 5
				DefaultText {
					Layout.fillWidth: true
					Layout.fillHeight: true
					text: styleData.value
					verticalAlignment: Text.AlignVCenter
				}
				DefaultButton {
					text: qsTr("Edit Staring Parameters...");
					onClicked: list.model.editState(styleData.row);
				}
				DefaultButton {
					visible: list.model.defaultStateIndex !== styleData.row
					text: qsTr("Delete");
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
}

