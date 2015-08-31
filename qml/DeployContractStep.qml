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

Rectangle {
	property variant paramsModel: []
	property variant worker
	property variant gas: []
	color: "#E3E3E3E3"
	signal deployed
	anchors.fill: parent
	id: root

	property int labelWidth: 150
	property bool verifyDeploy: true

	function show()
	{
		init()
	}

	function init()
	{
		visible = true
		contractList.currentIndex = 0
		contractList.change()
		accountsModel.clear()
		for (var k in worker.accounts)
			accountsModel.append(worker.accounts[k])

		if (worker.currentAccount === "" && worker.accounts.length > 0)
		{
			worker.currentAccount = worker.accounts[0].id
			accountsList.currentIndex = 0
		}

		verifyDeployedContract()
		deployedAddresses.refresh()

		worker.renewCtx()
		verifyDeploy = true
		worker.pooler.onTriggered.connect(function() {
			if (root.visible && verifyDeploy)
				verifyDeployedContract();
		})
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

	RowLayout
	{
		anchors.fill: parent
		anchors.margins: 10
		ColumnLayout
		{
			anchors.top: parent.top
			Layout.preferredWidth: parent.width * 0.40 - 20
			Layout.fillHeight: true
			id: scenarioList

			Label
			{
				Layout.fillWidth: true
				text: qsTr("Ethereum node URL")
				font.bold: true
			}

			TextField
			{
				Layout.preferredWidth: parent.width - 20
				text: appSettings.nodeAddress;
				onTextChanged: {
					appSettings.nodeAddress = text
					root.init()
				}
			}

			Label
			{
				text: qsTr("Pick scenario to deploy")
				font.bold: true
			}

			ComboBox
			{
				id: contractList
				Layout.preferredWidth: parent.width - 20
				model: projectModel.stateListModel
				textRole: "title"
				onCurrentIndexChanged:
				{
					if (root.visible)
						change()
				}

				function change()
				{
					trListModel.clear()
					if (currentIndex > -1)
					{
						for (var k = 0; k < projectModel.stateListModel.get(currentIndex).blocks.count; k++)
						{
							for (var j = 0; j < projectModel.stateListModel.get(currentIndex).blocks.get(k).transactions.count; j++)
							{
								var tx = projectModel.stateListModel.get(currentIndex).blocks.get(k).transactions.get(j)
								if (tx.isFunctionCall || tx.isContractCreation)
									trListModel.append(projectModel.stateListModel.get(currentIndex).blocks.get(k).transactions.get(j));
							}
						}
						for (var k = 0; k < trListModel.count; k++)
							trList.itemAt(k).init()
						ctrDeployCtrLabel.calculateContractDeployGas();
					}
				}
			}

			Rectangle
			{
				Layout.fillHeight: true
				Layout.preferredWidth: parent.width - 20
				id: trContainer
				color: "white"
				border.color: "#cccccc"
				border.width: 1
				ScrollView
				{
					anchors.fill: parent
					horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
					ColumnLayout
					{
						spacing: 0

						ListModel
						{
							id: trListModel
						}

						Repeater
						{
							id: trList
							model: trListModel
							ColumnLayout
							{
								Layout.fillWidth: true
								spacing: 5
								Layout.preferredHeight:
								{
									if (index > -1)
										return 20 + trListModel.get(index)["parameters"].count * 20
									else
										return 20
								}

								function init()
								{
									paramList.clear()
									if (trListModel.get(index).parameters)
									{
										for (var k in trListModel.get(index).parameters)
											paramList.append({ "name": k, "value": trListModel.get(index).parameters[k] })
									}
								}

								Label
								{
									id: trLabel
									Layout.preferredHeight: 20
									anchors.left: parent.left
									anchors.top: parent.top
									anchors.topMargin: 5
									anchors.leftMargin: 10
									text:
									{
										if (index > -1)
											return trListModel.get(index).label
										else
											return ""
									}
								}

								ListModel
								{
									id: paramList
								}

								Repeater
								{
									Layout.preferredHeight:
									{
										if (index > -1)
											return trListModel.get(index)["parameters"].count * 20
										else
											return 0
									}
									model: paramList
									Label
									{
										Layout.preferredHeight: 20
										anchors.left: parent.left
										anchors.leftMargin: 20
										text: name + "=" + value
										font.italic: true
									}
								}

								Rectangle
								{
									Layout.preferredWidth: scenarioList.width
									Layout.preferredHeight: 1
									color: "#cccccc"
								}
							}
						}
					}
				}
			}
		}

		ColumnLayout
		{
			anchors.top: parent.top
			Layout.preferredHeight: parent.height - 25
			ColumnLayout
			{
				anchors.top: parent.top
				Layout.preferredWidth: parent.width * 0.60
				Layout.fillHeight: true
				id: deploymentOption
				spacing: 8

				Label
				{
					id: deploylabel
					anchors.left: parent.left
					anchors.leftMargin: 105
					text: qsTr("Select deployment options")
					font.bold: true
				}


				Label
				{
					id: nodeError
					visible: false
					color: "red"
					Layout.fillWidth: true
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
					}
					onNodeReachable:
					{
						if (!root.visible && connectState === 1)
							return
						connectState = 1
						nodeError.visible = false
						deploylabel.visible = true
					}
				}

				ListModel
				{
					id: accountsModel
				}

				RowLayout
				{
					Layout.fillWidth: true
					Rectangle
					{
						width: labelWidth
						Label
						{
							text: qsTr("Deployment account")
							anchors.left: parent.left
							anchors.verticalCenter: parent.verticalCenter
						}
					}					

					ComboBox
					{
						id: accountsList
						textRole: "id"
						model: accountsModel
						Layout.fillWidth: true
						onCurrentTextChanged:
						{
							worker.currentAccount = currentText
							accountBalance.text = worker.balance(currentText).format()
						}
					}

					Label
					{
						id: accountBalance
					}
				}

				RowLayout
				{
					Layout.fillWidth: true
					Rectangle
					{
						Layout.preferredWidth: labelWidth
						Label
						{
							text: qsTr("Gas price")
							anchors.left: parent.left
							anchors.verticalCenter: parent.verticalCenter
						}
					}

					GasPrice
					{
						id: gasPriceConf
						onGasPriceChanged: ctrDeployCtrLabel.setCost()
						defaultGasPrice: true
					}

					Connections
					{
						target: worker
						id: gasPriceLoad
						property bool loaded: false
						onGasPriceLoaded:
						{
							gasPriceConf.init(worker.gasPriceInt.value())
							gasPriceLoad.loaded = true
							ctrDeployCtrLabel.calculateContractDeployGas()
						}
					}
				}

				RowLayout
				{
					id: ctrDeployCtrLabel
					Layout.fillWidth: true
					property int cost
					function calculateContractDeployGas()
					{
						if (!root.visible)
							return;
						var sce = projectModel.stateListModel.getState(contractList.currentIndex)
						worker.estimateGas(sce, function(gas) {
							if (gasPriceLoad.loaded)
							{
								root.gas = gas
								cost = 0
								for (var k in gas)
									cost += gas[k]
								setCost()
							}
						});
					}

					function setCost()
					{
						if (gasPriceConf.gasPrice)
						{
							var ether = QEtherHelper.createBigInt(cost);
							var gasTotal = ether.multiply(gasPriceConf.gasPrice.toWei());
							if (gasTotal)
								gasToUseInput.value = QEtherHelper.createEther(gasTotal.value(), QEther.Wei, parent);
						}
					}

					Rectangle
					{
						width: labelWidth
						Label
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
						Layout.preferredWidth: 350
					}
				}

				Rectangle
				{
					Layout.fillWidth: true
					Layout.preferredHeight: parent.height + 25
					color: "transparent"
					id: rectDeploymentVariable
					ColumnLayout
					{
						width: parent.width
						RowLayout
						{
							id: deployedRow
							Layout.fillWidth: true
							Rectangle
							{
								width: labelWidth
								Label
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
								Layout.preferredHeight: 100

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

								Button
								{
									iconSource: "qrc:/qml/img/action_reset.png"
									tooltip: qsTr("Reset")
									width: 20
									height: 20
									anchors.top: copyBtn.bottom
									anchors.left: parent.left
									anchors.leftMargin: -18
									onClicked:
									{
										resetDialog.open()
									}
								}

								MessageDialog
								{
									id: resetDialog
									text: qsTr("This action removes all the properties related to this deployment (including contract addresses and packaged ressources).")
									onAccepted: {
										worker.forceStopPooling()
										if (projectModel.deploymentDir && projectModel.deploymentDir !== "")
											fileIo.deleteDir(projectModel.deploymentDir)
										projectModel.cleanDeploymentStatus()
										deploymentDialog.steps.reset()
									}
									standardButtons: StandardButton.Yes | StandardButton.No
								}

								ScrollView
								{
									anchors.fill: parent
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
													Label
													{
														id: name
														text: addresses.get(index).name
														font.pointSize: 10
													}

													Label
													{
														anchors.top: name.bottom
														anchors.left: name.left
														anchors.leftMargin: 30
														id: address
														text: addresses.get(index).address
														font.pointSize: 9
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
							Layout.fillWidth: true
							Rectangle
							{
								width: labelWidth
								Label
								{
									text: qsTr("Verifications")
									anchors.left: parent.left
									anchors.verticalCenter: parent.verticalCenter
								}
							}

							Rectangle
							{
								Layout.preferredHeight: 65
								Layout.fillWidth: true
								color: "#cccccc"
								TextArea
								{
									id: verificationTextArea
									visible: false
									font.pointSize: 10
									backgroundVisible: false
									anchors.fill: parent
								}
							}

							Label
							{
								id: verificationLabel
								visible: true
							}
						}
					}
				}
			}

			Rectangle
			{
				Layout.preferredWidth: parent.width
				Layout.alignment: Qt.BottomEdge

				MessageDialog
				{
					id: warning
					text: qsTr("Contracts are going to be deployed. Are you sure? (Another actions may be required on the remote node in order to complere deployment)")
					onAccepted: {
						deployBtn.deploy()
					}
					standardButtons: StandardButton.Yes | StandardButton.No
				}

				Button
				{
					id: deployBtn
					anchors.right: parent.right
					text: qsTr("Deploy contracts")
					onClicked:
					{
						warning.open()
					}

					function deploy()
					{
						projectModel.deployedScenarioIndex = contractList.currentIndex
						NetworkDeploymentCode.deployContracts(root.gas, gasPriceInput.toHexWei(), function(addresses, trHashes)
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
	}
}

