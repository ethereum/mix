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
/** @file NewProjectDialog.qml
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
	property alias projectTitle: titleField.text
	readonly property string projectPath: "file://" + pathField.text
	property alias pathFieldText: pathField.text
	signal accepted
	function open() {
		newProjectWin.visible = true;
		titleField.focus = true;
	}

	function close() {
		newProjectWin.visible = false;
	}

	function acceptAndClose() {
		close();
		accepted();
	}

	Dialog {
		id: newProjectWin
		modality: Qt.ApplicationModal
		title: qsTr("New Project");
		width: 550
		height: 130

		visible: false

		contentItem: Rectangle {
			implicitHeight: newProjectWin.height
			implicitWidth: newProjectWin.width

			GridLayout
			{
				id: dialogContent
				columns: 4
				anchors.fill: parent
				anchors.margins: 10
				rowSpacing: 10
				columnSpacing: 10

				DefaultLabel {
					text: qsTr("Title")
				}
				DefaultTextField {
					id: titleField
					focus: true
					Layout.fillWidth: true
					Layout.columnSpan : 3
					Keys.onReturnPressed: {
						if (okButton.enabled)
							acceptAndClose();
					}
				}

				DefaultLabel {
					text: qsTr("Path")
				}
				RowLayout {
					Layout.columnSpan : 3
					DefaultTextField {
						id: pathField
						Layout.fillWidth: true
						Keys.onReturnPressed: {
							if (okButton.enabled)
								acceptAndClose();
						}
					}
					DefaultButton {
						text: qsTr("Browse")
						onClicked:
						{
							newProjectWin.close()
							createProjectFileDialog.open()
						}
					}
				}

				RowLayout
				{
					anchors.bottom: parent.bottom
					anchors.right: parent.right;
					Layout.columnSpan : 3

					DefaultButton {
						id: okButton;
						enabled: titleField.text != "" && pathField.text != ""
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
		Component.onCompleted: pathField.text = fileIo.homePath

	}

	QFileDialog {
		id: createProjectFileDialog
		visible: false
		title: qsTr("Please choose a path for the project")
		selectFolder: true
		onAccepted: {
			var u = createProjectFileDialog.fileUrl.toString();
			if (u.indexOf("file://") == 0)
				u = u.substring(7, u.length)
			if (Qt.platform.os == "windows" && u.indexOf("/") == 0)
				u = u.substring(1, u.length);
			pathField.text = u;
			newProjectWin.open()
		}
	}
}
