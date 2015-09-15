import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "."


Rectangle {
	id: root
	color: "#ededed"
	property alias bc: blockChain

	function clear()
	{
		loader.clear()
		watchers.clear()
		blockChain.clear()
	}

	Connections
	{
		target:  projectModel
		onProjectLoaded: {
			if (projectModel.stateListModel.defaultStateIndex)
				loader.selectedScenarioIndex = projectModel.stateListModel.defaultStateIndex
			loader.init()
		}
	}

	onActiveFocusChanged:
	{
		blockChain.forceActiveFocus()
	}

	onWidthChanged:
	{
		loader.updateWidth(width)
	}

	ScrollView
	{
		anchors.fill: parent
		onWidthChanged: {
			columnExe.width = width - 40
		}

		ColumnLayout
		{
			id: columnExe
			Layout.preferredWidth: parent.width
			anchors.left: parent.left
			anchors.leftMargin: 15
			ColumnLayout
			{				
				id: scenarioColumn
				width: parent.width
				ScenarioLoader
				{
					Layout.preferredHeight: 75
					Layout.preferredWidth: parent.width
					width: parent.width
					id: loader
				}

				Connections
				{
					target: blockChain
					onChainChanged: loader.needSaveOrReload()
				}

				Rectangle
				{
					Layout.preferredWidth: parent.width
					height: 1
					color: "#cccccc"
				}

				Connections
				{
					target: loader
					onLoaded:
					{
						watchers.clear()
						blockChain.load(scenario, loader.selectedScenarioIndex)
						blockChain.forceActiveFocus()
					}
				}

				BlockChain
				{
					id: blockChain
					Layout.preferredWidth: parent.width
				}

				Connections
				{
					target: blockChain
					property var currentSelectedBlock
					property var currentSelectedTx
					onTxSelected:
					{
						currentSelectedBlock = blockIndex
						currentSelectedTx = txIndex
						updateWatchers(blockIndex, txIndex, callIndex)
					}

					function updateWatchers(blockIndex, txIndex, callIndex)
					{
						var tx;
						if (callIndex === -1)
							tx = blockChain.model.blocks[blockIndex].transactions[txIndex]
						else
						{
							var calls = blockChain.calls[JSON.stringify([blockIndex, txIndex])]
							tx = calls[callIndex]
						}
						var state = blockChain.getState(tx.recordIndex)
						watchers.updateWidthTx(tx, state, blockIndex, txIndex, callIndex)
					}

					onRebuilding: {
						watchers.clear()
					}

					onAccountAdded: {
						watchers.addAccount(address, "0 wei")
					}
				}
			}

			Watchers
			{
				id: watchers
				bc: blockChain
				Layout.fillWidth: true
				Layout.preferredHeight: 800
			}

			Rectangle
			{
				color: "transparent"
				Layout.preferredHeight: 50
				Layout.fillWidth: true
			}
		}
	}
}
