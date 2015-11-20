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
	property var gasByTx
	property var gasUsed
	property int labelWidth: 150
	property int selectedScenarioIndex


	function show()
	{
		init()
	}

	function init()
	{
		visible = true
		contractList.currentIndex = 0
		contractList.change()

		if (worker.currentAccount === "" && worker.accounts.length > 0)
		{
			worker.currentAccount = worker.accounts[0].id
			accountsList.currentIndex = 0
		}
		worker.renewCtx()
		selectedScenarioIndex = 0
	}

	function calculateContractDeployGas()
	{
		if (!root.visible)
			return;
		var sce = projectModel.stateListModel.getState(contractList.currentIndex)
		worker.estimateGas(sce, function(gas) {
			gasByTx = gas
			gasUsed = 0
			for (var k in gas)
				gasUsed += gas[k]
			gasUsedLabel.text = gasUsed
		});
	}

	ColumnLayout
	{
		anchors.top: parent.top
		anchors.fill: parent
		anchors.margins: 10
		id: chooseSceCol

		DefaultLabel
		{
			anchors.top: parent.top
			Layout.fillWidth: true
			text: qsTr("Choose node and scenario")
			font.bold: true
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 60
			id: scenarioList

			Rectangle
			{
				Layout.preferredWidth: chooseSceCol.width / 5
				anchors.verticalCenter: parent.verticalCenter
				DefaultLabel
				{
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					text: qsTr("Ethereum node URL")
				}
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
				}

				onNodeReachable:
				{
					if (!root.visible && connectState === 1)
						return
					connectState = 1
					nodeError.visible = false
				}
			}

			DefaultTextField
			{
				Layout.preferredWidth: 500
				text: appSettings.nodeAddress;
				onTextChanged: {
					appSettings.nodeAddress = text
					root.init()
				}

				DefaultLabel
				{
					id: nodeError
					anchors.top: parent.bottom
					visible: false
					color: "red"
					text: qsTr("Unable to contact Ethereum node on ") + appSettings.nodeAddress
				}
			}
		}

		RowLayout
		{
			Rectangle
			{
				Layout.preferredWidth: chooseSceCol.width / 5
				anchors.top: parent.top
				anchors.topMargin: 12
				DefaultLabel
				{
					text: qsTr("Pick scenario to deploy")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			ColumnLayout
			{
				Layout.preferredWidth: 400
				DefaultCombobox
				{
					id: contractList
					Layout.fillWidth: true
					model: projectModel.stateListModel
					textRole: "title"
					rootItem: root
					onCurrentIndexChanged:
					{
						if (root.visible)
							change()
					}

					function change()
					{
						selectedScenarioIndex = currentIndex
						trListModel.clear()
						if (currentIndex > -1)
						{
							if (projectModel.stateListModel)
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
								calculateContractDeployGas()
							}
						}
					}
				}

				Rectangle
				{
					Layout.fillHeight: true
					Layout.fillWidth: true
					id: trContainer
					color: "#cccccc"
					visible: trListModel.count > 0
					ScrollView
					{
						anchors.fill: parent
						horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
						flickableItem.interactive: false
						ColumnLayout
						{
							spacing: 5
							anchors.top: parent.top
							anchors.topMargin: 5

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
									spacing: 2
									Layout.minimumHeight:
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

									DefaultLabel
									{
										id: trLabel
										Layout.minimumHeight: 20
										anchors.left: parent.left
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
										Layout.minimumHeight:
										{
											if (index > -1)
												return trListModel.get(index)["parameters"].count * 20
											else
												return 0
										}
										Layout.fillWidth: true
										model: paramList
										DefaultLabel
										{
											Layout.minimumHeight: 20
											anchors.left: parent.left
											anchors.leftMargin: 20
											text: name + " = " + value
											font.italic: true
										}
									}

									Rectangle
									{
										anchors.bottom: parent.bottom
										Layout.preferredWidth: chooseSceCol.width
										Layout.minimumHeight: 1
										color: "#ededed"
										visible: true
									}
								}
							}
						}
					}
				}
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 60
			Rectangle
			{
				Layout.preferredWidth: chooseSceCol.width / 5
				anchors.verticalCenter: parent.verticalCenter
				DefaultLabel
				{
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					text: qsTr("Gas used")
				}
			}

			DefaultLabel
			{
				Layout.preferredWidth: 500
				id: gasUsedLabel
			}
		}
	}
}

