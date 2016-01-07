import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.2
import "."

RowLayout
{
	visible: section.state !== "hidden"
	id: rootItem
	Layout.minimumWidth: colFiles.width
	property bool isSelected
	property bool renameMode
	property variant selManager
	property string path
	property bool isContract:
	{
		projectModel.filesPath[path].isContract
	}
	property string documentId: projectModel.filesPath[path].documentId

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

		DefaultImgButton
		{
			iconSource: "qrc:/qml/img/edit_combox.png"
			tooltip: qsTr("Rename")
			visible: !isContract
			height: 25
			width: 25
			onClicked:
			{
				rootItem.renameMode = true;
			}
			anchors.verticalCenter: parent.verticalCenter
		}

		Button
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
			text: projectModel.filesPath[rootItem.path].fileName
			font.family: fileNameFont.name
		/*	Connections
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
			}*/

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
					/*if (codeModel.contracts[name])
						hex = codeModel.contracts[name].codeHex + name*/
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
			/*rootItem.isSelected = true;
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
				documentSelected(documentId, groupName);*/
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
