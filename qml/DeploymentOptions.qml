import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper
import org.ethereum.qml.QEther 1.0

Rectangle
{
	property variant worker
	anchors.fill: parent
	color: "#E3E3E3E3"
	id: root
	property bool verifyDeploy: true
	property variant deployStep

	function show()
	{
		accountsModel.clear()
		for (var k in worker.accounts)
			accountsModel.append(worker.accounts[k])

		verifyDeployedContract()
		deployedAddresses.refresh()
		worker.renewCtx()
		verifyDeploy = true
		visible = true
		worker.pooler.onTriggered.connect(function() {
			if (root.visible && verifyDeploy)
				verifyDeployedContract();
		})
		ctrDeployCtrLabel.setCost()
	}


	function verifyDeployedContract()
	{
		if (projectModel.deployBlockNumber !== -1)
		{
			worker.verifyHashes(projectModel.deploymentTrHashes, function (bn, trLost)
			{
				root.updateVerification(bn, trLost)
			});
		}
	}

	function updateVerification(blockNumber, trLost)
	{
		if (projectModel.deployBlockNumber === "")
			verificationLabel.text = ""
		else
		{
			var nb = parseInt(blockNumber - projectModel.deployBlockNumber)
			verificationTextArea.visible = false
			verificationLabel.visible = true
			if (nb >= 10)
			{
				verificationLabel.text = qsTr("contracts deployment verified")
				verificationLabel.color = "green"
			}
			else
			{
				verificationLabel.text = nb
				if (trLost.length > 0)
				{
					verifyDeploy = false
					verificationTextArea.visible = true
					verificationLabel.visible = false
					verificationTextArea.text = qsTr("Following transactions are invalidated:") + "\n"
					deploymentStepChanged(qsTr("Following transactions are invalidated:"))
					verificationTextArea.textColor = "red"
					for (var k in trLost)
					{
						deploymentStepChanged(trLost[k])
						verificationTextArea.text += trLost[k] + "\n"
					}
				}
			}
		}
	}

	Column
	{
		anchors.top: parent.top
		anchors.fill: parent
		id: deploymentOption
		anchors.margins: 10
		spacing: 10

		DefaultLabel
		{
			id: deploylabel
			text: qsTr("Select deployment options")
			font.bold: true
		}

		DefaultLabel
		{
			id: nodeError
			visible: false
			color: "red"
			text: qsTr("Unable to contact Ethereum node on ") + appSettings.nodeAddress
		}

		Connections
		{
			target: worker
			property int connectState: 0
			onNodeUnreachable:
			{
				if (!root.visible && connectState === -1)
					return
				connectState = -1
				nodeError.visible = true
				deploylabel.visible = false
				deployBtn.enabled = false
			}
			onNodeReachable:
			{
				if (!root.visible && connectState === 1)
					return
				connectState = 1
				nodeError.visible = false
				deploylabel.visible = true
				deployBtn.enabled = true
			}
		}

		ListModel
		{
			id: accountsModel
		}

		RowLayout
		{
			width: parent.width
			height: 30
			Rectangle
			{
				width: deploymentOption.width / 5
				anchors.verticalCenter: parent.verticalCenter
				DefaultLabel
				{
					text: qsTr("Deployment account")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			DefaultCombobox
			{
				id: accountsList
				textRole: "id"
				rootItem: root
				Layout.fillWidth: true
				model: accountsModel
				onCurrentTextChanged:
				{
					worker.currentAccount = currentText
					accountBalance.text = worker.balance(currentText).format()
				}
			}

			DefaultLabel
			{
				id: accountBalance
				Layout.preferredWidth: 70
				visible: text !== ""
			}
		}

		RowLayout
		{
			width: parent.width
			height: 60
			Rectangle
			{
				width: deploymentOption.width / 5
				anchors.verticalCenter: parent.verticalCenter
				DefaultLabel
				{
					text: qsTr("Gas price")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			Rectangle
			{
				color: "transparent"
				Layout.fillWidth: true
				height: 60
				GasPrice
				{
					width: 360
					anchors.left: parent.left
					id: gasPriceConf
					onGasPriceChanged: ctrDeployCtrLabel.setCost()
					defaultGasPrice: true
					defaultUnit: QEther.Finney
				}
			}

			Connections
			{
				target: worker
				id: gasPriceLoad
				property bool loaded: false
				onGasPriceLoaded:
				{
					if (!loaded)
					{
						gasPriceConf.init(worker.gasPriceInt.value())
						ctrDeployCtrLabel.setCost()
					}
					loaded = true
				}
			}
		}

		RowLayout
		{
			id: ctrDeployCtrLabel
			width: parent.width
			height: 30

			function setCost()
			{
				if (gasPriceConf.gasPrice && deployStep.gasUsed)
				{
					var ether = QEtherHelper.createBigInt(deployStep.gasUsed);
					var gasTotal = ether.multiply(gasPriceConf.gasPrice.toWei());
					if (gasTotal)
						gasToUseInput.value = QEtherHelper.createEther(gasTotal.value(), QEther.Wei, parent);
				}
			}

			Rectangle
			{
				width: deploymentOption.width / 5
				anchors.verticalCenter: parent.verticalCenter
				DefaultLabel
				{
					text: qsTr("Deployment cost")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			Ether
			{
				id: gasToUseInput
				displayUnitSelection: false
				displayFormattedValue: true
				edit: false
				Layout.preferredWidth: 400
			}
		}

		RowLayout
		{
			id: deployedRow
			width: parent.width
			height: 50
			Rectangle
			{
				width: deploymentOption.width / 5
				anchors.verticalCenter: parent.verticalCenter
				DefaultLabel
				{
					id: labelAddresses
					text: qsTr("Deployed Contracts")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			Rectangle
			{
				color: "#cccccc"
				Layout.fillWidth: true
				Layout.minimumHeight: 50
				CopyButton
				{
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.leftMargin: -18
					width: 20
					height: 20
					id: copyBtn
					getContent: function()
					{
						return JSON.stringify(projectModel.deploymentAddresses, null, ' ')
					}
				}

				ScrollView
				{
					anchors.fill: parent
					flickableItem.interactive: false
					Rectangle
					{
						anchors.fill: parent
						color: "#cccccc"
						anchors.margins: 8
						ColumnLayout
						{
							spacing: 1
							ListModel
							{
								id: addresses
							}

							Repeater
							{
								id: deployedAddresses
								Layout.fillWidth: true

								function refresh()
								{
									addresses.clear()
									for (var k in projectModel.deploymentAddresses)
									{
										if (k.indexOf("<") === 0)
											addresses.append({ name: k, address: projectModel.deploymentAddresses[k]})
									}
								}

								model: addresses
								Item
								{
									height: 40
									DefaultLabel
									{
										id: name
										text: addresses.get(index).name
									}

									DefaultLabel
									{
										anchors.top: name.bottom
										anchors.left: name.left
										anchors.leftMargin: 30
										id: address
										text: addresses.get(index).address
									}
								}
							}
						}
					}
				}
			}
		}

		Style
		{
			id: style
		}

		RowLayout
		{
			id: verificationRow
			width: parent.width
			height: 50
			Rectangle
			{
				Layout.preferredWidth: deploymentOption.width / 5
				anchors.verticalCenter: parent.verticalCenter
				id: verLabel
				DefaultLabel
				{
					text: qsTr("Verifications")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			Rectangle
			{
				Layout.minimumHeight: 50
				Layout.preferredWidth: parent.width - verLabel.width - 5
				color: "#cccccc"
				visible: false
				DefaultTextArea
				{
					id: verificationTextArea
					visible: false
					backgroundVisible: false
					anchors.fill: parent
					onVisibleChanged:
					{
						parent.visible = visible
					}
				}
			}

			DefaultLabel
			{
				id: verificationLabel
				visible: true
			}
		}
	}	

	Rectangle
	{
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 35
		anchors.rightMargin: 10
		MessageDialog
		{
			id: warning
			text: qsTr("Contracts are going to be deployed. Are you sure? (Another actions may be required on the remote node in order to complere deployment)")
			onYes: {
				deployBtn.deploy()
			}
			standardButtons: StandardButton.Yes | StandardButton.No
		}

		DefaultButton
		{
			id: deployBtn
			anchors.right: parent.right
			text: qsTr("Deploy Scenario")
			onClicked:
			{
				warning.open()
			}

			function deploy()
			{
				projectModel.deployedScenarioIndex = deployStep.selectedScenarioIndex
				NetworkDeploymentCode.deployContracts(deployStep.gasByTx, gasPriceConf.toHexWei(), function(addresses, trHashes)
				{
					projectModel.deploymentTrHashes = trHashes
					worker.verifyHashes(trHashes, function (nb, trLost)
					{
						projectModel.deployBlockNumber = nb
						projectModel.saveProject()
						root.updateVerification(nb, trLost)
						root.deployed()
					})
					projectModel.deploymentAddresses = addresses
					projectModel.saveProject()
					deployedAddresses.refresh()
				});
			}
		}
	}
}



