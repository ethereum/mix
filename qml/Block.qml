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
	property int trHeight: 35
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
		if (transactions)
		{
			var h = trHeight
			h += trHeight * transactions.count
			if (blockChainRepeater.callsDisplayed)
				for (var k = 0; k < transactions.count; k++)
				{
					var calls = blockChainPanel.calls[JSON.stringify([blockIndex, k])]
					if (calls)
						h += trHeight * calls.length
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

	onOpenedTrChanged:
	{
		Layout.preferredHeight = calculateHeight()
		height = calculateHeight()
	}

	DebuggerPaneStyle {
		id: dbgStyle
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
			Label {
				anchors.verticalCenter: parent.verticalCenter
				anchors.left: parent.left
				anchors.leftMargin: horizontalMargin
				font.pointSize: dbgStyle.absoluteSize(1)
				color: "#adadad"
				text:
				{
					if (number === -2)
						return qsTr("STARTING PARAMETERS")
					else if (status === "mined")
						return qsTr("BLOCK") + " " + number
					else
						return qsTr("PENDING TRANSACTIONS")
				}
			}

			Button {
				iconSource: "qrc:/qml/img/edit_combox.png"
				anchors.verticalCenter: parent.verticalCenter
				anchors.right: parent.right
				anchors.rightMargin: 14
				visible: number === -2
				height: 25
				MouseArea
				{
					anchors.fill: parent
					onClicked:
					{
						// load edit block panel
						projectModel.stateListModel.editState(scenarioIndex)
					}
				}
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

