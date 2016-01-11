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
				text: projectModel.projectTitle
				anchors.verticalCenter: parent.verticalCenter
				visible: !projectModel.isEmpty;
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
			onProjectLoaded:
			{
				projectFiles.setFolder(fileIo.pathFromUrl(projectModel.projectPath))
				if (projectFiles.model.count > 1)
				{
					projectFiles.currentRow = 1
					if (projectFiles.model.get(1).type === "file")
						projectFiles.executeSelection(1)
					else
						projectFiles.currentRow = 0
				}
				else
					projectFiles.currentRow = 0
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
		}

		DefaultText
		{
			id: folderPath
			Layout.preferredWidth: filesCol.width
		}

		Splitter
		{
			orientation: Qt.Vertical
			Layout.preferredWidth: filesCol.width
			Layout.preferredHeight: filesCol.height - projectHeader.height - folderPath.height
			TableView {
				id: projectFiles
				property string currentFolder
				Layout.preferredWidth: filesCol.width
				clip: true
				headerDelegate: null
				itemDelegate: renderDelegate
				model: ListModel {}

				function updateView()
				{
					setFolder(currentFolder)
				}

				function setFolder(folder)
				{
					currentFolder = folder
					folderPath.text = folder
					projectModel.currentFolder = folder
					model.clear()
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
						for (var document in projectModel.unsavedFiles)
						{
							if (projectFiles.model.get(k).path === document.path)
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
					height: 20
					color: "transparent"

					Component.onCompleted:
					{
						rect.updateLayout()
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
							rect.height = 20
						else
							rect.height = 20 + appSettings.systemPointSize
					}
				}
			}
		}

			Component {
			id: renderDelegate
			Item {
				Rectangle {
					id: selectedItem
					anchors.fill: parent
					color: projectFilesStyle.title.background
					visible: styleData.selected
					onVisibleChanged:
					{
						if (styleData.selected && styleData.row > -1)
							documentSelected(projectFiles.model.get(styleData.row).path)
					}
				}

				DefaultText {
					anchors.left: parent.left
					anchors.leftMargin: 10
					text: styleData.value
					wrapMode: Text.NoWrap
					id: fileName

					Connections
					{
						target: mainContent.codeEditor
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
					anchors.left: parent.left
					anchors.leftMargin: 10
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
						fileIo.moveFile(projectFiles.model.get(styleData.row).path, projectFiles.currentFolder + "/" + fileNameRename.text)
						fileNameRename.text = ""
						projectFiles.updateView()
					}
				}

				MessageDialog
				{
					id: deleteConfirmation
					text: qsTr("Are you sure to delete this file ?")
					standardButtons: StandardIcon.Ok | StandardIcon.Cancel
					onAccepted:
					{
						fileIo.deleteFile(projectFiles.model.get(styleData.row).path)
						projectFiles.updateView()
					}
				}
			}
		}

			ColumnLayout
			{
				id: openedFiles
				Layout.preferredHeight: 200
				Layout.fillWidth: true
				Repeater
				{
					id: openedFilesRepeater
					model: mainContent.codeEditor.openedDocuments()
					RowLayout
					{
						Layout.minimumHeight: 25
						Layout.preferredHeight: 25
						Layout.maximumHeight: 60
						id: openedFile
						Rectangle
						{
							color: mainContent.codeEditor.openedDocuments()[index].documentId === mainContent.codeEditor.currentDocumentId ? projectFilesStyle.title.background : "transparent"
							anchors.fill: parent
							MouseArea
							{
								anchors.fill: parent
								onClicked:
								{
									mainContent.codeEditor.currentDocumentId = mainContent.codeEditor.openedDocuments()[index].documentId
								}
							}
							DefaultLabel
							{
								anchors.left: parent.left
								anchors.leftMargin: 10
								text: mainContent.codeEditor.openedDocuments()[index].fileName
								width: 100
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

								DefaultLabel
								{
									text: qsTr("Close")
									anchors.top: parent.top
									anchors.left: parent.right
									anchors.leftMargin: 15
									MouseArea
									{
										anchors.fill: parent
										onClicked:
										{
											var currentPath = mainContent.codeEditor.openedDocuments()[index].path
											mainContent.codeEditor.closeDocument(currentPath)
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



