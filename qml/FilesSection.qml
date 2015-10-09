import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.2
import "."


Rectangle
{
	Layout.fillWidth: true
	Layout.minimumHeight: hiddenHeightTopLevel()
	height: hiddenHeightTopLevel()
	Layout.maximumHeight: hiddenHeightTopLevel()
	id: wrapperItem
	signal documentSelected(string doc, string groupName)
	property alias model: filesList.model
	property string sectionName;
	property variant selManager;
	property int index;
	color: index % 2 === 0 ? "transparent" : projectFilesStyle.title.background

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

	ColumnLayout {
		anchors.fill: parent
		spacing: 0

		SourceSansProRegular
		{
			id: fileNameFont
		}

		SourceSansProBold
		{
			id: boldFont
		}

		RowLayout
		{
			anchors.top: parent.top
			id: rowCol
			height: projectFilesStyle.documentsList.height
			Layout.fillWidth: true


			Image {
				source: "qrc:/qml/img/opentriangleindicator_filesproject.png"
				width: 15
				sourceSize.width: 12
				id: imgArrow
				anchors.right: section.left
				anchors.rightMargin: 2
				anchors.top: parent.top
				anchors.topMargin: 9
			}

			DefaultText
			{
				id: section
				text: sectionName
				anchors.left: parent.left
				anchors.leftMargin: projectFilesStyle.general.leftMargin
				color: projectFilesStyle.documentsList.sectionColor
				font.family: boldFont.name
				states: [
					State {
						name: "hidden"
						PropertyChanges { target: filesList; visible: false; }
						PropertyChanges { target: rowCol; Layout.minimumHeight: projectFilesStyle.documentsList.height; Layout.maximumHeight: projectFilesStyle.documentsList.height; height: projectFilesStyle.documentsList.height; }
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
			height: wrapperItem.hiddenHeightRepeater()
			Layout.minimumHeight: wrapperItem.hiddenHeightRepeater()
			Layout.preferredHeight: wrapperItem.hiddenHeightRepeater()
			Layout.maximumHeight: wrapperItem.hiddenHeightRepeater()
			width: parent.width
			visible: section.state !== "hidden"
			spacing: 0

			Repeater
			{
				id: filesList
				visible: section.state !== "hidden"
				Rectangle
				{
					visible: section.state !== "hidden"
					id: rootItem
					Layout.fillWidth: true
					Layout.minimumHeight: wrapperItem.hiddenHeightElement()
					Layout.preferredHeight: wrapperItem.hiddenHeightElement()
					Layout.maximumHeight: wrapperItem.hiddenHeightElement()
					height: wrapperItem.hiddenHeightElement()
					color: isSelected ? projectFilesStyle.documentsList.highlightColor : "transparent"
					property bool isSelected
					property bool renameMode

					Row
					{
						z: 6
						anchors.right: parent.right
						anchors.rightMargin: 8
						anchors.verticalCenter: parent.verticalCenter
						spacing: 3

						DefaultImgButton
						{
							iconSource: "qrc:/qml/img/edit_combox.png"
							tooltip: qsTr("Rename")
							visible: !isContract
							width: 20
							height: 20
							onClicked:
							{
								rootItem.renameMode = true;
							}
							anchors.verticalCenter: parent.verticalCenter
						}

						DefaultImgButton
						{
							tooltip: qsTr("Delete")
							visible: !isContract
							width: 20
							height: 20
							onClicked:
							{
								deleteConfirmation.open();
							}
							anchors.verticalCenter: parent.verticalCenter
							iconSource: "qrc:/qml/img/delete-block-icon@2x.png"
						}
					}

					Row {
						spacing: 3
						anchors.verticalCenter: parent.verticalCenter
						anchors.fill: parent
						anchors.left: parent.left
						anchors.leftMargin: projectFilesStyle.general.leftMargin + 2
						id: rowFileName
						DefaultText {
							id: nameText
							height: parent.height
							visible: !renameMode
							color: rootItem.isSelected ? projectFilesStyle.documentsList.selectedColor : projectFilesStyle.documentsList.color
							text: name
							font.family: fileNameFont.name
							verticalAlignment:  Text.AlignVCenter

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
										if (sectionName === "Contracts" && isClean)
											codeConnection.hex = codeModel.contracts[name].codeHex + name
										if (sectionName !== "Contracts" || isClean)
											editStatusLabel.visible = !isClean;
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
									editStatusLabel.visible = true
									//we have to check in the document if the modified contract is this one.
									var IsClean = hex === (codeModel.contracts[name].codeHex + name)
									editStatusLabel.visible = !IsClean
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

								Component.onCompleted:
								{
									if (codeModel.contracts[name])
										hex = codeModel.contracts[name].codeHex + name
								}
							}
						}

						DefaultLabel {
							id: editStatusLabel
							visible: false
							color: rootItem.isSelected ? projectFilesStyle.documentsList.selectedColor : projectFilesStyle.documentsList.color
							verticalAlignment: Text.AlignVCenter
							text: "*"
							width: 10
							height: parent.height
						}

						DefaultLabel {
							property bool wasClean: true
							id: editErrorStatusLabel
							visible: false
							color: "red"
							verticalAlignment: Text.AlignVCenter
							text: "*"
							width: 10
							height: parent.height
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
						anchors.verticalCenter: parent.verticalCenter
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
						text: qsTr("Are you sure to delete this file ?")
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
}
