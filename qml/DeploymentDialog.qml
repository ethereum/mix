import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.QEther 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper
import "."


Dialog {
	id: modalDeploymentDialog
	modality: Qt.ApplicationModal
	width: 1050
	height: 550
	visible: false

	property alias deployStep: deployStep
	property alias packageStep: packageStep
	property alias registerStep: registerStep
	property alias worker: worker
	property alias steps: steps

	function close()
	{
		visible = false;
		worker.pooler.running = false
	}

	function open()
	{
		deployStep.visible = false
		packageStep.visible = false
		registerStep.visible = false
		steps.init()
		worker.renewCtx()
		worker.pooler.running = true
		visible = true;
	}

	DeploymentWorker
	{
		id: worker
	}

	contentItem: Rectangle {
		color: appStyle.generic.layout.backgroundColor
		anchors.fill: parent
		ColumnLayout
		{
			spacing: 5
			anchors.fill: parent
			anchors.margins: 10

			Rectangle
			{
				id: explanation
				Layout.preferredWidth: parent.width - 50
				Layout.preferredHeight: 50
				height: 50
				color: "transparent"
				DefaultLabel
				{
					id: info
					anchors.centerIn: parent
					text: qsTr("Putting your dapp live is a multi step process. You can read more about it on the")
				}

				DefaultText {
					anchors.left: info.right
					anchors.leftMargin: 7
					id: linkText
					text: '<a href="https://github.com/ethereum/wiki/wiki/Mix:-The-DApp-IDE#deployment-to-network">guide to uploading</a>'
					onLinkActivated: Qt.openUrlExternally(link)
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			RowLayout
			{
				ColumnLayout
				{
					Layout.preferredHeight: parent.height - 50
					Layout.preferredWidth: 200
					DeploymentDialogSteps
					{
						id: steps
						worker: worker
					}
				}

				Connections
				{
					target: steps
					property variant selected
					onSelected:
					{
						if (selected)
							selected.visible = false
						switch (step)
						{
						case "deploy":
						{
							selected = deployStep
							break;
						}
						case "option":
						{
							selected = optionStep
							break;
						}
						case "package":
						{
							selected = packageStep
							break;
						}
						case "upload":
						{
							selected = uploadStep
							break;
						}
						case "register":
						{
							selected = registerStep
							break;
						}
						}
						selected.show()
					}
				}

				ColumnLayout
				{
					Layout.preferredHeight: parent.height - 50
					Layout.preferredWidth: parent.width - 200
					DeployContractStep
					{
						id: deployStep
						visible: false
						worker: worker
					}

					DeploymentOptions
					{
						id: optionStep
						visible: false
						worker: worker
						deployStep: deployStep
					}

					PackagingStep
					{
						id: packageStep
						visible: false
						worker: worker
					}

					UploadPackage
					{
						id: uploadStep
						visible: false
						worker: worker
					}

					RegisteringStep
					{
						id: registerStep
						visible: false
						worker: worker
					}
				}
			}

			Rectangle
			{
				Layout.fillWidth: true
				Layout.preferredHeight: 30
				color: "transparent"

				DefaultButton
				{
					id: resetBtn
					anchors.left: parent.left
					anchors.leftMargin: 205
					text: qsTr("Reset")
					onClicked:
					{
						resetDialog.open()
					}
				}

				MessageDialog
				{
					id: resetDialog
					text: qsTr("This action removes all the properties related to this deployment (including contract addresses and packaged ressources).")
					onYes: {
						worker.forceStopPooling()
						if (projectModel.deploymentDir && projectModel.deploymentDir !== "")
							fileIo.deleteDir(projectModel.deploymentDir)
						projectModel.cleanDeploymentStatus()
						deploymentDialog.steps.reset()
					}
					standardButtons: StandardButton.Yes | StandardButton.No
				}

				DefaultButton
				{
					text: qsTr("Cancel")
					anchors.right: parent.right
					anchors.rightMargin: 10
					onClicked:
					{
						modalDeploymentDialog.close()
					}
				}
			}

		}
	}

	MessageDialog {
		id: deployDialog
		standardButtons: StandardButton.Ok
		icon: StandardIcon.Warning
	}

	MessageDialog {
		id: errorDialog
		standardButtons: StandardButton.Ok
		icon: StandardIcon.Critical
	}
}
