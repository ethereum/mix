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
/** @file NewFolderDialog.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.1

Item
{
	signal accepted
	property string path
	function open() {
		newFolderWin.visible = true;
		folderField.focus = true;
	}

	function close() {
		newFolderWin.visible = false;
	}

	function acceptAndClose() {
		path = projectModel.currentFolder + "/" + folderField.text
		close();
		accepted();
	}

	Dialog {
		id: newFolderWin
		modality: Qt.ApplicationModal
		title: qsTr("New Folder");
		width: 550
		height: 80

		visible: false

		contentItem: Rectangle {
			implicitHeight: newFolderWin.height
			implicitWidth: newFolderWin.width

			GridLayout
			{
				id: dialogContent
				columns: 4
				anchors.fill: parent
				anchors.margins: 10
				rowSpacing: 10
				columnSpacing: 10

				DefaultLabel {
					text: qsTr("Name")
				}
				DefaultTextField {
					id: folderField
					focus: true
					Layout.fillWidth: true
					Layout.columnSpan : 3
					Keys.onReturnPressed: {
						if (okButton.enabled)
							acceptAndClose();
					}
				}

				RowLayout
				{
					anchors.bottom: parent.bottom
					anchors.right: parent.right;
					Layout.columnSpan : 3

					DefaultButton {
						id: okButton;
						enabled: folderField.text != ""
						text: qsTr("OK");
						onClicked: {
							acceptAndClose();
						}
					}
					DefaultButton {
						text: qsTr("Cancel");
						onClicked: close();
					}
				}
			}
		}
	}
}
