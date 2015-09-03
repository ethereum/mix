import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper

Rectangle {
	property variant paramsModel: []
	property variant worker
	color: "#E3E3E3E3"
	anchors.fill: parent
	id: root
	property string packageHash
	property string packageBase64
	property alias localPackageUrl: localPackageUrl.originalText
	property alias lastDeployDate: lastDeployLabel.text
	property string deploymentId
	property string packageDir
	signal packaged

	function show()
	{
		visible = true
	}

	QFileDialog {
		id: ressourcesFolder
		visible: false
		title: qsTr("Please choose a path")
		selectFolder: true
		selectExisting: true
		property variant target
		onAccepted: {
			var u = ressourcesFolder.fileUrl.toString();
			if (u.indexOf("file://") == 0)
				u = u.substring(7, u.length)
			if (Qt.platform.os == "windows" && u.indexOf("/") == 0)
				u = u.substring(1, u.length);
			target.text = u;
		}
	}

	ColumnLayout
	{
		anchors.top: parent.top
		anchors.topMargin: 10
		width: parent.width
		id: col
		spacing: 20
		anchors.left: parent.left
		anchors.leftMargin: 10

		Label
		{
			anchors.top: parent.top
			Layout.fillWidth: true
			text: qsTr("Upload and update your dapp assets")
			font.bold: true
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.preferredHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				anchors.verticalCenter: parent.verticalCenter
				Label
				{
					text: qsTr("Save packaged dapp to")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			DefaultTextField
			{
				anchors.verticalCenter: parent.verticalCenter
				id: packageFolder
				visible: true
				Layout.preferredWidth: 360
				text: projectPath + "package/"
			}

			Button
			{
				iconSource: "qrc:/qml/img/Folder-Open.png"
				anchors.verticalCenter: parent.verticalCenter
				tooltip: qsTr("Select folder")
				onClicked: {
					ressourcesFolder.target = packageFolder
					ressourcesFolder.open()
				}
			}
			Button
			{
				id: generatePackageBtn
				anchors.verticalCenter: parent.verticalCenter
				text: qsTr("Generate Package")
				onClicked:
				{
					NetworkDeploymentCode.packageDapp(projectModel.deploymentAddresses);
					projectModel.saveProject()
					root.packaged()
				}
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.preferredHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				anchors.verticalCenter: parent.verticalCenter
				Label
				{
					text: qsTr("Local package URL")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			TextField
			{
				anchors.verticalCenter: parent.verticalCenter
				Layout.preferredWidth: 360
				id: localPackageUrl
				readOnly: true
				property var originalText
				property bool updating: false

				function init()
				{
					if (updating)
						return
					updating = true
					if (originalText.length > 48)
						text = originalText.substring(0, 46) + "..."
					cursorPosition = 0
					updating = false
				}

				onOriginalTextChanged:
				{
					init()
				}

				style: TextFieldStyle {
					background: Rectangle
					{
					width: 360
					color: "#cccccc"
					radius: 2
				}
			}
		}

		CopyButton
		{
			anchors.verticalCenter: parent.verticalCenter
			getContent: function()
			{
				return localPackageUrl.originalText;
			}
		}

		Label
		{
			anchors.verticalCenter: parent.verticalCenter
			id: lastDeployLabel
		}
	}	
}
}









