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
	id: blockChainPanel
	property alias trDialog: transactionDialog
	property alias blockChainRepeater: blockChainRepeater
	property var calls: ({})
	property variant model
	property int scenarioIndex
	property var states: ({})
	spacing: 0
	property int previousWidth
	property variant debugTrRequested: []
	signal chainChanged(var blockIndex, var txIndex, var item)
	signal chainReloaded
	signal txSelected(var blockIndex, var txIndex, var callIndex)
	signal rebuilding
	signal accountAdded(string address, string amount)
	signal changeSelection(var current, var next, var direction)
	property bool firstLoad: true

	Keys.onUpPressed:
	{
		var prev = blockModel.getPrevItem(blockChainRepeater.blockSelected, blockChainRepeater.txSelected)
		blockChainRepeater.select(prev[0], prev[1], prev.length > 2 ? prev[2] : -1)
	}

	Keys.onDownPressed:
	{
		var next = blockModel.getNextItem(blockChainRepeater.blockSelected, blockChainRepeater.txSelected)
		blockChainRepeater.select(next[0], next[1], next.length > 2 ? next[2] : -1)
	}

	function build()
	{
		rebuild.build()
	}

	Connections
	{
		target: projectModel.stateListModel
		onAccountsValidated:
		{
			if (rebuild.accountsSha3 !== codeModel.sha3(JSON.stringify(_accounts)))
				rebuild.needRebuild("AccountsChanged")
			else
				rebuild.notNeedRebuild("AccountsChanged")
		}
		onContractsValidated:
		{
			if (rebuild.contractsSha3 !== codeModel.sha3(JSON.stringify(_contracts)))
				rebuild.needRebuild("ContractsChanged")
			else
				rebuild.notNeedRebuild("ContractsChanged")
		}
	}

	Connections
	{
		target: codeModel
		onContractRenamed: {
			if (firstLoad)
				return
			rebuild.needRebuild("ContractRenamed")
		}
		onNewContractCompiled: {
			if (firstLoad)
				return
			rebuild.needRebuild("NewContractCompiled")
		}
		onCompilationComplete: {
			if (firstLoad)
			{
				if (runOnProjectLoad)
					blockChain.build()
			}
			else
			{
				for (var c in rebuild.contractsHex)
				{
					if (codeModel.contracts[c] === undefined || codeModel.contracts[c].codeHex !== rebuild.contractsHex[c])
					{
						if (!rebuild.containsRebuildCause("CodeChanged"))
							rebuild.needRebuild("CodeChanged")
						return
					}
				}
				rebuild.notNeedRebuild("CodeChanged")
			}
		}
	}


	onChainChanged: {
		if (rebuild.txSha3[blockIndex][txIndex] !== codeModel.sha3(JSON.stringify(model.blocks[blockIndex].transactions[txIndex])))
		{
			rebuild.txChanged.push(rebuild.txSha3[blockIndex][txIndex])
			rebuild.needRebuild("txChanged")
		}
		else {
			for (var k in rebuild.txChanged)
			{
				if (rebuild.txChanged[k] === rebuild.txSha3[blockIndex][txIndex])
				{
					rebuild.txChanged.splice(k, 1)
					break
				}
			}
			if (rebuild.txChanged.length === 0)
				rebuild.notNeedRebuild("txChanged")
		}
	}

	onWidthChanged:
	{
		var minWidth = scenarioMinWidth - 20 // margin
		if (width <= minWidth || previousWidth <= minWidth)
		{
			fromWidth = 250
			toWidth = 240
		}
		else
		{
			var diff = (width - previousWidth) / 3;
			fromWidth = fromWidth + diff < 250 ? 250 : fromWidth + diff
			toWidth = toWidth + diff < 240 ? 240 : toWidth + diff
		}
		previousWidth = width
	}

	function getAccountNickname(address)
	{
		for (var k = 0; k < model.accounts.length; ++k)
		{
			var addr = model.accounts[k].address.indexOf("0x") === 0 ? model.accounts[k].address : "0x" + model.accounts[k].address
			if (addr === address)
				return model.accounts[k].name
		}
		return address
	}

	function addContractAddress(token, label, truncate)
	{
		var addr = getContractAddress(token)
		if (addr === token)
			return label
		else
		{
			addr = truncate ? addr.substring(0, 10) + "..." : addr
			return addr + " (" + label.replace(token, TransactionHelper.contractFromToken(label)) + ")"
		}
	}

	function getContractAddress(token)
	{
		for (var k in clientModel.contractAddresses)
		{
			if (k === token)
				return clientModel.contractAddresses[k]
		}
		return token
	}

	function addAccountNickname(address, truncate)
	{
		var name = getAccountNickname(address)
		if (address !== name)
		{
			var addr = truncate ? address.substring(0, 10) + "..." : address
			return addr + " (" + name + ")"
		}
		else
			return address
	}

	function addContractName(address, truncate)
	{
		for (var k in clientModel.contractAddresses)
		{
			var addr = clientModel.contractAddresses[k].indexOf("0x") === 0 ? clientModel.contractAddresses[k] : "0x" + clientModel.contractAddresses[k]
			if (address === addr)
			{
				var name = TransactionHelper.contractFromToken(k)
				if (name !== k)
				{
					addr = truncate ? addr.substring(0, 10) + "..." : addr
					return addr + " (" + name  + ")"
				}
			}
		}
		return address
	}

	function formatRecipientLabel(_tx)
	{
		if (!_tx.isFunctionCall)
		{
			if (_tx.contractId.indexOf("0x") === 0)
				return addAccountNickname(_tx.contractId, true)
			else
				return addContractAddress(_tx.contractId, _tx.contractId, true)
		}
		else if (_tx.isContractCreation)
			return _tx.label
		else
			return addContractAddress(_tx.contractId, _tx.label, true)
	}

	function getState(record)
	{
		return states[record]
	}

	function load(scenario, index)
	{
		if (!scenario)
			return;
		if (model && firstLoad)
			rebuild.startBlinking()
		model = scenario
		scenarioIndex = index
		genesis.scenarioIndex = index
		states = []
		blockModel.clear()
		for (var b in model.blocks)
			blockModel.append(model.blocks[b])
		previousWidth = width
		blockChainRepeater.hideCalls()
		toggleCallsBtn.text = toggleCallsBtn.getText()		
	}

	property int statusWidth: 30
	property int fromWidth: 250
	property int toWidth: 240
	property int debugActionWidth: 40
	property int horizontalMargin: 10
	property int cellSpacing: 10

	RowLayout
	{
		Layout.preferredHeight: 10
	}

	Rectangle
	{
		MouseArea
		{
			anchors.fill: parent
			onClicked:
			{
				blockChainPanel.forceActiveFocus()
			}
		}
		Layout.preferredHeight: 500
		Layout.preferredWidth: parent.width
		border.color: "#cccccc"
		border.width: 2
		color: "white"
		ScrollView
		{
			id: blockChainScrollView
			anchors.fill: parent
			anchors.topMargin: 8
			ColumnLayout
			{
				id: blockChainLayout
				width: parent.width
				spacing: 20


				Rectangle
				{
					Layout.preferredHeight: 80
					Layout.preferredWidth: blockChainScrollView.width
					color: "transparent"

					Button
					{
						anchors.left: parent.left
						anchors.leftMargin: statusWidth
						id: toggleCallsBtn
						text: getText()
						Layout.preferredHeight: 40

						function getText()
						{
							if (blockChainRepeater.callsDisplayed)
								return qsTr("transactions only")
							else
								return qsTr("transactions + calls")
						}

						onClicked:
						{
							toggleCalls()
						}

						function toggleCalls()
						{
							if (blockChainRepeater.callsDisplayed)
								blockChainRepeater.hideCalls()
							else
								blockChainRepeater.displayCalls()
							text = getText()
						}
					}

					Block
					{
						id: genesis
						anchors.top: toggleCallsBtn.bottom
						scenario: blockChainPanel.model
						scenarioIndex: scenarioIndex
						Layout.preferredWidth: blockChainScrollView.width
						Layout.preferredHeight: 60
						width: blockChainScrollView.width
						height: 60
						blockIndex: -1
						transactions: []
						status: ""
						number: -2
						trHeight: 60
					}
				}

				Connections
				{
					target: projectModel.stateDialog
					onAccepted:
					{
						blockChainPanel.forceActiveFocus()
					}
					onClosed:
					{
						blockChainPanel.forceActiveFocus()
					}
				}

				Repeater // List of blocks
				{
					id: blockChainRepeater
					model: blockModel
					property bool callsDisplayed
					property int blockSelected
					property int txSelected
					property int callSelected: 0

					function editTx(blockIndex, txIndex)
					{
						itemAt(blockIndex).editTx(txIndex)
					}

					function select(blockIndex, txIndex, callIndex)
					{
						blockSelected = blockIndex
						txSelected = txIndex
						callSelected = callIndex
						if (itemAt(blockIndex))
							itemAt(blockIndex).select(txIndex, callIndex)
						blockChainPanel.forceActiveFocus()
					}

					function displayCalls()
					{
						for (var k in blockChainPanel.calls)
						{
							var ref = JSON.parse(k)
							itemAt(ref[0]).displayNextCalls(ref[1], blockChainPanel.calls[k])
						}
						callsDisplayed = true
					}

					function hideCalls()
					{
						for (var k = 0; k < blockChainRepeater.count; k++)
							blockChainRepeater.itemAt(k).hideNextCalls()
						callsDisplayed = false
					}

					Block
					{
						Connections
						{
							target: block
							onTxSelected:
							{
								blockChainRepeater.blockSelected = blockIndex
								blockChainRepeater.txSelected = txIndex
								blockChainRepeater.callSelected = callIndex
								blockChainPanel.txSelected(index, txIndex, callIndex)
							}
						}

						Connections
						{
							target: blockChainRepeater
							onCallsDisplayedChanged:
							{
								block.Layout.preferredHeight = block.calculateHeight()
							}
						}

						id: block
						scenario: blockChainPanel.model
						Layout.preferredWidth: blockChainScrollView.width
						Layout.preferredHeight:
						{
							return calculateHeight()
						}
						blockIndex: index
						transactions:
						{
							if (index >= 0)
								return blockModel.get(index).transactions
							else
								return []
						}
						transactionModel:
						{
							if (index >= 0)
								return scenario.blocks[index].transactions
							else
								return []
						}

						status:
						{
							if (index >= 0)
								return blockModel.get(index).status
							else
								return ""
						}

						number:
						{
							if (index >= 0)
								return blockModel.get(index).number
							else
								return 0
						}
					}
				}
			}
		}
	}

	ListModel
	{
		id: blockModel

		function appendBlock(block)
		{
			blockModel.append(block);
		}

		function appendTransaction(tr)
		{
			blockModel.get(blockModel.count - 1).transactions.append(tr)
		}

		function removeTransaction(blockIndex, trIndex)
		{
			blockModel.get(blockIndex).transactions.remove(trIndex)
		}

		function removeLastBlock()
		{
			blockModel.remove(blockModel.count - 1)
		}

		function removeBlock(index)
		{
			blockModel.remove(index)
		}

		function getTransaction(block, tr)
		{
			return blockModel.get(block).transactions.get(tr)
		}

		function setTransaction(blockIndex, trIndex, tr)
		{
			blockModel.get(blockIndex).transactions.set(trIndex, tr)
		}

		function setTransactionProperty(blockIndex, trIndex, propertyName, value)
		{
			blockModel.get(blockIndex).transactions.set(trIndex, { propertyName: value })
		}

		function getNextItem(blockIndex, txIndex)
		{
			var next = [blockIndex, txIndex]
			if (!blockChainRepeater.callsDisplayed)
			{
				next = getNextTx(blockIndex, txIndex)
				next.push(-1)
			}
			else
			{
				if (isLastCall())
				{
					next = getNextTx(blockIndex, txIndex)
					next.push(-1)
				}
				else
					next.push(blockChainRepeater.callSelected + 1)
			}
			return next
		}

		function getPrevItem(blockIndex, txIndex)
		{
			var prev = [blockIndex, txIndex]
			if (!blockChainRepeater.callsDisplayed)
			{
				prev = getPrevTx(blockIndex, txIndex)
				prev.push(-1)
			}
			else
			{
				if (blockChainRepeater.callSelected === -1)
				{
					prev = getPrevTx(blockIndex, txIndex)
					var current = blockChainPanel.calls[JSON.stringify(prev)]
					if (current)
						prev.push(current.length - 1)
				}
				else
					prev.push(blockChainRepeater.callSelected - 1)
			}
			console.log(JSON.stringify(prev))
			return prev
		}

		function getNextTx(blockIndex, txIndex)
		{
			var next = []
			var nextTx = txIndex
			var nextBlock = blockIndex
			var txCount = blockModel.get(blockIndex).transactions.count;
			if (txCount - 1 > txIndex)
				nextTx = txIndex + 1
			else if (blockModel.count - 1 > blockIndex)
			{
				nextTx = 0;
				nextBlock = blockIndex + 1
			}
			else
				nextTx = 0
			next.push(nextBlock)
			next.push(nextTx)
			return next
		}

		function getPrevTx(blockIndex, txIndex)
		{
			var prev = []
			var prevTx = txIndex
			var prevBlock = blockIndex
			if (txIndex === 0 && blockIndex !== 0)
			{
				prevBlock = blockIndex - 1
				prevTx = blockModel.get(prevBlock).transactions.count - 1
			}
			else if (txIndex > 0)
				prevTx = txIndex - 1
			prev.push(prevBlock)
			prev.push(prevTx)
			return prev;
		}

		function isFirstCall()
		{
			var call = blockChainRepeater.callSelected
			return (call === 0)
		}

		function isLastCall()
		{
			var i = [blockChainRepeater.blockSelected, blockChainRepeater.txSelected]
			var current = blockChainPanel.calls[JSON.stringify(i)]
			if (current)
			{
				var callnb = current.length
				var call = blockChainRepeater.callSelected
				return call === callnb - 1
			}
			else
				return true
		}
	}

	Rectangle
	{
		Layout.preferredWidth: parent.width
		Layout.preferredHeight: 70
		color: "transparent"
		RowLayout
		{
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: parent.top
			anchors.topMargin: 10
			spacing: 20

			Connections
			{
				target: clientModel
				onSetupFinished:
				{
					if (!firstLoad)
						reloadFrontend.startBlinking()
					else
						reloadFrontend.reload()
					if (rebuild.isBlinking)
						reloadFrontend.setBlinking(rebuild.index, rebuild.direction, rebuild.color)
					firstLoad = false
				}
			}

			Rectangle {
				Layout.preferredWidth: 100
				Layout.preferredHeight: 30
				ScenarioButton {
					id: rebuild
					text: qsTr("Rebuild Scenario")
					width: 100
					height: 30
					roundLeft: true
					roundRight: true
					property variant contractsHex: ({})
					property variant txSha3: ({})
					property variant accountsSha3
					property variant contractsSha3
					property variant txChanged: []
					property var blinkReasons: []

					function needRebuild(reason)
					{
						rebuild.startBlinking()
						if (reloadFrontend.isBlinking)
							rebuild.setBlinking(reloadFrontend.index, reloadFrontend.direction, reloadFrontend.color)
						blinkReasons.push(reason)
					}

					function containsRebuildCause(reason)
					{
						for (var c in blinkReasons)
						{
							if (blinkReasons[c] === reason)
								return true
						}
						return false
					}


					function notNeedRebuild(reason)
					{
						for (var c in blinkReasons)
						{
							if (blinkReasons[c] === reason)
							{
								blinkReasons.splice(c, 1)
								break
							}
						}
						if (blinkReasons.length === 0)
							rebuild.stopBlinking()
					}

					function build()
					{
						if (ensureNotFuturetime.running)
							return
						blockChainPanel.calls = {}
						stopBlinking()
						rebuilding()
						states = []
						var retBlocks = [];
						var bAdded = 0;
						for (var j = 0; j < model.blocks.length; j++)
						{
							var b = model.blocks[j];
							var block = {
								hash: b.hash,
								number: b.number,
								transactions: [],
								status: b.status
							}
							for (var k = 0; k < model.blocks[j].transactions.length; k++)
							{
								if (blockModel.get(j).transactions.get(k).saveStatus)
								{
									var tr = model.blocks[j].transactions[k]
									tr.saveStatus = true
									block.transactions.push(tr);
								}

							}
							if (block.transactions.length > 0)
							{
								bAdded++
								block.number = bAdded
								block.status = "mined"
								retBlocks.push(block)
							}
						}
						if (retBlocks.length === 0)
							retBlocks.push(projectModel.stateListModel.createEmptyBlock())
						else
						{
							var last = retBlocks[retBlocks.length - 1]
							last.number = -1
							last.status = "pending"
						}

						model.blocks = retBlocks
						blockModel.clear()
						for (var j = 0; j < model.blocks.length; j++)
							blockModel.append(model.blocks[j])

						ensureNotFuturetime.start()

						takeCodeSnapshot()
						takeTxSnaphot()
						takeAccountsSnapshot()
						takeContractsSnapShot()
						blinkReasons = []
						clientModel.setupScenario(model);
						blockChainPanel.forceActiveFocus()
					}

					onClicked:
					{
						build()
					}

					function takeContractsSnapShot()
					{
						contractsSha3 = codeModel.sha3(JSON.stringify(model.contracts))
					}

					function takeAccountsSnapshot()
					{
						accountsSha3 = codeModel.sha3(JSON.stringify(model.accounts))
					}

					function takeCodeSnapshot()
					{
						contractsHex = {}
						for (var c in codeModel.contracts)
							contractsHex[c] = codeModel.contracts[c].codeHex
					}

					function takeTxSnaphot()
					{
						txSha3 = {}
						txChanged = []
						for (var j = 0; j < model.blocks.length; j++)
						{
							for (var k = 0; k < model.blocks[j].transactions.length; k++)
							{
								if (txSha3[j] === undefined)
									txSha3[j] = {}
								txSha3[j][k] = codeModel.sha3(JSON.stringify(model.blocks[j].transactions[k]))
							}
						}
					}

					buttonShortcut: ""
					sourceImg: "qrc:/qml/img/recycleicon@2x.png"
				}
			}

			Rectangle {
				Layout.preferredWidth: 100
				Layout.preferredHeight: 30
				ScenarioButton {
					id: reloadFrontend
					text: qsTr("Reload Frontend")
					width: 100
					height: 30
					roundLeft: true
					roundRight: true
					onClicked:
					{
						reload()
					}
					buttonShortcut: ""
					sourceImg: "qrc:/qml/img/recycleicon@2xGrey.png"
					function reload()
					{
						mainContent.webView.reload()
						reloadFrontend.stopBlinking()
					}
				}
			}

			Rectangle
			{
				Layout.preferredWidth: 200
				Layout.preferredHeight: 30
				color: "transparent"

				ScenarioButton {
					id: addTransaction
					text: qsTr("Add Tx...")
					onClicked:
					{
						if (model && model.blocks)
						{
							var lastBlock = model.blocks[model.blocks.length - 1];
							if (lastBlock.status === "mined")
							{
								var newblock = projectModel.stateListModel.createEmptyBlock()
								blockModel.appendBlock(newblock)
								model.blocks.push(newblock);
							}

							var item = TransactionHelper.defaultTransaction()
							transactionDialog.execute = !rebuild.isBlinking
							transactionDialog.stateAccounts = model.accounts
							transactionDialog.editMode = false
							transactionDialog.open(model.blocks[model.blocks.length - 1].transactions.length, model.blocks.length - 1, item)
						}
					}
					width: 100
					height: 30
					buttonShortcut: ""
					sourceImg: "qrc:/qml/img/sendtransactionicon@2x.png"
					roundLeft: true
					roundRight: false
				}

				Timer
				{
					id: ensureNotFuturetime
					interval: 1000
					repeat: false
					running: false
				}

				Rectangle
				{
					width: 1
					height: parent.height
					anchors.right: addBlockBtn.left
					color: "#ededed"
				}

				ScenarioButton {
					id: addBlockBtn
					text: qsTr("Add Block")
					anchors.left: addTransaction.right
					roundLeft: false
					roundRight: true
					onClicked:
					{
						if (ensureNotFuturetime.running)
							return
						if (clientModel.mining || clientModel.running)
							return
						if (model.blocks.length > 0)
						{
							var lastBlock = model.blocks[model.blocks.length - 1]
							if (lastBlock.status === "pending")
							{
								ensureNotFuturetime.start()
								clientModel.mine()
							}
							else
								addNewBlock()
						}
						else
							addNewBlock()
					}

					function addNewBlock()
					{
						var block = projectModel.stateListModel.createEmptyBlock()
						model.blocks.push(block)
						blockModel.appendBlock(block)
					}
					width: 100
					height: 30

					buttonShortcut: ""
					sourceImg: "qrc:/qml/img/newblock@2x.png"
				}
			}


			Connections
			{
				id: clientListenner
				target: clientModel
				onNewBlock:
				{
					if (!clientModel.running)
					{
						var lastBlock = model.blocks[model.blocks.length - 1]
						lastBlock.status = "mined"
						lastBlock.number = model.blocks.length
						var lastB = blockModel.get(model.blocks.length - 1)
						lastB.status = "mined"
						lastB.number = model.blocks.length
						addBlockBtn.addNewBlock()
					}
				}
				onStateCleared:
				{
				}
				onNewRecord:
				{
					if (_r.transactionIndex !== "Call")
					{
						var blockIndex =  parseInt(_r.transactionIndex.split(":")[0]) - 1
						var trIndex = parseInt(_r.transactionIndex.split(":")[1])
						if (blockIndex <= model.blocks.length - 1)
						{
							var item = model.blocks[blockIndex]
							if (trIndex <= item.transactions.length - 1)
							{
								var tr = item.transactions[trIndex]
								tr.returned = _r.returned
								tr.recordIndex = _r.recordIndex
								tr.logs = _r.logs
								tr.isCall = false
								tr.sender = _r.sender
								tr.returnParameters = _r.returnParameters
								var trModel = blockModel.getTransaction(blockIndex, trIndex)
								trModel.returned = _r.returned
								trModel.recordIndex = _r.recordIndex
								trModel.logs = _r.logs
								trModel.sender = _r.sender
								trModel.returnParameters = _r.returnParameters
								blockModel.setTransaction(blockIndex, trIndex, trModel)
								blockChainRepeater.select(blockIndex, trIndex, -1)
								return;
							}
						}
						// tr is not in the list.
						var itemTr = fillTx(_r, false)
						model.blocks[model.blocks.length - 1].transactions.push(itemTr)
						blockModel.appendTransaction(itemTr)
						blockChainRepeater.select(blockIndex, trIndex, -1)
					}
					else
					{
						var blockIndex =  parseInt(clientModel.lastTransaction.transactionIndex.split(":")[0]) - 1
						var trIndex = parseInt(clientModel.lastTransaction.transactionIndex.split(":")[1])
						var i = [blockIndex, trIndex]
						if (!blockChainPanel.calls[JSON.stringify(i)])
							blockChainPanel.calls[JSON.stringify(i)] = []
						var itemTr = fillTx(_r, true)
						blockChainPanel.calls[JSON.stringify(i)].push(itemTr)
						if (blockChainRepeater.callsDisplayed)
						{
							blockChainRepeater.hideCalls()
							blockChainRepeater.displayCalls()
						}
					}
				}

				function fillTx(_r, _isCall)
				{
					// tr is not in the list.
					var itemTr = TransactionHelper.defaultTransaction()
					itemTr.saveStatus = _r.source === 0 ? false : true //? 0 coming from Web3, 1 coming from MixGui
					itemTr.functionId = _r.function
					itemTr.contractId = _r.contract
					itemTr.isCall = _isCall
					itemTr.gasAuto = true
					itemTr.parameters = _r.parameters
					itemTr.isContractCreation = itemTr.functionId === itemTr.contractId
					itemTr.label = _r.label
					itemTr.isFunctionCall = itemTr.functionId !== "" && itemTr.functionId !== "<none>"
					itemTr.returned = _r.returned
					itemTr.value = QEtherHelper.createEther(_r.value, QEther.Wei)
					itemTr.sender = _r.sender
					itemTr.recordIndex = _r.recordIndex
					itemTr.logs = _r.logs
					itemTr.returnParameters = _r.returnParameters
					return itemTr
				}

				onNewState: {
					states[_record] = _accounts
				}

				onMiningComplete:
				{
				}
			}

			ScenarioButton {
				id: newAccount
				text: qsTr("New Account...")
				onClicked: {
					newAddressWin.accounts = model.accounts
					newAddressWin.open()
				}
				Layout.preferredWidth: 100
				Layout.preferredHeight: 30
				buttonShortcut: ""
				sourceImg: "qrc:/qml/img/newaccounticon@2x.png"
				roundLeft: true
				roundRight: true
			}

			NewAccount
			{
				id: newAddressWin
				onAccepted:
				{
					model.accounts.push(ac)
					clientModel.addAccount(ac.secret);
				}
			}
		}
	}

	TransactionDialog {
		id: transactionDialog
		property bool execute
		onAccepted: {
			var item = transactionDialog.getItem()
			if (execute)
			{
				var lastBlock = model.blocks[model.blocks.length - 1];
				if (lastBlock.status === "mined")
				{
					var newBlock = projectModel.stateListModel.createEmptyBlock();
					model.blocks.push(newBlock);
					blockModel.appendBlock(newBlock)
				}
				if (!clientModel.running)
					clientModel.executeTr(item)
			}
			else {
				model.blocks[blockIndex].transactions[transactionIndex] = item
				blockModel.setTransaction(blockIndex, transactionIndex, item)
				chainChanged(blockIndex, transactionIndex, item)
			}
			blockChainPanel.forceActiveFocus()
		}

		onClosed:
		{
			blockChainPanel.forceActiveFocus()
		}

	}
}

