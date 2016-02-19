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
/** @file Folder.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.2
import "."

ColumnLayout {
	id: wrapperItem
	signal documentSelected(string doc, string groupName)
	property alias model: filesList.model
	property string sectionName;
	property variant selManager;
	property int index;
	spacing: 0

	function hiddenHeightTopLevel()
	{
		return section.state === "hidden" ? projectFilesStyle.documentsList.height : projectFilesStyle.documentsList.fileNameHeight * model.count + projectFilesStyle.documentsList.height;
	}

	function hiddenHeightRepeater()
	{
		return section.state === "hidden" ? 0 : projectFilesStyle.documentsList.fileNameHeight * wrapperItem.model.count;
	}

	function hiddenHeightElement()
	{
		return section.state === "hidden" ? 0 : projectFilesStyle.documentsList.fileNameHeight;
	}

	function getDocumentIndex(documentId)
	{
		for (var i = 0; i < model.count; i++)
			if (model.get(i).documentId === documentId)
				return i;
		return -1;
	}

	function removeDocument(documentId)
	{
		var i = getDocumentIndex(documentId);
		if (i !== -1)
			model.remove(i);
	}

	RowLayout
	{
		anchors.top: parent.top
		id: rowCol
		Layout.fillWidth: true

		Image {
			source: "qrc:/qml/img/opentriangleindicator_filesproject.png"
			width: 15
			sourceSize.width: 12
			id: imgArrow
			anchors.verticalCenter: parent.verticalCenter
		}

		DefaultText
		{
			id: section
			text: sectionName
			anchors.verticalCenter: parent.verticalCenter
			color: projectFilesStyle.documentsList.sectionColor
			states: [
				State {
					name: "hidden"
					PropertyChanges { target: filesList; visible: false; }
					PropertyChanges { target: imgArrow; source: "qrc:/qml/img/closedtriangleindicator_filesproject.png" }
				}
			]
		}

		MouseArea {
			id: titleMouseArea
			anchors.fill: parent
			hoverEnabled: true
			z: 2
			onClicked: {
				if (section.state === "hidden")
					section.state = "";
				else
					section.state = "hidden";
			}
		}
	}

	ColumnLayout {
		width: parent.width
		visible: section.state !== "hidden"
		spacing: 0
		id: colFiles
		Repeater
		{
			id: filesList
			visible: section.state !== "hidden"
			RowLayout
			{
				visible: section.state !== "hidden"
				id: rootItem
				Layout.minimumWidth: colFiles.width
				property bool isSelected
				property bool renameMode

				Rectangle
				{
					anchors.fill: parent
					color: isSelected ? projectFilesStyle.documentsList.highlightColor : "transparent"
				}

				Row
				{
					z: 6
					anchors.right: parent.right
					anchors.rightMargin: 30
					anchors.verticalCenter: parent.verticalCenter
					spacing: 3

					DefaultButton
					{
						tooltip: qsTr("Rename")
						visible: !isContract
						height: 25
						width: 25
						onClicked:
						{
							rootItem.renameMode = true;
						}
						anchors.verticalCenter: parent.verticalCenter
						Image {
							height: 20
							width: 20
							anchors.verticalCenter: parent.verticalCenter
							anchors.horizontalCenter: parent.horizontalCenter
							source: "qrc:/qml/img/edit_combox.png"
						}
					}

					DefaultButton
					{
						tooltip: qsTr("Delete")
						visible: !isContract
						height: 25
						width: 25
						onClicked:
						{
							deleteConfirmation.open();
						}
						anchors.verticalCenter: parent.verticalCenter
						Image {
							height: 25
							width: 25
							source: "qrc:/qml/img/delete-block-icon@2x.png"
						}
					}
				}

				RowLayout {
					spacing: 3
					anchors.left: parent.left
					anchors.leftMargin: projectFilesStyle.general.leftMargin + 2
					id: rowFileName
					DefaultText {
						id: nameText
						visible: !renameMode
						color: rootItem.isSelected ? projectFilesStyle.documentsList.selectedColor : projectFilesStyle.documentsList.color
						text: name
						Connections
						{
							target: selManager
							onSelected: {
								if (groupName != sectionName)
									rootItem.isSelected = false;
								else if (doc === documentId)
									rootItem.isSelected = true;
								else
									rootItem.isSelected = false;

								if (sectionName === "Contracts")
									rootItem.isSelected = name === doc

								if (rootItem.isSelected && section.state === "hidden")
									section.state = "";
							}
							onIsCleanChanged: {
								if (groupName === sectionName && doc === documentId)
								{
									if (sectionName === "Contracts" && isClean && codeModel.contracts[name])
										codeConnection.hex = codeModel.contracts[name].codeHex + name
									if (sectionName !== "Contracts" || isClean)
									{
										editStatusLabel.visible = !isClean
										if (sectionName === "Contracts")
											editErrorStatusLabel.visible = !isClean
									}
								}
							}
						}

						Connections
						{
							target: projectModel
							onContractSaved:
							{
								for (var ctr in codeModel.contracts)
								{
									if (codeModel.contracts[ctr].documentId === documentId && codeModel.contracts[ctr].contract.name === name)
									{
										editStatusLabel.visible = false
										codeConnection.resetHex()
										break
									}
								}
							}
						}

						Connections
						{
							id: codeConnection
							target: codeModel
							property string hex
							onCompilationComplete:
							{
								if (sectionName !== "Contracts")
									return
								editErrorStatusLabel.visible = false
								nameText.text = name
								//we have to check in the document if the modified contract is this one.
								if (codeModel.contracts[name])
								{
									var isClean = hex === (codeModel.contracts[name].codeHex + name)
									editStatusLabel.visible = !isClean
								}
							}

							onCompilationError:
							{
								if (sectionName !== "Contracts")
									return
								if (_error.indexOf(documentId) !== -1)
								{
									editErrorStatusLabel.visible = true
									editErrorStatusLabel.wasClean = !editStatusLabel.visible
									editStatusLabel.visible = false
								}
							}

							function resetHex() {
								if (codeModel.contracts[name])
									hex = codeModel.contracts[name].codeHex + name
							}

							Component.onCompleted:
							{
								resetHex()
							}
						}
					}

					DefaultLabel {
						id: editStatusLabel
						visible: false
						color: rootItem.isSelected ? projectFilesStyle.documentsList.selectedColor : projectFilesStyle.documentsList.color
						text: "*"
						width: 10
					}

					DefaultLabel {
						property bool wasClean: true
						id: editErrorStatusLabel
						visible: false
						color: "red"
						text: "*"
						width: 10
						onVisibleChanged:
						{
							if (!visible)
								editStatusLabel.visible = !wasClean
						}
					}
				}

				TextInput {
					id: textInput
					text: nameText.text
					visible: renameMode
					anchors.left: parent.left
					anchors.leftMargin: projectFilesStyle.general.leftMargin
					MouseArea {
						id: textMouseArea
						anchors.fill: parent
						hoverEnabled: true
						z: 2
						onClicked: {
							textInput.forceActiveFocus();
						}
					}

					onVisibleChanged: {
						if (visible) {
							selectAll();
							forceActiveFocus();
						}
					}

					onAccepted: close(true);
					onCursorVisibleChanged: {
						if (!cursorVisible)
							close(false);
					}
					onFocusChanged: {
						if (!focus)
							close(false);
					}
					function close(accept) {
						rootItem.renameMode = false;
						if (accept)
						{
							var i = getDocumentIndex(documentId);
							projectModel.renameDocument(documentId, textInput.text);
							wrapperItem.model.set(i, projectModel.getDocument(documentId));
						}
					}
				}

				Connections {
					id: projectModelConnection
					target: projectModel

					onContractSelected:
					{
						if (sectionName === "Contracts" && _contractIndex === index)
							mouseArea.select()
					}
				}

				MouseArea {
					id: mouseArea
					z: 1
					hoverEnabled: false
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked:{
						if (mouse.button === Qt.LeftButton)
							select(mouse)
					}

					function select()
					{
						rootItem.isSelected = true;
						projectModel.openDocument(documentId);
						if (sectionName === "Contracts")
						{
							projectModel.currentContractIndex = index
							for (var k = 0; k < sectionModel.count; k++)
							{
								if (sectionModel.get(k).name === name)
								{
									documentSelected(name, groupName);
									mainContent.codeEditor.setCursor(sectionModel.get(k).startlocation.startlocation, sectionModel.get(k).documentId)
									mainContent.codeEditor.basicHighlight(sectionModel.get(k).documentId,
																		  sectionModel.get(k).startlocation.startlocation,
																		  sectionModel.get(k).startlocation.endlocation)
									return
								}
							}
						}
						else
							documentSelected(documentId, groupName);
					}
				}

				Menu {
					id: contextMenu
					MenuItem {
						text: qsTr("Rename")
						onTriggered: {
							rootItem.renameMode = true;
						}
					}
					MenuItem {
						text: qsTr("Delete")
						onTriggered: {
							deleteConfirmation.open();
						}
					}
				}

				Menu {
					id: contextMenuContract
					MenuItem {
						text: qsTr("Delete")
						onTriggered: {
							deleteConfirmation.open();
						}
					}
				}

				MessageDialog
				{
					id: deleteConfirmation
					text: qsTr("Are you sure you want to delete this file?")
					standardButtons: StandardIcon.Ok | StandardIcon.Cancel
					onAccepted:
					{
						projectModel.removeDocument(documentId);
						wrapperItem.removeDocument(documentId);
					}
				}
			}
		}
	}
}

