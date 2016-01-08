import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4
import Qt.labs.folderlistmodel 2.1
import QtQuick.Controls.Styles 1.3
import Qt.labs.settings 1.0
import "."

ScrollView
{
	id: filesCol
	property bool renameMode: false
	flickableItem.interactive: false
	signal docDoubleClicked(var fileData)
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
						break
					}
				}
			}
			onDocumentAdded:
			{
				projectFiles.setFolder(projectFiles.currentFolder)
			}
			onFolderAdded:
			{
				projectFiles.setFolder(projectFiles.currentFolder)
			}
		}

		DefaultText
		{
			id: folderPath
			Layout.preferredWidth: filesCol.width
		}

		TableView {
			id: projectFiles
			property string currentFolder
			Layout.preferredWidth: filesCol.width
			Layout.preferredHeight: filesCol.height - projectHeader.height - folderPath.height
			clip: true
			headerDelegate: null
			itemDelegate: renderDelegate
			model: ListModel {}

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
			}

			DefaultText {
				anchors.left: parent.left
				anchors.leftMargin: 10
				text: styleData.value
				wrapMode: Text.NoWrap
				id: fileName

				DefaultText
				{
					id: unsaved
					text: "*"
					visible: styleData.row > -1 ? projectFiles.model.get(styleData.row).unsaved : false
					anchors.left: parent.right
					anchors.leftMargin: 5
				}
			}
		}
	}
}
}



