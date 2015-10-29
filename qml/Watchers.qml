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

ColumnLayout {
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
	signal updated()

	function clear()
	{
		accounts.clear()
		accounts.visible = false
		storages.clear()
	}

	function addAccount(address, amount)
	{
		accounts.add(address, amount)
	}

	function updateWidthTx(_tx, _state, _blockIndex, _txIndex, _callIndex)
	{
		accounts.visible = true
		tx = _tx
		blockIndex  = _blockIndex
		txIndex = _txIndex
		callIndex = _callIndex
		currentState = _state
		accounts.init()
		storages.clear()
		searchBox.visible = currentState && currentState.contractsStorage && Object.keys(currentState.contractsStorage).length > 0
		for (var k in currentState.contractsStorage)
			storages.append({ "key": k, "value": currentState.contractsStorage[k].values })
		for (var k = 0; k < storages.count; k++)
			stoRepeater.itemAt(k).init()
		updated()
	}

	ListModel
	{
		id: storages
	}

	KeyValuePanel
	{
		width: parent.width
		visible: false
		id: accounts
		title: qsTr("User Account")
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

	RowLayout
	{
		Layout.minimumHeight: 20
		Layout.fillWidth: true
		DefaultLabel
		{
			id: titleLabel
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			color: "#414141"
			text: qsTr("Contract Account")
		}
	}

	RowLayout
	{
		id: searchBox
		Image {
			sourceSize.width: 20
			sourceSize.height: 20
			source: "qrc:/qml/img/searchicon.png"
			fillMode: Image.PreserveAspectFit
		}
		DefaultTextField
		{
			Layout.fillWidth: true
			onTextChanged: {
				for (var k = 0; k < stoRepeater.count; k++)
				{
					var label = storages.get(k).key.split(" - ")
					stoRepeater.itemAt(k).visible = text.trim() === "" || label[0].toLowerCase().indexOf(text.toLowerCase()) !== -1 || label[1].toLowerCase().indexOf(text.toLowerCase()) !== -1
				}
			}
		}
	}

	Repeater
	{
		id: stoRepeater
		model: storages
		KeyValuePanel
		{
			width: root.width
			id: ctrsStorage
			function computeData()
			{
				title = storages.get(index).key
				ctrsStorage.model.clear()
				for (var k in storages.get(index).value)
					ctrsStorage.add(k, JSON.stringify(storages.get(index).value[k]))
			}
		}
	}
}


