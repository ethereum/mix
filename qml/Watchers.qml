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

Rectangle
{
	border.color: "#cccccc"
	border.width: 2
	color: "white"

	property variant tx
	property variant currentState
	property variant bc
	property var blockIndex
	property var txIndex
	property var callIndex

	property string selectedTxColor: "#accbf2"
	property string selectedBlockForeground: "#445e7f"

	function clear()
	{
		from.text = ""
		to.text = ""
		value.text = ""
		inputParams.clear()
		returnParams.clear()
		accounts.clear()
		events.clear()
	}

	function addAccount(address, amount)
	{
		accounts.add(address, amount)
	}

	function updateWidthTx(_tx, _state, _blockIndex, _txIndex, _callIndex)
	{		
		var addr = clientModel.resolveAddress(_tx.sender)
		from.text =  blockChain.addAccountNickname(addr, true)
		to.text = blockChain.formatRecipientLabel(_tx)
		value.text = _tx.value.format()
		tx = _tx
		blockIndex  = _blockIndex
		txIndex = _txIndex
		callIndex = _callIndex
		currentState = _state
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
	}

	Rectangle {
		color: selectedTxColor
		anchors.fill: parent
		anchors.margins: 10
		radius: 4
		Column {
			anchors.fill: parent
			spacing: 5
			Rectangle
			{
				height: 20 * 3
				width: parent.width - 30
				anchors.horizontalCenter: parent.horizontalCenter
				color: "transparent"

				ColumnLayout
				{
					height: parent.height
					width: parent.width
					anchors.top: parent.top
					anchors.topMargin: 2
					Row
					{
						Layout.preferredWidth: parent.width
						spacing: 5
						Label {
							id: fromLabel
							text: qsTr("From:")
							visible: from.text != ""
							color: selectedBlockForeground
							font.italic: true
						}
						Label {
							id: from
							color: selectedBlockForeground
							maximumLineCount: 1
							clip: true
							width: parent.width - 50
							elide: Text.ElideRight
						}
					}

					Row
					{
						Layout.preferredWidth: parent.width
						spacing: 5
						Label {
							id: toLabel
							text: qsTr("To:")
							visible: to.text != ""
							color: selectedBlockForeground
							font.italic: true
						}
						Label {
							id: to
							color: selectedBlockForeground
							maximumLineCount: 1
							clip: true
							width: parent.width - 50
							elide: Text.ElideRight
						}
					}

					Row
					{
						Layout.preferredWidth: parent.width
						spacing: 5
						Label {
							id: valueLabel
							text: qsTr("Value:")
							visible: value.text != ""
							color: selectedBlockForeground
							font.italic: true
						}
						Label {
							id: value
							color: selectedBlockForeground
							font.italic: true
							clip: true
							width: 350
						}
					}
				}

				Button {
					anchors.right: parent.right
					anchors.top: parent.top
					anchors.topMargin: 20
					iconSource: "qrc:/qml/img/edit_combox.png"
					height: 25
					visible: from.text !== ""
					MouseArea
					{
						anchors.fill: parent
						onClicked:
						{
							bc.blockChainRepeater.editTx(blockIndex, txIndex)
						}
					}
				}
			}

			Rectangle {
				height: 1
				width: parent.width - 30
				anchors.horizontalCenter: parent.horizontalCenter
				border.color: "#cccccc"
				border.width: 1
			}

			KeyValuePanel
			{
				height: 100
				width: parent.width - 30
				anchors.horizontalCenter: parent.horizontalCenter
				id: inputParams
				title: qsTr("INPUT PARAMETERS")
				role: "parameters"
				_data: tx
			}

			KeyValuePanel
			{
				height: 100
				width: parent.width - 30
				anchors.horizontalCenter: parent.horizontalCenter
				id: returnParams
				title: qsTr("RETURN PARAMETERS")
				role: "returnParameters"
				_data: tx
			}

			KeyValuePanel
			{
				height: 100
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
			}

			KeyValuePanel
			{
				height: 100
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
			}
		}
	}
}
