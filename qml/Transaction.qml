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
/** @file Transaction.qml
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
import "js/ScientificNumber.js" as ScientificNumber
import "."

ColumnLayout
{
	id: rowTransaction
	Layout.minimumHeight: trHeight
	Layout.preferredWidth: blockWidth
	spacing: 1
	property bool isCall

	property variant tx
	property int txIndex
	property int callIndex
	property bool detailVisible: txDetail.visible
	property string trDetailColor: "#adadad"

	Keys.onDeletePressed:
	{
		if (!isCall && blockChain)
		{
			deleteConfirmation.open();
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

	Connections
	{
		target: blockChainPanel
		onTxExecuted:
		{
			if (_blockIndex == blockIndex && _txIndex == txIndex && _callIndex == callIndex)
				txDetail.updateView()
		}
	}	

	ColumnLayout
	{
		id: rowContentTr
		anchors.top: parent.top
		Layout.preferredWidth: parent.width
		Layout.preferredHeight: rowTr.height
		spacing: 0
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

		Rectangle
		{
			color: rowContentTr.selected ? selectedTxColor : (status === "mined" ? (isCall ? callColor : txColor) : halfOpacity)
			Layout.preferredWidth: blockWidth
			Layout.minimumHeight: trHeight
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.leftMargin: statusWidth
			id: rowTr
			Rectangle
			{
				id: trSaveStatus
				anchors.right: parent.left
				anchors.top: parent.top
				width: statusWidth
				height: rowTransactionItem.height < trHeight ? trHeight : rowTransactionItem.height
				color: "transparent"
				TooltipArea {
					text: qsTr("Mark to delete")
					anchors.fill: parent
				}
				property bool saveStatus
				Image {
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: -4
					id: saveStatusImage
					source: "qrc:/qml/img/recyclediscard@2x.png"
					width: statusWidth + 10
					fillMode: Image.PreserveAspectFit
					visible: !isCall
				}

				Image {
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: 3
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

			RowLayout
			{
				id: rowTransactionItem
				anchors.verticalCenter: parent.verticalCenter
				onHeightChanged: {
					parent.Layout.minimumHeight = height < trHeight ? trHeight : height
				}

				Component.onCompleted: {
					parent.Layout.minimumHeight = trHeight
				}
				width: parent.width
				DefaultText
				{
					id: hash
					Layout.preferredWidth: (parent.width / 2) - 80
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: horizontalMargin
					elide: Text.ElideRight
					width: parent.width - 80
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

				Rectangle
				{
					Layout.preferredWidth: 30
					DefaultLabel
					{
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.verticalCenter: parent.verticalCenter
						color: labelColor
						text:  {
							if (!tx || tx.exception === "None" || tx.exception === undefined)
							{
								color = labelColor
								return "→"

							}
							else
							{
								color = "red"
								font.italic = true
								return tx.exception
							}
						}
					}
				}

				DefaultText
				{
					anchors.verticalCenter: parent.verticalCenter
					Layout.preferredWidth: (parent.width / 2) - 85
					id: func
					text: {
						if (tx)
							return bc.formatRecipientLabel(tx)
						else
							return ""
					}
					elide: Text.ElideRight
					color: labelColor
					font.bold: true
					clip: true
					maximumLineCount: 1
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

			RowLayout
			{
				anchors.right: parent.right

				DefaultButton
				{
					width: 15
					height: 15
					id: debugTxButton
					anchors.verticalCenter: parent.verticalCenter
					Layout.preferredWidth: 30
					Layout.preferredHeight: 30
					TooltipArea {
						text: qsTr("Debug transaction")
						anchors.fill: parent
					}
					onClicked:
					{
						if (tx.recordIndex !== undefined)
							clientModel.debugRecord(tx.recordIndex, tx.label);
					}
					style: ButtonStyle
					{
						id: name
						label: Image { source: "qrc:/qml/img/bugiconactive.png" }
					}
				}
				Rectangle
				{
					width: 15
					height: 15
					color: "transparent"
					TooltipArea {
						text: qsTr("Expand transaction")
						anchors.fill: parent
					}
					Image {
						id: expandImg
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
								if (txDetail.visible)
									colDetail.updateContainerHeight()
								else
									txDetail.Layout.preferredHeight = 0
							}
						}
					}
				}
			}
		}
	}

	Rectangle
	{
		Layout.preferredWidth: blockWidth
		color: status === "mined" ? (isCall ? callColor : txColor) : halfOpacity
		visible: false
		id: txDetail
		anchors.left: parent.left
		anchors.leftMargin: statusWidth
		function ensureScientificNumber(value)
		{
			return ScientificNumber.shouldConvertToScientific(value) ? ScientificNumber.toScientificNumber(value) + " (" + value + ")" : value
		}

		function updateView()
		{
			inputList.clear()
			outputList.clear()
			eventList.clear()
			if (tx && tx.parameters)
			{
				var keys = Object.keys(tx.parameters)
				for (var k in keys)
					inputList.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": ensureScientificNumber(tx.parameters[keys[k]]) })
			}

			if (tx && tx.returnParameters)
			{
				var keys = Object.keys(tx.returnParameters)
				for (var k in keys)
					outputList.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": ensureScientificNumber(tx.returnParameters[keys[k]]) })
			}

			if (tx && tx.logs)
			{
				for (var k = 0; k < tx.logs.count; k++)
				{
					var param = ""
					for (var p = 0; p < tx.logs.get(k).param.count; p++)
						param += " " + tx.logs.get(k).param.get(p).value
					param = "(" + param + ")"
					eventList.append({ "key": tx.logs.get(k).name, "value": param })
				}
			}
		}

		ColumnLayout
		{
			anchors.top: parent.top
			id: colDetail
			onHeightChanged: {
				updateContainerHeight()
			}

			Component.onCompleted: {
				updateContainerHeight()
			}

			function updateContainerHeight()
			{
				if (txDetail.visible)
					parent.Layout.preferredHeight = height + 5
				else
					parent.Layout.preferredHeight = 0
			}

			spacing: 5
			RowLayout
			{
				anchors.left: parent.left
				anchors.leftMargin: 5
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

			RowLayout
			{
				id: toDetail
				anchors.left: parent.left
				anchors.leftMargin: 5
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

			RowLayout
			{
				id: valueDetail
				anchors.left: parent.left
				anchors.leftMargin: 5
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

			RowLayout
			{
				id: gasUsedDetail
				anchors.left: parent.left
				anchors.leftMargin: 5
				DefaultLabel
				{
					text: qsTr("Gas Used: ")
					color: trDetailColor
				}
				DefaultLabel
				{
					text:  tx ? tx.gas.value() : ""
					width: rowTransactionItem.width - 30
					elide: Text.ElideRight
					color: trDetailColor
					font.bold: true
				}
			}

			RowLayout
			{
				id: inputDetail
				anchors.left: parent.left
				anchors.leftMargin: 5
				Column
				{
					DefaultLabel
					{
						id: labelInput
						text: qsTr("Input:")
						color: trDetailColor
					}

					ListModel
					{
						id: inputList
					}

					Repeater
					{
						model: inputList
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

			RowLayout
			{
				id: outputDetail
				anchors.left: parent.left
				anchors.leftMargin: 5
				ColumnLayout
				{
					DefaultLabel
					{
						color: trDetailColor
						id: labelOutput
						text: qsTr("Output:")
					}

					ListModel
					{
						id: outputList
					}

					Repeater
					{
						model: outputList
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

			RowLayout
			{
				id: eventDetail
				anchors.left: parent.left
				anchors.leftMargin: 5
				ColumnLayout
				{
					DefaultLabel
					{
						color: trDetailColor
						id: labelEvent
						text: qsTr("Events:")
					}

					ListModel
					{
						id: eventList
					}

					Repeater
					{
						model: eventList
						RowLayout
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
								width: rowTransactionItem.width - 70
								elide: Text.ElideRight
								font.bold: true
							}
						}
					}
				}
			}

			RowLayout
			{
				id: debugDetail
				spacing: 5
				width: parent.width
				layoutDirection: Qt.RightToLeft
				anchors.left: parent.left
				anchors.leftMargin: 5
				CopyButton
				{
					anchors.verticalCenter: parent.verticalCenter
					getContent: function() {
						return JSON.stringify(tx)
					}
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
					text: isCall ? qsTr("Debug call...") : qsTr("Debug transaction...")
				}
			}
		}
	}
}


