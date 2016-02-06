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
/** @file ProjectList.qml
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


ScrollView
{
	id: filesCol
	flickableItem.interactive: false
	signal docDoubleClicked(var fileData)
	signal fileUnsaved(string path, bool status)
	signal documentSelected(string path)
	signal documentRenamed(string oldDocumentId, string newDocumentId)
	horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

	onDocumentRenamed:
	{
		projectFiles.updateFileName(newDocumentId, oldDocumentId)
	}

	function openNextOpenedDocument()
	{
		for (var k = 0; k < mainContent.codeEditor.openedDocuments().length; k++)
		{
			if (mainContent.codeEditor.openedDocuments()[k].documentId === mainContent.codeEditor.currentDocumentId)
			{
				if (k === mainContent.codeEditor.openedDocuments().length - 1)
					k = -1
				mainContent.codeEditor.currentDocumentId = mainContent.codeEditor.openedDocuments()[k + 1].documentId
				break
			}
		}
	}

	function openPrevOpenedDocument()
	{
		for (var k = 0; k < mainContent.codeEditor.openedDocuments().length; k++)
		{
			if (mainContent.codeEditor.openedDocuments()[k].documentId === mainContent.codeEditor.currentDocumentId)
			{
				if (k === 0)
					k = mainContent.codeEditor.openedDocuments().length
				mainContent.codeEditor.currentDocumentId = mainContent.codeEditor.openedDocuments()[k - 1].documentId
				break
			}
		}
	}

	ColumnLayout
	{
		Layout.preferredHeight: parent.height
		Layout.preferredWidth: parent.width
		spacing: 0
		ProjectFilesStyle
		{
			id: projectFilesStyle
		}
		SourceSansProLight
		{
			id: srcSansProLight
		}
		RowLayout
		{
			id: projectHeader
			Layout.preferredWidth: parent.width
			Rectangle
			{
				anchors.fill: parent
				color: projectFilesStyle.title.background
			}

			Image {
				id: projectIcon
				source: "qrc:/qml/img/dappProjectIcon.png"
				anchors.right: projectTitle.left
				anchors.verticalCenter: parent.verticalCenter
				anchors.rightMargin: 6
				fillMode: Image.PreserveAspectFit
				width: 32
				height: 32
				visible: false
			}

			DefaultText
			{
				id: projectTitle
				color: projectFilesStyle.title.color
				text: projectModel.projectTitle == "" ? "-" : projectModel.projectTitle
				anchors.verticalCenter: parent.verticalCenter
				anchors.left: parent.left
				anchors.leftMargin: projectFilesStyle.general.leftMargin
				font.family: srcSansProLight.name
				font.bold: true
				font.wordSpacing: 2
			}

			DefaultText
			{
				text: "-"
				anchors.right: parent.right
				anchors.rightMargin: 15
				font.family: srcSansProLight.name
				anchors.verticalCenter: parent.verticalCenter
				font.weight: Font.Light
			}
		}

		Connections {
			id: projectModelConnection
			target: projectModel
			onProjectClosed:
			{
				projectFiles.clear()
			}
			onProjectLoaded:
			{
				projectFiles.setFolder(fileIo.pathFromUrl(projectModel.projectPath))
				for (var k = 0; k < projectFiles.model.count; k++)
				{
					if (projectFiles.model.get(k).type === "file")
					{
						projectFiles.currentRow = k
						projectFiles.executeSelection(k)
						break
					}
				}
			}

			onIsCleanChanged:
			{
				for (var k = 0; k < projectFiles.model.count; k++)
				{
					if (projectFiles.model.get(k).path === document.path)
					{
						projectFiles.model.get(k).unsaved = !isClean
						fileUnsaved(document.path, !isClean)
						break
					}
				}
			}
			onDocumentAdded:
			{
				projectFiles.updateView()
			}
			onFolderAdded:
			{
				projectFiles.updateView()
			}
			onContractSaved:
			{
				projectModel.saveContractCompilationResult(document.documentId)
			}
		}

		Connections
		{
			target: codeModel
			onNewContractCompiled:
			{
				projectModel.saveContractCompilationResult(codeModel.contracts[_name].documentId)
			}
		}

		DefaultText
		{
			id: folderPath
			Layout.preferredWidth: filesCol.width
			Layout.minimumHeight: 18
			anchors.left: parent.left
			anchors.leftMargin: 10
			font.pointSize: appSettings.getFormattedPointSize() - 1
			color:
			{
				return text.indexOf(fileIo.pathFromUrl(projectModel.projectPath)) !== -1 ? "undefined" : "red"
			}
			verticalAlignment: Text.AlignVCenter
		}

		Splitter
		{
			orientation: Qt.Vertical
			Layout.preferredWidth: filesCol.width
			Layout.preferredHeight: filesCol.height - projectHeader.height - folderPath.height

			TableView {
				id: projectFiles
				property string currentFolder
				Layout.minimumHeight: 500
				clip: true
				headerDelegate: null
				itemDelegate: renderDelegate
				model: ListModel {}

				Component {
					id: renderDelegate
					Item {
						id: innerItem

						Rectangle
						{
							color: "transparent"
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
							anchors.leftMargin: 3
							height: fileName.height
							Image {
								source:
								{
									if (styleData.value === "" || styleData.row === -1)
										return "qrc:/qml/img/unknown.png"
									if (projectFiles.model.get(styleData.row).type === "folder")
										return "qrc:/qml/img/folder-icon-64x64.png"
									else
										return "qrc:/qml/img/unknown.png"
								}
								anchors.verticalCenter: parent.verticalCenter
								height: 25
								sourceSize.height: 25
								fillMode: Image.PreserveAspectFit
								visible: styleData.value !== ".."
							}
						}

						DefaultText {
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
							anchors.leftMargin: 30
							text: styleData.value
							wrapMode: Text.NoWrap
							id: fileName

							Connections
							{
								target: mainContent.codeEditor
								objectName: "ConnectionmainContent.codeEditor"
								onDocumentClosed:
								{
									if (unsaved.visible)
										unsaved.visible = projectFiles.model.get(styleData.row).path !== path
								}
							}

							DefaultText
							{
								id: unsaved
								text: "*"
								visible: styleData.row > -1 ? projectFiles.model.get(styleData.row).unsaved : false
								anchors.left: parent.right
								anchors.leftMargin: 5
							}

							MouseArea
							{
								anchors.fill: parent
								acceptedButtons: Qt.RightButton
								onClicked:
								{
									contextMenu.popup()
								}
							}

							Menu
							{
								id: contextMenu
								visible: false
								MenuItem {
									text: qsTr("Rename")
									onTriggered: {
										fileNameRename.text = fileName.text
										fileName.visible = false
										fileNameRename.visible = true
										fileNameRename.forceActiveFocus()
										contextMenu.visible = false
									}
								}
								MenuItem {
									text: qsTr("Delete")
									onTriggered: {
										deleteConfirmation.open();
										contextMenu.visible = false
									}
								}
							}
						}

						TextInput {
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
							anchors.leftMargin: 30
							text: styleData.value
							wrapMode: Text.NoWrap
							id: fileNameRename
							visible: false

							MouseArea {
								id: textMouseArea
								anchors.fill: parent
								hoverEnabled: true
								z: 2
								onClicked: {
									fileNameRename.forceActiveFocus();
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

							function close(accept)
							{
								contextMenu.visible = false
								fileName.visible = true
								fileNameRename.visible = false
								if (accept)
								{
									var oldPath = projectFiles.model.get(styleData.row).path
									var newPath = projectFiles.currentFolder + "/" + fileNameRename.text
									if (projectFiles.model.get(styleData.row).type === "folder")
										fileIo.moveFile(oldPath, newPath)
									else
									{
										var shouldReopen = mainContent.codeEditor.currentDocumentId === projectFiles.model.get(styleData.row).path
										mainContent.codeEditor.closeDocument(oldPath)
										fileIo.stopWatching(oldPath)
										fileIo.moveFile(oldPath, newPath)
										fileIo.watchFileChanged(newPath)
										if (shouldReopen)
											mainContent.codeEditor.openDocument(projectModel.file(projectFiles.model.get(styleData.row)))
									}
									documentRenamed(oldPath, newPath)
								}
							}
						}

						MessageDialog
						{
							id: deleteConfirmation
							text: qsTr("Are you sure you want to delete this file?")
							standardButtons: StandardIcon.Ok | StandardIcon.Cancel
							property bool regenerateCompilationResult: false
							onAccepted:
							{
								var item = projectFiles.model.get(styleData.row)
								var doc = projectModel.file(item)
								if (item.type === "folder")
									fileIo.deleteDir(item.path)
								else
								{
									if (doc.isContract)
										codeModel.unregisterContractSrc(doc.path)
									mainContent.codeEditor.closeDocument(doc.path)
									fileIo.stopWatching(doc.path)
									fileIo.deleteFile(doc.path)

								}
								regenerateCompilationResult = true
								projectFiles.updateView()
							}
						}

						Connections
						{
							target: codeModel
							onCompilationComplete:
							{
								if (deleteConfirmation.regenerateCompilationResult)
								{
									deleteConfirmation.regenerateCompilationResult = false
									projectModel.regenerateCompilationResult()
								}
							}
						}
					}
				}


				function updateFileName(newPath, oldPath)
				{
					for (var k = 0; k < model.count; k++)
					{
						if (model.get(k).path === oldPath)
						{
							var fileName = newPath.substring(newPath.lastIndexOf("/") + 1)
							model.set(k, { fileName: fileName, type: model.get(k).type, path: newPath })
							break
						}
					}
				}

				function updateView()
				{
					setFolder(currentFolder)
				}

				function clear()
				{
					folderPath.text = ""
					model.clear()
				}

				function setFolder(folder)
				{
					clear()
					currentFolder = folder
					folderPath.text = folder
					projectModel.currentFolder = folder
					if (currentFolder.indexOf("/") !== -1 && currentFolder.substring(1) !== ":")
						model.append({ fileName: "..", type: "folder", path: currentFolder })
					fillView(fileIo.directories(folder), "folder")
					fillView(fileIo.files(folder), "file")
					updateSaveStatus()
				}

				function updateSaveStatus()
				{
					for (var k = 0; k < projectFiles.model.count; k++)
					{
						projectFiles.model.get(k).unsaved = false
						for (var docIndex in projectModel.unsavedFiles)
						{
							if (projectFiles.model.get(k).path === projectModel.unsavedFiles[docIndex].path)
							{
								projectFiles.model.get(k).unsaved = true
								fileUnsaved(document.path, true)
								break
							}
						}
					}
				}

				function fillView(items, type)
				{
					for (var k = 0; k < items.length; k++)
					{
						if (items[k].fileName !== "" && items[k].fileName !== ".." && items[k].fileName !== ".")
						{
							var document = projectModel.file(items[k])
							if (document.isContract)
							{
								var data = fileIo.readFile(document.path);
								codeModel.registerCodeChange(document.documentId, data);
							}
							model.append({ fileName: items[k].fileName, type: type, path: items[k].path, unsaved: false })
						}
					}
				}

				function executeSelection(row)
				{
					var item = projectFiles.model.get(row)
					if (item.type === "folder")
					{
						if (item.fileName === "..")
						{
							var f = projectFiles.currentFolder.substring(0, projectFiles.currentFolder.lastIndexOf("/"))
							if (f === "")
								f = "/"
							projectFiles.setFolder(f)
						}
						else
							projectFiles.setFolder(item.path)
					}
					else
						docDoubleClicked(projectModel.file(item))
				}

				onDoubleClicked:
				{
					executeSelection(row)
				}

				TableViewColumn {
					role: "fileName"
					width: parent.width
				}

				rowDelegate:
					Component
				{
				id: rowItems
				Rectangle
				{
					id: rect
					height: 30
					color: styleData.selected ? projectFilesStyle.title.background : "transparent"
					Component.onCompleted:
					{
						rect.updateLayout()
					}

					onColorChanged:
					{
						if (styleData.selected && styleData.row > -1)
							documentSelected(projectFiles.model.get(styleData.row).path)
					}

					Connections
					{
						target: appSettings
						onSystemPointSizeChanged:
						{
							rect.updateLayout()
						}
					}

					function updateLayout()
					{
						if (mainApplication.systemPointSize >= appSettings.systemPointSize)
							rect.height = 30
						else
							rect.height = 30 + appSettings.systemPointSize
					}
				}
			}
		}

		ScrollView
		{
			horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
			ColumnLayout
			{
				id: openedFiles
				spacing: 0
				Repeater
				{
					id: openedFilesRepeater
					model: mainContent.codeEditor.openedDocuments()
					RowLayout
					{
						Layout.maximumHeight: 40
						Layout.minimumHeight: 40
						Layout.preferredWidth: filesCol.width
						id: openedFile
						Rectangle
						{
							color: mainContent.codeEditor.openedDocuments()[index].documentId === mainContent.codeEditor.currentDocumentId ? projectFilesStyle.title.background : "transparent"
							Layout.preferredHeight: parent.height
							Layout.preferredWidth: parent.width

							TooltipArea
							{
								text: mainContent.codeEditor.openedDocuments()[index].path
								onClicked:
								{
									mainContent.codeEditor.currentDocumentId = mainContent.codeEditor.openedDocuments()[index].documentId
								}
							}

							DefaultImgButton
							{
								id: fileCloseBtn
								height: 20
								width: 20
								anchors.left: parent.left
								anchors.leftMargin: 10
								iconSource: "qrc:/qml/img/delete_sign.png"
								tooltip: qsTr("Close")
								anchors.verticalCenter: parent.verticalCenter
								onClicked:
								{
									var currentPath = mainContent.codeEditor.openedDocuments()[index].path
									mainContent.codeEditor.closeDocument(currentPath)
								}
							}

							DefaultLabel
							{
								anchors.left: fileCloseBtn.right
								anchors.leftMargin: 5
								text: mainContent.codeEditor.openedDocuments()[index].fileName
								elide: Text.ElideRight
								anchors.verticalCenter: parent.verticalCenter

								DefaultText
								{
									id: unsavedOpenedFile
									text: "*"
									visible: false
									anchors.left: parent.right
									anchors.leftMargin: 5
									Component.onCompleted:
									{
										for (var k = 0; k < projectModel.unsavedFiles.length; k++)
										{
											if (projectModel.unsavedFiles[k].path === mainContent.codeEditor.openedDocuments()[index].path)
											{
												visible = true
												break
											}
										}
									}
								}

								Connections
								{
									target: filesCol
									onFileUnsaved:
									{
										if (mainContent.codeEditor.openedDocuments()[index].path === path)
											unsavedOpenedFile.visible = status
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
}
