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
	property string sectionName
	property variant selManager
	property string path
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
			font.family: boldFont.name
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
			Loader
			{
				property bool isFolder
				property string completePath: fileIo.pathFromUrl(path + "" + modelData.substring(1))
				sourceComponent:
				{
					//TODO : to be improved
					isFolder = projectModel.filesMap[completePath  + "/"] !== undefined
					console.log("....p")
					console.log(isFolder)
					console.log(completePath  + "/")
					if (isFolder)
						return Qt.createComponent("qrc:/qml/FilesSection.qml");
					else
						return Qt.createComponent("qrc:/qml/FileItem.qml");
				}

				onLoaded:
				{
					if (isFolder)
					{
						console.log("yann " + JSON.stringify(projectModel.filesMap[completePath + "/"]))
						item.model = projectModel.filesMap[completePath + "/"]
						item.sectionName = completePath + "/"
					}
					item.path = completePath + "/"
					item.selManager = wrapperItem.selManager
				}
			}
		}
	}
}

