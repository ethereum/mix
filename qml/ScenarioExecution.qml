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
/** @file ScenarioExecution.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

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
	property alias bcLoader: loader

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
			columnExe.width = width - 30
		}
		flickableItem.interactive: false
		id: scenarioScrollView

		ColumnLayout
		{
			id: columnExe
			Layout.preferredWidth: parent.width
			anchors.left: parent.left
			anchors.leftMargin: 14

			ColumnLayout
			{				
				id: scenarioColumn
				width: parent.width
				spacing: 8

				ScenarioButton
				{
					Image {
						anchors.left: parent.left
						source: loader.visible ? "qrc:/qml/img/down.png" : "qrc:/qml/img/right.png"
						fillMode: Image.PreserveAspectFit
						width: 10
						anchors.verticalCenter: parent.verticalCenter
					}

					width: 10
					Layout.minimumHeight: 10
					Layout.preferredHeight: 12

					roundRight: true
					roundLeft: true
					enabled: true
					anchors.top: parent.top
					anchors.topMargin: 5
					anchors.left: parent.left
					anchors.leftMargin: 5
					MouseArea
					{
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							loader.visible = !loader.visible
						}
					}
				}

				ScenarioLoader
				{
					Layout.minimumHeight: 40
					Layout.preferredWidth: parent.width
					width: parent.width
					visible: true
					id: loader
					anchors.left: parent.left
					anchors.leftMargin: 5
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
					anchors.left: parent.left
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
				Layout.preferredWidth: parent.width
				onUpdated:
				{
					var count = Object.keys(currentState.contractsStorage).length
					Layout.minimumHeight = (count + 1) * 110
				}
			}

			Rectangle
			{
				color: "transparent"
				Layout.minimumHeight: 50
				Layout.fillWidth: true
			}
		}
	}
}
