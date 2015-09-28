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
			height: 25
			width: 25
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
			blockChainPanel.forceActiveFocus()
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
				Text
				{
					id: hash
					width: parent.width - 30
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					maximumLineCount: 1
					clip: true
					color: labelColor
					font.pointSize: dbgStyle.absoluteSize(1)
					font.bold: true
					text: {
						if (tx)
							return bc.addAccountNickname(clientModel.resolveAddress(tx.sender), true)
						else
							return ""
					}
				}

				Image {
					anchors.left: hash.right
					anchors.leftMargin: 1
					source: "qrc:/qml/img/right.png"
					fillMode: Image.PreserveAspectFit
					anchors.verticalCenter: parent.verticalCenter
					width: 20
				}
			}

			Rectangle
			{
				Layout.preferredWidth: toWidth
				anchors.verticalCenter: parent.verticalCenter
				Text
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
					font.pointSize: dbgStyle.absoluteSize(1)
					font.bold: true
					clip: true
					maximumLineCount: 1
					width: parent.width - 50
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
			anchors.topMargin: 18
			anchors.left: rowTransactionItem.left
			width: blockWidth
			height: 90
			visible: false
			color: txColor

			function updateView()
			{
				if (tx && tx.parameters)
				{
					var keys = Object.keys(tx.parameters)
					for (var k in keys)
					{
						labelInput.visible = true
						inputList.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": tx.parameters[keys[k]] })
						txDetail.height += detailRowHeight
					}
				}

				if (tx && tx.returnParameters)
				{
					var keys = Object.keys(tx.returnParameters)
					for (var k in keys)
					{
						labelOutput.visible = true
						outputList.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": tx.returnParameters[keys[k]] })
						txDetail.height += detailRowHeight
					}
				}

				if (tx && tx.logs)
				{
					for (var k = 0; k < tx.logs.count; k++)
					{
						labelEvent.visible = true
						var param = ""
						for (var p = 0; p < tx.logs.get(k).param.count; p++)
							param += " " + tx.logs.get(k).param.get(p).value + " "
						param = "(" + param + ")"
						eventList.append({ "key": tx.logs.get(k).name, "value": param })
						txDetail.height += detailRowHeight
					}
					txDetail.height += labelEvent.parent.height
				}
			}

			Column
			{
				anchors.fill: parent
				anchors.margins: 10
				Row
				{
					Label
					{
						text: qsTr("From: ")
					}
					Label
					{
						text: tx ? tx.sender : ""
						width: rowTransactionItem.width - 30
						elide: Text.ElideRight
					}
				}

				Row
				{
					Label
					{
						text: qsTr("To: ")
					}
					Label
					{
						text: tx ? tx.contractId : ""
						width: rowTransactionItem.width - 30
						elide: Text.ElideRight
					}
				}

				Row
				{
					Label
					{
						text: qsTr("Value: ")
					}
					Label
					{
						text:  tx ? tx.value.format() : ""
						width: rowTransactionItem.width - 30
						elide: Text.ElideRight
					}
				}
				Row
				{
					Column
					{
						Label
						{
							id: labelInput
							text: qsTr("Input:")
							visible: false
						}

						ListModel
						{
							id: inputList
						}

						Repeater
						{
							model: inputList
							Component.onCompleted:
							{

							}

							Row
							{
								Label
								{
									text: key + " "
								}
								Label
								{
									text: value
									width: rowTransactionItem.width - 30
									elide: Text.ElideRight
								}
							}
						}
					}
				}

				Row
				{
					Column
					{
						Label
						{
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
							Component.onCompleted:
							{

							}

							Row
							{
								Label
								{
									text: key
								}
								Label
								{
									text: value
									width: rowTransactionItem.width - 30
									elide: Text.ElideRight
								}
							}
						}
					}
				}

				Row
				{
					Column
					{
						Label
						{
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
							Component.onCompleted:
							{

							}

							Row
							{
								Label
								{
									text: index >= 0 ? eventList.get(index).key : ""
								}

								Label
								{
									text: index >= 0 ? eventList.get(index).value : ""
									width: rowTransactionItem.width - 30
									elide: Text.ElideRight
								}
							}
						}
					}
				}

				Row
				{
					Button
					{
						id: editTx
						visible: !isCall
						onClicked:
						{
							if (!isCall)
								root.editTx(index)
						}
						text: qsTr("Edit Transaction...")
					}

					Button
					{
						id: debugTx
						onClicked:
						{
							if (tx.recordIndex !== undefined)
							{
								debugTrRequested = [ blockIndex, txIndex, callIndex ]
								clientModel.debugRecord(tx.recordIndex);
							}
						}
						text: isCall ? qsTr("Debug Call...") : qsTr("Debug Transaction...")
					}
				}
			}
		}
	}

	Rectangle
	{
		width: debugActionWidth
		height: trHeight - 10
		anchors.right: rowContentTr.right
		anchors.top: rowContentTr.top
		anchors.rightMargin: 10
		color: "transparent"

		Image {
			id: debugImg
			source: "qrc:/qml/img/rightarrowcircle.png"
			width: debugActionWidth
			fillMode: Image.PreserveAspectFit
			anchors.horizontalCenter: parent.horizontalCenter
			visible: tx !== null && tx !== undefined && tx.recordIndex !== undefined
		}
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


