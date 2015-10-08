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
	property int trHeight: 25
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

	function calculateHeight()
	{
		if (transactions && transactions.count > 0)
		{
			var h = trHeight
			for (var k = 0; k < transactionRepeater.count; k++)
			{
				h += trHeight
				if (transactionRepeater.itemAt(k))
					h += transactionRepeater.itemAt(k).detailHeight()
			}
			if (blockChainRepeater.callsDisplayed)
				for (var k = 0; k < transactions.count; k++)
				{
					var calls = blockChainPanel.calls[JSON.stringify([blockIndex, k])]
					if (calls)
					{
						for (var k = 0; k < transactionRepeater.count; k++)
						{
							if (transactionRepeater.itemAt(k))
							{
								h += trHeight
								h += transactionRepeater.itemAt(k).callsDetailHeight()
							}
						}
					}
				}
			return h;
		}
		else
			return trHeight
	}

	function editTx(txIndex)
	{
		transactionDialog.stateAccounts = scenario.accounts
		transactionDialog.execute = false
		transactionDialog.editMode = true
		transactionDialog.open(txIndex, blockIndex,  transactions.get(txIndex))
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

	function setHeight()
	{
		Layout.preferredHeight = calculateHeight()
		height = calculateHeight()
	}

	onOpenedTrChanged:
	{
		setHeight()
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
		anchors.bottomMargin: -5
	}

	RowLayout
	{
		Layout.preferredHeight: trHeight
		Layout.preferredWidth: blockWidth
		id: rowHeader
		spacing: 0
		Rectangle
		{
			Layout.preferredWidth: blockWidth
			Layout.preferredHeight: trHeight
			color: status === "mined" ? txColor : halfOpacity
			anchors.left: parent.left
			anchors.leftMargin: statusWidth
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
				height: 18
				width: 150
				enabled: scenarioIndex !== -1
				onClicked:
				{
					// load edit block panel
					projectModel.stateListModel.editState(scenarioIndex)
				}
				text: qsTr("Edit Starting Parameters")
			}
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

			function detailHeight()
			{
				return tx.detailHeight()
			}

			Transaction
			{
				id: tx
				tx: transactions.get(index)
				txIndex: index
				callIndex: -1
				isCall: false

				function select(direction)
				{
					highlight()
				}

				function deselect()
				{
					highlight()
				}

				onDetailVisibleChanged:
				{
					root.setHeight()
				}
			}

			function displayCalls(calls)
			{
				for (var k in calls)
					callsModel.append(calls[k])
				root.Layout.preferredHeight = calculateHeight()
				root.height = calculateHeight()
			}

			function hideCalls()
			{
				callsModel.clear()
			}

			function callsDetailHeight()
			{
				var h = 0
				for (var k = 0; k < callsRepeater.count; k++)
				{
					if (callsRepeater.itemAt(k))
					{
						h += callsRepeater.itemAt(k).detailHeight()
					}
				}
				return h
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

					onDetailVisibleChanged:
					{
						root.setHeight()
					}
				}
			}
		}
	}
}

