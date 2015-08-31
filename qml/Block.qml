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


	property string selectedBlockColor: "#accbf2"
	property string selectedBlockForeground: "#445e7f"

	property int scenarioIndex
	signal txSelected(var txIndex)

	function calculateHeight()
	{
		if (transactions)
		{
			if (index >= 0)
				return trHeight + trHeight * transactions.count + openedTr
			else
				return trHeight
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

	function select(txIndex, direction)
	{
		transactionRepeater.itemAt(txIndex).changeSelection([blockIndex, txIndex], [blockIndex, txIndex], direction)
		//transactionRepeater.itemAt(txIndex).select(direction)
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
		color: "#DEDCDC"
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
			color: "#DEDCDC"
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
						return qsTr("GENESIS PARAMETERS")
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
			property bool selected: false
			id: columnTx

			function select()
			{
				tx.select()
			}

			function changeSelection(current, next, direction)
			{
				console.log("change " )
				if (current[0] === blockIndex && current[1] === index)
				{
					if (!selected)
					{
						selected = true
						if (direction === +1)
						{
							selectedIndex = -1
						}
						else
						{
							selectedIndex = callsModel.count - 1
						}

					}
					else
					{
						selectedIndex = selectedIndex + direction
					}

					if (selectedIndex === -1)
					{
						tx.select()
					}
					else if (selectedIndex > -1 && selectedIndex < callsModel.count)
					{
						callsRepeater.itemAt(selectedIndex).select()
						tx.de
					}
					else
					{
						//hightlight the next tr
						blockChainPanel.blockChainRepeater.select(next[0], next[1], direction);
						selected = false
					}
				}
				else
					selected = false
			}

			Connections
			{
				target: blockChainPanel
				onChangeSelection:
				{
					columnTx.changeSelection(current, next)
				}
			}

			Transaction
			{
				id: tx
				tx: transactions.get(index)
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
					isCall: true
				}
			}
		}
	}
}

