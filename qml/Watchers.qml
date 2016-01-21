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

Column {
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

	Component.onCompleted:
	{
		clear()
	}

	function clear()
	{
		accounts.clear()
		rowLabelContractAccount.visible = false
		searchBox.visible = false
		accounts.visible = false
		storages.clear()
	}

	function addAccount(address, amount)
	{
		accounts.add(address, amount)
	}

	function updateWidthTx(_tx, _state, _blockIndex, _txIndex, _callIndex)
	{
		rowLabelContractAccount.visible = true
		searchBox.visible = true
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
			var startingParams = projectModel.stateListModel.getState(mainContent.rightPane.bc.scenarioIndex)
			var miner = startingParams.miner
			if (currentState)
				for (var k in currentState.accounts)
				{
					var label = blockChain.addAccountNickname(k, false)
					var value = currentState.accounts[k]
					if (k === "0x" + miner.address)
						value = value + " " + qsTr("(is mining)")
					accounts.add(label, value)
				}
		}
	}

	RowLayout
	{
		width: parent.width
		id: rowLabelContractAccount
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
		width: parent.width
		Image {
			sourceSize.width: 20
			sourceSize.height: 20
			source: "qrc:/qml/img/searchicon.png"
			fillMode: Image.PreserveAspectFit
		}
		DefaultTextField
		{
			Layout.fillWidth: true
			property string defaultLabel: qsTr("Filter by Contract Name or Addresses")
			text: defaultLabel
			font.italic: true
			onFocusChanged:
			{
				if (focus && text === defaultLabel)
					text = ""
				else if (!focus && text.trim() == "")
					text = defaultLabel
			}
			onTextChanged: {
				if (text === defaultLabel)
					return
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
			prettyJSON: true
			Component.onCompleted:
			{
				init()
			}

			function computeData()
			{
				title = storages.get(index).key
				ctrsStorage.clear()
				for (var k in storages.get(index).value)
					ctrsStorage.add(k, JSON.stringify(storages.get(index).value[k]))
				ctrsStorage.updateToJSON()
			}
		}
	}
}


