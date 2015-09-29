import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import org.ethereum.qml.QEther 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "js/TransactionHelper.js" as TransactionHelper
import "js/QEtherHelper.js" as QEtherHelper
import "."

Rectangle {
	id: root
	property variant tx
	property variant currentState
	property variant bc
	property variant storage
	property var blockIndex
	property var txIndex
	property var callIndex

	property string selectedTxColor: "#accbf2"
	property string selectedBlockForeground: "#445e7f"

	function clear()
	{
		inputParams.clear()
		returnParams.clear()
		accounts.clear()
		events.clear()
		ctrStorage.clear()
	}

	function addAccount(address, amount)
	{
		accounts.add(address, amount)
	}

	function updateWidthTx(_tx, _state, _blockIndex, _txIndex, _callIndex)
	{
		tx = _tx
		blockIndex  = _blockIndex
		txIndex = _txIndex
		callIndex = _callIndex
		currentState = _state
		storage = clientModel.contractStorage(_tx.recordIndex, _tx.isContractCreation ? _tx.returned : blockChain.getContractAddress(_tx.contractId))
		inputParams.init()
		if (_tx.isContractCreation)
		{
			returnParams.role = "creationAddr"
			returnParams._data = {
				creationAddr : {
				}
			}
			returnParams._data.creationAddr[qsTr("contract address")] = _tx.returned
		}
		else
		{
			returnParams.role = "returnParameters"
			returnParams._data = tx
		}
		returnParams.init()
		accounts.init()
		events.init()
		ctrStorage.init()
	}

	color: selectedTxColor
	radius: 4
	Column {
		anchors.fill: parent
		spacing: 2

		KeyValuePanel
		{
			visible: false
			height: minHeight
			width: parent.width - 30
			anchors.horizontalCenter: parent.horizontalCenter
			id: inputParams
			title: qsTr("INPUT PARAMETERS")
			role: "parameters"
			_data: tx
			onMinimized:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - maxHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + minHeight
			}
			onExpanded:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - minHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + maxHeight
			}
		}

		KeyValuePanel
		{
			visible: false
			height: minHeight
			width: parent.width - 30
			anchors.horizontalCenter: parent.horizontalCenter
			id: returnParams
			title: qsTr("RETURN PARAMETERS")
			role: "returnParameters"
			_data: tx
			onMinimized:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - maxHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + minHeight
			}
			onExpanded:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - minHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + maxHeight
			}
		}

		KeyValuePanel
		{
			height: minHeight
			width: parent.width - 30
			anchors.horizontalCenter: parent.horizontalCenter
			id: ctrStorage
			title: qsTr("CONTRACT STORAGE")
			function computeData()
			{
				model.clear()
				for (var k in storage.values)
					model.append({ "key": k, "value": JSON.stringify(storage.values[k]) })
			}
			onMinimized:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - maxHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + minHeight
			}
			onExpanded:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - minHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + maxHeight
			}
		}

		KeyValuePanel
		{
			height: minHeight
			width: parent.width - 30
			anchors.horizontalCenter: parent.horizontalCenter
			id: accounts
			title: qsTr("ACCOUNTS")
			role: "accounts"
			_data: currentState
			function computeData()
			{
				model.clear()
				var ret = []
				if (currentState)
					for (var k in currentState.accounts)
					{
						var label = blockChain.addAccountNickname(k, false)
						if (label === k)
							label = blockChain.addContractName(k) //try to resolve the contract name
						model.append({ "key": label, "value": currentState.accounts[k] })
					}
			}
			onMinimized:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - maxHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + minHeight
			}
			onExpanded:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - minHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + maxHeight
			}
		}

		KeyValuePanel
		{
			visible: false
			height: minHeight
			width: parent.width - 30
			anchors.horizontalCenter: parent.horizontalCenter
			id: events
			title: qsTr("EVENTS")
			function computeData()
			{
				model.clear()
				var ret = []
				for (var k in tx.logs)
				{
					var param = ""
					for (var p in tx.logs[k].param)
					{
						param += " " + tx.logs[k].param[p].value + " "
					}
					param = "(" + param + ")"
					model.append({ "key": tx.logs[k].name, "value": param })
				}
			}
			onMinimized:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - maxHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + minHeight
			}
			onExpanded:
			{
				root.Layout.preferredHeight = root.Layout.preferredHeight - minHeight
				root.Layout.preferredHeight = root.Layout.preferredHeight + maxHeight
			}
		}
	}
}

