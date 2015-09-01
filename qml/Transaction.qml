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

	function highlight()
	{
		rowContentTr.select()
	}

	function unHightlight()
	{
		rowContentTr.deselect()
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
				parent.saveStatus = !parent.saveStatus
				if (isCall)
					parent.saveStatus = false
			}
		}
	}

	Rectangle
	{
		Layout.preferredWidth: blockWidth
		Layout.preferredHeight: trHeight
		height: trHeight
		color: isCall ? callColor : txColor
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
			rowContentTr.color = selectedTxColor
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
			rowContentTr.color = isCall ? callColor : txColor
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
				root.editTx(index)
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.preferredHeight: trHeight - 10
			anchors.verticalCenter: parent.verticalCenter
			Rectangle
			{
				Layout.preferredWidth: fromWidth
				anchors.left: parent.left
				anchors.leftMargin: horizontalMargin
				Text
				{
					id: hash
					width: parent.width - 30
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					maximumLineCount: 1
					color: labelColor
					font.pointSize: dbgStyle.absoluteSize(1)
					font.bold: true
					text: {
						if (tx)
							return clientModel.resolveAddress(tx.sender)
						else
							return ""
					}
				}
			}

			Rectangle
			{
				Layout.preferredWidth: toWidth
				Text
				{
					id: func
					text: {
						if (tx)
							parent.parent.userFrienldyToken(tx.label)
						else
							return ""
					}
					elide: Text.ElideRight
					anchors.verticalCenter: parent.verticalCenter
					color: labelColor
					font.pointSize: dbgStyle.absoluteSize(1)
					font.bold: true
					maximumLineCount: 1
					width: parent.width
				}

				Label
				{
					visible: isCall
					anchors.verticalCenter: parent.verticalCenter
					text: qsTr("(JavaScript call)")
					font.italic: true
					font.pointSize: dbgStyle.absoluteSize(-2)
					color: labelColor
					anchors.left: func.right
					anchors.leftMargin: 10
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
				if (tx.recordIndex !== undefined)
				{
					debugTrRequested = [ blockIndex, index ]
					clientModel.debugRecord(tx.recordIndex);
				}
			}
		}
	}
}


