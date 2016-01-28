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
/** @file Block.qml
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

ColumnLayout
{
	id: root
	property variant transactions
	property variant transactionModel
	property string status
	property int number
	property int blockWidth: Layout.preferredWidth - statusWidth - horizontalMargin
	property int horizontalMargin: 10
	property int trHeight: 30
	spacing: 1
	property int openedTr: 0
	property int blockIndex
	property variant scenario
	property string labelColor: "#414141"
	property string selectedTxColor: "#accbf2"
	property string selectedCallColor: "#d7"
	property string selectedBlockForeground: "#445e7f"
	property string txColor: "#DEDCDC"
	property string callColor: "#e6e5e5"
	property string halfOpacity: "#f3f2f2"

	property int scenarioIndex
	signal txSelected(var txIndex, var callIndex)

	function editTx(txIndex)
	{
		transactionDialog.stateAccounts = scenario.accounts
		transactionDialog.execute = false
		transactionDialog.editMode = true
		transactionDialog.open(txIndex, blockIndex, transactions.get(txIndex))
	}

	function select(txIndex, callIndex)
	{
		if (callIndex === -1)
			transactionRepeater.itemAt(txIndex).select()
		else
			transactionRepeater.itemAt(txIndex).selectCall(callIndex)
	}

	function displayNextCalls(trIndex, calls)
	{
		transactionRepeater.itemAt(trIndex).displayCalls(calls)
	}

	function hideNextCalls()
	{
		for (var k = 0; k < transactionRepeater.count; k++)
			transactionRepeater.itemAt(k).hideCalls()
	}

	Rectangle
	{
		id: top
		Layout.preferredWidth: blockWidth
		height: 10
		anchors.bottom: rowHeader.top
		color: status === "mined" ? txColor : halfOpacity
		radius: 15
		anchors.left: parent.left
		anchors.leftMargin: statusWidth
		anchors.bottomMargin: -9
	}

	RowLayout
	{
		Layout.preferredWidth: blockWidth
		id: rowHeader
		spacing: 0
		Layout.minimumHeight: trHeight
		anchors.left: parent.left
		anchors.leftMargin: statusWidth
		Rectangle
		{
			anchors.fill: parent
			color: status === "mined" ? txColor : halfOpacity
		}

		DefaultLabel {
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: parent.left
			anchors.leftMargin: horizontalMargin
			color: "#808080"
			text:
			{
				if (number === -2)
					return qsTr("GENESIS BLOCK")
				else if (status === "mined")
					return qsTr("BLOCK") + " " + number
				else
					return qsTr("PENDING TRANSACTIONS")
			}
		}

		DefaultButton {
			anchors.verticalCenter: parent.verticalCenter
			anchors.right: parent.right
			anchors.rightMargin: 10
			visible: number === -2
			enabled: scenarioIndex !== -1
			onClicked:
			{
				// load edit block panel
				projectModel.stateListModel.editState(scenarioIndex)
			}
			text: qsTr("Edit Starting Parameters")
		}
	}


	Repeater // List of transactions
	{
		id: transactionRepeater
		model: transactions
		ColumnLayout
		{
			spacing: 1
			property int selectedIndex: -1
			property int txIndex: index
			property bool selected: false
			id: columnTx
			function select()
			{
				tx.select()
			}

			function selectCall(index)
			{
				callsRepeater.itemAt(index).highlight()
			}

			Transaction
			{
				id: tx
				tx: transactions.get(index)
				txIndex: index
				callIndex: -1
				isCall: false

				Menu
				{
					id: contextMenu
					visible: false
					MenuItem {
						text: qsTr("Delete")
						onTriggered: {
							deleteConfirmation.open();
						}
					}
				}

				MouseArea
				{
					anchors.fill: parent
					acceptedButtons: Qt.RightButton
					onClicked:
					{
						contextMenu.popup()
					}
				}

				Menu {
					id: contextMenuContract
					MenuItem {
						text: qsTr("Delete")
						onTriggered: {
							deleteConfirmation.open();
						}
					}
				}

				MessageDialog
				{
					id: deleteConfirmation
					text: qsTr("Are you sure you want to delete this transaction?\n\nTo mark multiple transactions to delete on reload, click on 'Mark to delete' icon at the left")

					standardButtons: StandardIcon.Ok | StandardIcon.Cancel
					onAccepted:
					{
						deleteTransaction(blockIndex, txIndex)
						contextMenu.visible = false
					}
				}

				function select(direction)
				{
					highlight()
				}

				function deselect()
				{
					highlight()
				}
			}

			function displayCalls(calls)
			{
				for (var k in calls)
					callsModel.append(calls[k])
			}

			function hideCalls()
			{
				callsModel.clear()
			}

			ListModel
			{
				id: callsModel
			}

			Repeater
			{
				id: callsRepeater
				model: callsModel
				Transaction
				{
					tx: callsModel.get(index)
					txIndex: columnTx.txIndex
					callIndex: index
					isCall: true
				}
			}
		}
	}
}

