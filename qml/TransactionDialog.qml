/*
	This file is part of cpp-ethereum.
	cpp-ethereum is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	cpp-ethereum is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	You should have received a copy of the GNU General Public License
	along with cpp-ethereum.  If not, see <http://www.gnu.org/licenses/>.
*/
/** @file transactionDialog.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.QEther 1.0
import org.ethereum.qml.CodeModel 1.0
import org.ethereum.qml.ClientModel 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/InputValidator.js" as InputValidator
import "js/NetworkDeployment.js" as NetworkDeployment
import "js/QEtherHelper.js" as QEtherHelper
import "."

Dialog {
	id: modalTransactionDialog
	modality: Qt.ApplicationModal
	width: 580
	height: 480
	visible: false
	title:  editMode ? qsTr("Edit Transaction") : qsTr("Add Transaction")
	property bool editMode
	property int transactionIndex
	property int blockIndex
	property alias gas: gasValueEdit.gasValue;
	property alias gasAuto: gasAutoCheck.checked;
	property alias gasPrice: gasPriceField.value;
	property alias transactionValue: valueField.value;
	property string contractId: contractCreationComboBox.currentValue();
	property alias functionId: functionComboBox.currentText;
	property var paramValues;
	property var paramsModel: [];
	property alias stateAccounts: senderComboBox.model
	property bool saveStatus
	property bool loaded: false
	property bool enableGasEstimation: true
	signal accepted
	signal closed

	property int rowWidth: 500
	StateDialogStyle {
		id: transactionDialogStyle
	}

	function open(index, blockIdx, item) {
		loaded = false
		gasEstimationClient.reset(codeModel)
		if (mainApplication.systemPointSize >= appSettings.systemPointSize)
		{
			width = 580
			height = 480
			containerRect.implicitWidth = width
			colTrContent.spacing = 10
			colSender.spacing = 5
		}
		else
		{
			width = 580 + (11 * appSettings.systemPointSize)
			height = 480 + (3 * appSettings.systemPointSize)
			containerRect.implicitWidth = width
			colTrContent.spacing = 10 + (Math.round(appSettings.systemPointSize / 4))
			colSender.spacing = 5 + (Math.round(appSettings.systemPointSize / 2))
		}
		paramScroll.setSpacing(colTrContent.spacing)

		transactionIndex = index
		blockIndex = blockIdx
		paramScroll.transactionIndex = index
		paramScroll.blockIndex = blockIdx
		saveStatus = item.saveStatus
		gasValueEdit.gasValue = item.gas;
		gasAutoCheck.checked = item.gasAuto ? true : false;
		gasPriceField.value = item.gasPrice;
		valueField.value = item.value;
		valueField.formatInput()
		var contractId = item.contractId;
		var functionId = item.functionId;

		paramValues = item.parameters !== undefined ? item.parameters : {};
		if (item.sender)
			senderComboBox.select(item.sender)

		trTypeCreate.checked = item.isContractCreation
		trTypeSend.checked = !item.isFunctionCall
		trTypeExecute.checked = item.isFunctionCall && !item.isContractCreation
		load(item.isContractCreation, item.isFunctionCall, functionId, contractId)
		estimatedGas.updateView()
		visible = true;
		senderComboBox.updateCombobox()
		valueField.update()
		gasPriceField.update()
		contractCreationComboBox.updateCombobox()		
		loaded = true
	}

	function loadCtorParameters(contractId)
	{
		paramsModel = [];
		var contract = codeModel.contracts[contractId];
		if (contract) {
			var params = contract.contract.constructor.parameters;
			for (var p = 0; p < params.length; p++)
				loadParameter(params[p]);
		}
		initTypeLoader();
	}

	function loadFunctions(contractId)
	{
		functionsModel.clear();
		var contract = codeModel.contracts[contractId];
		if (contract) {
			var functions = codeModel.contracts[contractId].contract.functions;
			for (var f = 0; f < functions.length; f++) {
				if (functions[f].name !== contractId)
					functionsModel.append({ text: functions[f].name });
			}
		}
	}

	function selectContract(contractName)
	{
		for (var k = 0; k < contractsModel.count; k++)
		{
			if (contractsModel.get(k).cid === contractName)
			{
				contractComboBox.currentIndex = k;
				break;
			}
		}
	}

	function selectFunction(functionId)
	{
		var functionIndex = -1;
		for (var f = 0; f < functionsModel.count; f++)
			if (functionsModel.get(f).text === functionId)
				functionIndex = f;

		if (functionIndex == -1 && functionsModel.count > 0)
			functionIndex = 0; //@todo suggest unused function

		functionComboBox.currentIndex = functionIndex;
	}

	function loadParameter(parameter)
	{
		var type = parameter.type;
		var pname = parameter.name;
		paramsModel.push({ name: pname, type: type });
	}

	function loadParameters() {
		paramsModel = []
		if (functionComboBox.currentIndex >= 0 && functionComboBox.currentIndex < functionsModel.count) {
			var contract = codeModel.contracts[TransactionHelper.contractFromToken(recipientsAccount.currentValue())];
			if (contract) {
				var func = getFunction(functionComboBox.currentText, contract);
				if (func) {
					var parameters = func.parameters;
					for (var p = 0; p < parameters.length; p++)
						loadParameter(parameters[p]);
				}
			}
		}
		initTypeLoader();
	}

	function getFunction(name, contract)
	{
		for (var k in contract.contract.functions)
		{
			if (contract.contract.functions[k].name === name)
			{
				return contract.contract.functions[k]
			}
		}
		return null
	}

	function initTypeLoader()
	{
		paramScroll.clear()
		paramScroll.value = paramValues;
		paramScroll.members = paramsModel;
		paramScroll.updateView()
	}

	function acceptAndClose()
	{
		close();
		accepted();
	}

	function close()
	{
		gasEstimationTimer.running = false
		visible = false;
		closed()
	}

	function getItem()
	{
		var item = TransactionHelper.defaultTransaction();
		item = {
			contractId: transactionDialog.contractId,
			functionId: transactionDialog.functionId,
			gas: transactionDialog.gas,
			gasAuto: transactionDialog.gasAuto,
			gasPrice: transactionDialog.gasPrice,
			value: transactionDialog.transactionValue,
			parameters: {},
		};
		item.isContractCreation = trTypeCreate.checked;
		if (item.isContractCreation)
			item.functionId = item.contractId;
		item.isFunctionCall = trTypeExecute.checked

		if (!item.isContractCreation)
		{
			item.contractId = recipientsAccount.currentValue();
			item.label = TransactionHelper.contractFromToken(item.contractId) + "." + item.functionId + "()";
			if (recipientsAccount.current().type === "address")
			{
				item.functionId = "";
				item.isFunctionCall = false
				item.label = item.contractId
			}
		}
		else
		{
			item.isFunctionCall = true
			item.functionId = item.contractId;
			item.label = item.contractId + "." + item.contractId + "()";
		}
		item.saveStatus = saveStatus
		item.sender = senderComboBox.model[senderComboBox.currentIndex].secret;
		item.parameters = paramValues;
		return item;
	}

	function load(isContractCreation, isFunctionCall, functionId, contractId)
	{
		if (loaded)
		{
			paramsModel = []
			paramValues = {}
		}

		if (!isContractCreation)
		{
			contractCreationComboBox.visible = false
			colRecipient.visible = true
			recipientsAccount.visible = true
			recipientsAccount.accounts = senderComboBox.model;
			amountLabel.text = qsTr("Amount")
			if (!isFunctionCall)
				recipientsAccount.subType = "address"
			else
				recipientsAccount.subType = "contract";
			recipientsAccount.load();
			recipientsAccount.init();
			if (contractId)
				recipientsAccount.select(contractId)
			else
				recipientsAccount.selectFirst()
			if (functionId)
				selectFunction(functionId);
			else
				functionComboBox.currentIndex = 0
			if (isFunctionCall)
			{
				labelRecipient.text = qsTr("Recipient Contract")
				functionRect.show()
				loadFunctions(TransactionHelper.contractFromToken(recipientsAccount.currentValue()))
				loadParameters();
			}
			else
			{
				paramsModel = []
				labelRecipient.text = qsTr("Recipient Account")
				functionRect.hide()
				paramScroll.updateView()
			}
		}
		else
		{
			//contract creation
			contractsModel.clear();
			var contractIndex = -1;
			var contracts = codeModel.contracts;
			for (var c in contracts) {
				contractsModel.append({ cid: c, text: contracts[c].contract.name });
				if (contracts[c].contract.name === contractId)
					contractIndex = contractsModel.count - 1;
			}

			if (contractIndex == -1 && contractsModel.count > 0)
				contractIndex = 0; //@todo suggest unused contract
			contractCreationComboBox.currentIndex = contractIndex;
			contractCreationComboBox.visible = true
			labelRecipient.text = qsTr("Contract")
			amountLabel.text = qsTr("Endownment")
			functionRect.hide()
			colRecipient.visible = false
			recipientsAccount.visible = false
			loadCtorParameters(contractCreationComboBox.currentValue());
		}
	}

	contentItem: Rectangle {
		id: containerRect
		color: transactionDialogStyle.generic.backgroundColor
		anchors.fill: parent
		implicitHeight: modalTransactionDialog.height
		implicitWidth: modalTransactionDialog.width
		ScrollView
		{
			anchors.top: parent.top
			width: parent.width
			height: parent.height - separator.height - validationRow.height
			flickableItem.interactive: false
			ColumnLayout {
				id: colTrContent
				Layout.preferredWidth: rowWidth
				anchors.top: parent.top
				anchors.left: parent.left
				anchors.topMargin: 10
				width: 460
				anchors.leftMargin:
				{
					return (containerRect.width - width) /2
				}
				spacing: 10

				RowLayout
				{
					Layout.minimumHeight: 60
					Rectangle
					{
						color: "transparent"
						Layout.preferredWidth: 100
						Layout.fillHeight: true
						DefaultLabel {
							anchors.right: parent.right
							anchors.verticalCenter: parent.verticalCenter
							text: qsTr("Sender Account")
						}
					}
					ColumnLayout
					{
						id: colSender
						spacing: 5
						Layout.minimumHeight: 60
						DefaultCombobox {
							anchors.top: parent.top
							function select(secret)
							{
								for (var i in model)
									if (model[i].secret === secret)
									{
										currentIndex = i;
										break;
									}
							}
							Layout.preferredWidth: 350
							id: senderComboBox
							rootItem: modalTransactionDialog
							currentIndex: 0
							textRole: "name"
							editable: false

							onCurrentIndexChanged:
							{
								update()
								updateCombobox()
							}

							onModelChanged:
							{
								update()
								updateCombobox()
							}

							Component.onCompleted: {
								update()
								updateCombobox()
							}

							function update()
							{
								for (var i in model)
									if (model[i].name === currentText)
									{
										addressCopyInput.originalText = model[i].address
										break;
									}
							}
						}

						DisableInput
						{
							Layout.minimumWidth: 350
							id: addressCopyInput
						}
					}
				}

				RowLayout
				{
					Rectangle
					{
						Layout.preferredWidth: 100
						color: "transparent"
						DefaultLabel
						{
							anchors.verticalCenter: parent.verticalCenter
							anchors.right: parent.right
							text: qsTr("Type of Transaction")
						}
					}

					Column
					{
						Layout.preferredWidth: 350
						Layout.minimumHeight: 90
						ExclusiveGroup {
							id: rbbuttonList
							onCurrentChanged: {
								if (current)
								{
									if (current.objectName === "trTypeSend")
									{
										colRecipient.visible = true
										recipientsAccount.visible = true
										contractCreationComboBox.visible = false
										modalTransactionDialog.load(false, false)
									}
									else if (current.objectName === "trTypeCreate")
									{
										colRecipient.visible = false
										contractCreationComboBox.visible = true
										recipientsAccount.visible = false
										modalTransactionDialog.load(true, true)
									}
									else if (current.objectName === "trTypeExecute")
									{
										colRecipient.visible = true
										recipientsAccount.visible = true
										contractCreationComboBox.visible = false
										modalTransactionDialog.load(false, true)
									}
								}
							}
						}

						DefaultRadioButton {
							id: trTypeSend
							objectName: "trTypeSend"
							exclusiveGroup: rbbuttonList
							height: 30
							text: qsTr("Send Ether to Account")
						}

						DefaultRadioButton {
							id: trTypeCreate
							objectName: "trTypeCreate"
							exclusiveGroup: rbbuttonList
							height: 30
							text: qsTr("Create Contract")
						}

						DefaultRadioButton {
							id: trTypeExecute
							objectName: "trTypeExecute"
							exclusiveGroup: rbbuttonList
							height: 30
							text: qsTr("Transact with Contract")
						}
					}
				}

				RowLayout
				{
					Rectangle
					{
						color: "transparent"
						Layout.preferredWidth: 100
						Layout.fillHeight: true
						DefaultLabel {
							id: labelRecipient
							anchors.verticalCenter: parent.verticalCenter
							anchors.right: parent.right
							text: qsTr("Recipient Account")
						}
					}

					ColumnLayout
					{
						id: colRecipient
						QAddressView
						{
							Layout.preferredWidth: 350
							id: recipientsAccount
							displayInput: false
							onIndexChanged:
							{
								if (loaded)
									paramValues = {}
								if (rbbuttonList.current.objectName === "trTypeExecute")
								{
									loadFunctions(TransactionHelper.contractFromToken(currentValue()))
									loadParameters();
									paramScroll.updateView()
								}
								var addr = getAddress()
								addrRecipient.originalText = addr.indexOf("0x") === 0 ? addr.replace("0x", "") : addr
							}
						}

						DisableInput
						{
							Layout.preferredWidth: 350
							id: addrRecipient
						}
					}

					DefaultCombobox {
						id: contractCreationComboBox
						function currentValue() {
							return (currentIndex >=0 && currentIndex < contractsModel.count) ? contractsModel.get(currentIndex).cid : "";
						}
						Layout.preferredWidth: 350
						currentIndex: -1
						rootItem: modalTransactionDialog
						textRole: "text"
						editable: false
						model: ListModel {
							id: contractsModel
						}
						onCurrentIndexChanged: {
							if (loaded)
								paramValues = {}
							loadCtorParameters(currentValue());
						}
					}
				}

				RowLayout
				{
					Rectangle
					{
						Layout.preferredWidth: 100
						id: functionRect

						function hide()
						{
							parent.visible = false
							functionRect.visible = false
							functionComboBox.visible = false
						}

						function show()
						{
							parent.visible = true
							functionRect.visible = true
							functionComboBox.visible = true
						}

						DefaultLabel {
							anchors.verticalCenter: parent.verticalCenter
							anchors.right: parent.right
							text: qsTr("Function")
						}
					}

					DefaultCombobox {
						id: functionComboBox
						Layout.preferredWidth: 350
						currentIndex: -1
						textRole: "text"
						rootItem: modalTransactionDialog
						editable: false
						model: ListModel {
							id: functionsModel
						}
						onCurrentIndexChanged: {
							loadParameters();
						}
					}
				}

				StructView
				{
					id: paramScroll
					members: paramsModel
					accounts: senderComboBox.model
					context: "parameter"
					Layout.fillWidth: true
					anchors.left: parent.left
					anchors.leftMargin: -50
					function updateView()
					{
						paramScroll.visible = paramsModel.length > 0
						paramScroll.Layout.minimumHeight = paramScroll.colHeight
						if (paramsModel.length === 0)
							paramScroll.height = 0
					}
				}

				RowLayout
				{
					Rectangle
					{
						Layout.preferredWidth: 100
						DefaultLabel {
							id: amountLabel
							anchors.verticalCenter: parent.verticalCenter
							anchors.right: parent.right
							text: qsTr("Amount")
						}
					}

					Ether {
						Layout.minimumWidth: 350
						id: valueField
						edit: true
						displayFormattedValue: true
						displayUnitSelection: true
					}
				}

				Rectangle
				{
					Layout.minimumHeight: 1
					Layout.fillWidth: true
					color: "transparent"
					Rectangle
					{
						color: "#cccccc"
						height: 1
						width: parent.width
						anchors.verticalCenter: parent.verticalCenter
					}
				}

				DefaultLabel {
					text: qsTr("Transaction fees")
					anchors.horizontalCenter: parent.horizontalCenter
					font.bold: true
				}

				RowLayout
				{
					Layout.minimumHeight: 45
					Rectangle
					{
						Layout.preferredWidth: 100
						DefaultLabel {
							anchors.verticalCenter: parent.verticalCenter
							anchors.right: parent.right
							text: qsTr("Gas")
						}
					}

					ColumnLayout
					{
						Layout.preferredWidth: 350
						spacing: 0
						Row
						{
							spacing: 5
							DefaultTextField
							{
								property variant gasValue
								onGasValueChanged: text = gasValue.value();
								onTextChanged: gasValue.setValue(text);
								implicitWidth: 200
								enabled: !gasAutoCheck.checked
								id: gasValueEdit
							}

							CheckBox
							{
								anchors.verticalCenter: parent.verticalCenter
								id: gasAutoCheck
								checked: true
								style: CheckBoxStyle {
									label: DefaultLabel
									{
									text: qsTr("Auto");
								}
							}
						}
						}

						DefaultLabel
						{
							id: estimatedGas
							text: ""
							Connections
							{
								target: functionComboBox
							}

							function updateView()
							{
								if (rbbuttonList.current.objectName === "trTypeSend")
								{
									var gas = codeModel.txGas
									estimatedGas.text = qsTr("Estimated cost: ") + gas + " gas"
								}
							}

							Connections
							{
								target: rbbuttonList
								onCurrentChanged: {
									estimatedGas.updateView()
								}
							}
						}
					}
			}

			RowLayout
			{
				Layout.minimumHeight: 45
				Rectangle
				{
					Layout.preferredWidth: 100
					DefaultLabel {
						id: gasPriceLabel
						anchors.verticalCenter: parent.verticalCenter
						anchors.right: parent.right
						text: qsTr("Gas Price")
					}
				}

				ColumnLayout
				{
					Layout.preferredWidth: 350
					spacing: 0
					Ether {
						Layout.preferredWidth: 350
						width: 350
						id: gasPriceField
						edit: true
						displayFormattedValue: true
						displayUnitSelection: true
					}

					DefaultLabel {
						id: gasPriceMarket
						Component.onCompleted:
						{
							gasPriceMarket.visible = false
							NetworkDeployment.gasPrice(function(result)
							{
								gasPriceMarket.visible = true
								gasPriceMarket.text = qsTr("Current market: ") + " " + QEtherHelper.createEther(result, QEther.Wei).format()
							}, function (){});
						}
					}
				}
			}

			RowLayout
			{
				Layout.minimumHeight: 20
			}
		}
	}

	CommonSeparator
	{
		id: separator
		height: 1
		width: parent.width
		anchors.bottom: validationRow.top
	}

	Rectangle
	{
		anchors.bottom: parent.bottom
		width: parent.width
		height: 50
		color: transactionDialogStyle.generic.backgroundColor
		id: validationRow
		Row
		{
			layoutDirection: Qt.RightToLeft

			anchors.right: parent.right
			anchors.rightMargin: 10
			spacing: 10
			height: 50
			DefaultButton {
				anchors.verticalCenter: parent.verticalCenter
				id: updateBtn
				text: qsTr("Cancel");
				onClicked: close();
			}

			DefaultButton {
				anchors.verticalCenter: parent.verticalCenter
				text: editMode ? qsTr("Update") : qsTr("OK")
				onClicked: {
					var invalid = InputValidator.validate(paramsModel, paramValues);
					if (invalid.length === 0)
					{
						close();
						accepted();
					}
					else
					{
						errorDialog.text = qsTr("Some parameters are invalid:\n");
						for (var k in invalid)
							errorDialog.text += invalid[k].message + "\n";
						errorDialog.open();
					}
				}
			}

			MessageDialog {
				id: errorDialog
				standardButtons: StandardButton.Ok
				icon: StandardIcon.Critical
			}
		}
	}

	CodeModel {
		id: gasEstimationCode
	}

	property variant clientEstimation

	Timer
	{
		property string txHash: ""
		id: gasEstimationTimer
		repeat: true
		running: false
		interval: 700
		onTriggered:
		{
			var item = getItem()
			item.gasAuto = true
			var newHash = codeModel.sha3(JSON.stringify(item))
			if (txHash !== newHash)
			{
				txHash = newHash
				gasEstimationClient.setupContext(item)
			}
		}
	}

	ClientModel
	{
		id: gasEstimationClient
		codeModel: gasEstimationCode
		property bool scenarioLoaded: false
		property bool txRequested: false
		property int txLength: 0
		property int currentTx: 0
		property var tx
		Component.onCompleted:
		{
			if (enableGasEstimation)
				gasEstimationClient.init("/gasEstimationTx")
		}

		onNewRecord:
		{
			currentTx++
			if (txRequested && currentTx > txLength)
			{
				var gas = gasEstimationClient.gasCosts[gasEstimationClient.gasCosts.length - 1]
				estimatedGas.text = qsTr("Estimated cost: ") + gas + " gas"
				txRequested = false
				currentTx = 0
			}
		}

		onSetupFinished:
		{
			scenarioLoaded = true
			gasEstimationClient.executeTr(tx);
			txRequested = true
		}

		function reset(devCodeModel)
		{
			if (enableGasEstimation)
			{
				scenarioLoaded = false
				var docs = {}
				for (var c in devCodeModel.contracts)
				{
					var docId = devCodeModel.contracts[c].documentId
					if (!docs[docId])
					{
						gasEstimationCode.registerCodeChange(docId, fileIo.readFile(docId));
						docs[docId] = ""
					}
				}
				gasEstimationTimer.running = true
			}
		}

		function setupContext(tx)
		{
			if (!gasEstimationClient.running && enableGasEstimation)
			{
				gasEstimationClient.tx = tx
				estimatedGas.text = qsTr("Computing gas estimation...")
				var scenario = projectModel.stateListModel.getState(mainContent.rightPane.bcLoader.selectedScenarioIndex)
				txLength = 0
				currentTx = 0
				for (var i in scenario.blocks)
					txLength += scenario.blocks[i].transactions.length
				gasEstimationClient.setupScenario(scenario)
			}
		}
	}
}
}

