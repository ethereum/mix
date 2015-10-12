import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "."

RowLayout
{
	id: rowTransaction
	Layout.preferredHeight: trHeight
	spacing: 0
	property bool isCall

	property variant tx
	property int txIndex
	property int callIndex
	property alias detailVisible: txDetail.visible
	property int detailRowHeight: 25
	property string trDetailColor: "#adadad"

	Keys.onDeletePressed:
	{
		if (!isCall && blockChain)
		{
			blockChain.deleteTransaction(blockIndex, txIndex)
			blockChain.rebuildRequired()
		}
	}

	function highlight()
	{
		rowContentTr.select()
	}

	function unHightlight()
	{
		rowContentTr.deselect()
	}

	function detailHeight()
	{
		var detailH = 0
		if (tx)
		{
			if (txDetail.visible)
				detailH = txDetail.height
			else
				detailH = 0
		}
		Layout.preferredHeight = trHeight + detailH
		return detailH
	}

	Connections
	{
		target: blockChainPanel
		onTxExecuted:
		{
			if (_blockIndex == blockIndex && _txIndex == txIndex && _callIndex == callIndex)
				txDetail.updateView()
		}
	}

	Rectangle
	{
		id: trSaveStatus
		Layout.preferredWidth: statusWidth
		Layout.preferredHeight: parent.height
		color: "transparent"
		anchors.top: parent.top
		property bool saveStatus
		Image {
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.leftMargin: -4
			anchors.topMargin: 0
			id: saveStatusImage
			source: "qrc:/qml/img/recyclediscard@2x.png"
			width: statusWidth + 10
			fillMode: Image.PreserveAspectFit
			visible: !isCall
		}

		Image {
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.leftMargin: 3
			anchors.topMargin: 5
			source: "qrc:/qml/img/javascript_logo.png"
			height: 15
			width: 15
			fillMode: Image.PreserveAspectFit
			visible: isCall
		}


		Component.onCompleted:
		{
			if (tx && tx.saveStatus)
				saveStatus = tx.saveStatus
		}

		onSaveStatusChanged:
		{
			if (saveStatus)
				saveStatusImage.source = "qrc:/qml/img/recyclekeep@2x.png"
			else
				saveStatusImage.source = "qrc:/qml/img/recyclediscard@2x.png"

			if (index >= 0)
				tx.saveStatus = saveStatus
		}

		MouseArea {
			id: statusMouseArea
			anchors.fill: parent
			onClicked:
			{
				if (!isCall)
					parent.saveStatus = !parent.saveStatus
			}
		}
	}

	Rectangle
	{
		Layout.preferredWidth: blockWidth
		Layout.preferredHeight: trHeight
		height: trHeight
		color: rowContentTr.selected ? selectedTxColor : (status === "mined" ? (isCall ? callColor : txColor) : halfOpacity)
		id: rowContentTr
		anchors.top: parent.top

		property bool selected: false
		Connections
		{
			target: blockChainPanel
			onTxSelected: {
				if (root.blockIndex !== blockIndex || rowTransaction.txIndex !== txIndex || rowTransaction.callIndex !== callIndex)
					rowContentTr.deselect()
			}
		}

		function select()
		{
			rowContentTr.selected = true
			hash.color = selectedBlockForeground
			func.color = selectedBlockForeground
			if (isCall)
				txSelected(txIndex, callIndex)
			else
				txSelected(txIndex, -1)
			rowTransaction.forceActiveFocus()
		}

		function deselect()
		{
			rowContentTr.selected = false
			hash.color = labelColor
			func.color = labelColor
		}

		MouseArea
		{
			anchors.fill: parent
			onClicked: {
				if (!rowContentTr.selected)
					rowContentTr.select()
			}
			onDoubleClicked:
			{
				if (!isCall)
					root.editTx(index)
			}
		}

		RowLayout
		{
			id: rowTransactionItem
			Layout.fillWidth: true
			Layout.preferredHeight: trHeight - 10
			anchors.verticalCenter: parent.verticalCenter
			Rectangle
			{
				Layout.preferredWidth: fromWidth
				anchors.left: parent.left
				anchors.leftMargin: horizontalMargin
				anchors.verticalCenter: parent.verticalCenter
				DefaultText
				{
					id: hash
					width: parent.width - 30
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					maximumLineCount: 1
					clip: true
					color: labelColor
					font.bold: true
					text: {
						if (tx)
							return bc.addAccountNickname(clientModel.resolveAddress(tx.sender), true)
						else
							return ""
					}
				}

				DefaultLabel
				{
					anchors.left: hash.right
					anchors.leftMargin: 1
					text: "→"
					anchors.verticalCenter: parent.verticalCenter
					width: 20
				}
			}

			Rectangle
			{
				Layout.preferredWidth: toWidth
				anchors.verticalCenter: parent.verticalCenter
				DefaultText
				{
					id: func
					text: {
						if (tx)
							return bc.formatRecipientLabel(tx)
						else
							return ""
					}
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					color: labelColor
					font.bold: true
					clip: true
					maximumLineCount: 1
					width: parent.width - 58
				}
			}

			function userFrienldyToken(value)
			{
				if (value && value.indexOf("<") === 0)
				{
					if (value.split("> ")[1] === " - ")
						return value.split(" - ")[0].replace("<", "")
					else
						return value.split(" - ")[0].replace("<", "") + "." + value.split("> ")[1] + "()";
				}
				else
					return value
			}
		}

		Rectangle
		{
			id: txDetail
			anchors.top: rowTransactionItem.bottom
			anchors.topMargin: 10
			anchors.left: rowTransactionItem.left
			width: blockWidth
			height: 0
			visible: false
			color: txColor

			function updateView()
			{
				height = 3 * labelFrom.height + 25
				height += editTx.height
				var spacing = labelFrom.height
				if (tx && tx.parameters)
				{
					var keys = Object.keys(tx.parameters)
					txDetail.height += keys.length > 0 ? spacing : 0
					for (var k in keys)
					{
						labelInput.visible = true
						inputList.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": tx.parameters[keys[k]] })
						txDetail.height += spacing
					}
				}

				if (tx && tx.returnParameters)
				{
					var keys = Object.keys(tx.returnParameters)
					txDetail.height += keys.length > 0 ? spacing : 0
					for (var k in keys)
					{
						labelOutput.visible = true
						outputList.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": tx.returnParameters[keys[k]] })
						txDetail.height += spacing
					}
				}

				if (tx && tx.logs)
				{
					txDetail.height += tx.logs.count > 0 ? spacing : 0
					for (var k = 0; k < tx.logs.count; k++)
					{
						labelEvent.visible = true
						var param = ""
						for (var p = 0; p < tx.logs.get(k).param.count; p++)
							param += " " + tx.logs.get(k).param.get(p).value + " "
						param = "(" + param + ")"
						eventList.append({ "key": tx.logs.get(k).name, "value": param })
						txDetail.height += spacing
					}
				}
			}

			Column
			{
				anchors.fill: parent
				anchors.margins: 10
				Row
				{
					DefaultLabel
					{
						id: labelFrom
						text: qsTr("From: ")
						color: trDetailColor
					}
					DefaultLabel
					{
						text: {
							if (!tx)
								return ""
							else
							{
								var addr = clientModel.resolveAddress(tx.sender)
								return blockChain.addAccountNickname(addr, true)
							}
						}
						width: rowTransactionItem.width - 75
						elide: Text.ElideRight
						color: trDetailColor
						font.bold: true
					}
				}

				Row
				{
					DefaultLabel
					{
						text: qsTr("To: ")
						color: trDetailColor
					}
					DefaultLabel
					{
						text: blockChain.formatRecipientLabel(tx)
						width: rowTransactionItem.width - 75
						elide: Text.ElideRight
						color: trDetailColor
						font.bold: true
					}
				}

				Row
				{
					DefaultLabel
					{
						text: qsTr("Value: ")
						color: trDetailColor
					}
					DefaultLabel
					{
						text:  tx ? tx.value.format() : ""
						width: rowTransactionItem.width - 30
						elide: Text.ElideRight
						color: trDetailColor
						font.bold: true
					}
				}
				Row
				{
					Column
					{
						DefaultLabel
						{
							id: labelInput
							text: qsTr("Input:")
							visible: false
							color: trDetailColor
						}

						ListModel
						{
							id: inputList
						}

						Repeater
						{
							model: inputList
							Row
							{
								DefaultLabel
								{
									color: trDetailColor
									text: key + "\t" + value
									width: rowTransactionItem.width - 40
									elide: Text.ElideRight
									font.bold: true
								}
							}
						}
					}
				}

				Row
				{
					Column
					{
						DefaultLabel
						{
							color: trDetailColor
							id: labelOutput
							text: qsTr("Output:")
							visible: false
						}

						ListModel
						{
							id: outputList
						}

						Repeater
						{
							model: outputList

							Row
							{
								DefaultLabel
								{
									color: trDetailColor
									text: key + "\t" + value
									width: rowTransactionItem.width - 30
									elide: Text.ElideRight
									font.bold: true
								}
							}
						}
					}
				}

				Row
				{
					Column
					{
						DefaultLabel
						{
							color: trDetailColor
							id: labelEvent
							text: qsTr("Events:")
							visible: false
						}

						ListModel
						{
							id: eventList
						}

						Repeater
						{
							model: eventList
							Row
							{
								DefaultLabel
								{
									color: trDetailColor
									text: index >= 0 ? eventList.get(index).key : ""
									font.bold: true
								}

								DefaultLabel
								{
									color: trDetailColor
									text: index >= 0 ? eventList.get(index).value : ""
									width: rowTransactionItem.width - 30
									elide: Text.ElideRight
									font.bold: true
								}
							}
						}
					}
				}

				Row
				{
					height: 35
					spacing: 5
					width: parent.width
					layoutDirection: Qt.RightToLeft
					CopyButton
					{
						anchors.verticalCenter: parent.verticalCenter
						getContent: function() {
							return JSON.stringify(tx)
						}
						height: 22
						width: 25
					}
					DefaultButton
					{
						id: editTx
						anchors.verticalCenter: parent.verticalCenter
						visible: !isCall
						onClicked:
						{
							if (!isCall)
								root.editTx(index)
						}
						height: 22
						text: qsTr("Edit transaction...")
					}

					DefaultButton
					{
						id: debugTx
						anchors.verticalCenter: parent.verticalCenter
						onClicked:
						{
							if (tx.recordIndex !== undefined)
								clientModel.debugRecord(tx.recordIndex, tx.label);
						}
						height: 22
						text: isCall ? qsTr("Debug call...") : qsTr("Debug transaction...")
					}
				}
			}
		}
	}

	Rectangle
	{
		width: 15
		height: 15
		anchors.right: rowContentTr.right
		anchors.top: rowContentTr.top
		anchors.rightMargin: 10
		anchors.topMargin: 5
		color: "transparent"
		Image {
			id: debugImg
			source: txDetail.visible ? "qrc:/qml/img/contract-icon@2x.png" : "qrc:/qml/img/expand-icon@2x.png"
			width: parent.width
			fillMode: Image.PreserveAspectFit
			anchors.horizontalCenter: parent.horizontalCenter
			visible: tx !== null && tx !== undefined && tx.recordIndex !== undefined
			MouseArea
			{
				anchors.fill: parent
				onClicked:
				{
					txDetail.visible = !txDetail.visible
				}
			}
		}
	}
}


