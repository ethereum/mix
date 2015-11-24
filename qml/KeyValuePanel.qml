import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import org.ethereum.qml.QEther 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "js/TransactionHelper.js" as TransactionHelper
import "js/QEtherHelper.js" as QEtherHelper
import "js/ScientificNumber.js" as ScientificNumber
import "."

ColumnLayout {
	id: root
	property alias title: titleLabel.text
	property variant _data
	property string role
	property alias model: modelKeyValue
	property int minHeight: 100
	property int maxHeight: 250
	property bool hideEqualSign
	spacing: 0

	function add(key, value)
	{
		modelKeyValue.append({ "key": key, "value": toScientificNumber(value) })
	}

	function clear()
	{
		modelKeyValue.clear()
	}

	function init()
	{
		modelKeyValue.clear()
		if (typeof(computeData) !== "undefined" && computeData instanceof Function)
			computeData()
		else
		{			
			if (_data !== undefined && _data[role] !== undefined)
			{
				var keys = Object.keys(_data[role])
				for (var k in keys)
					modelKeyValue.append({ "key": keys[k] === "" ? qsTr("anonymous") : keys[k], "value": toScientificNumber(_data[role][keys[k]]) })
			}
		}
	}

	function toScientificNumber(value)
	{
		if (ScientificNumber.isNumber(value))
		{
			value = ScientificNumber.normalize(value)
			if (ScientificNumber.shouldConvertToScientific(value.replace(/"/g, "")))
			{
				return ScientificNumber.toScientificNumber(value.replace(/"/g, "")) + " (" + value + ")"
			}
			else
				return value
		}
		else
			return value
	}

	RowLayout
	{
		Layout.minimumHeight: 20
		Layout.fillWidth: true		

		DefaultLabel
		{
			id: titleLabel
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			color: "#414141"
			elide: Qt.ElideRight
			Layout.preferredWidth: root.width - 10
			maximumLineCount: 1
		}
	}

	onWidthChanged:
	{
		keyPanel.width = width
	}

	Rectangle
	{
		color: "white"
		border.width: 1
		border.color: "#cccccc"
		radius: 2
		Layout.preferredWidth: parent.width
		Layout.minimumHeight: minHeight
		width: parent.width
		CopyButton
		{
			anchors.top: parent.top
			anchors.topMargin: 1
			anchors.right: parent.right
			anchors.rightMargin: 1
			getContent: function()
			{
				var data = {}
				data.info = titleLabel.text
				data.content = []
				for (var k = 0; k < modelKeyValue.count; k++)
					data.content.push({ key: modelKeyValue.get(k).key, value: modelKeyValue.get(k).value})
				return JSON.stringify(data)
			}
		}
		RowLayout
		{
			id: keyPanel
			onHeightChanged:
			{
				parent.Layout.minimumHeight = height
			}

			ListModel
			{
				id: modelKeyValue
			}

			Rectangle
			{
				anchors.fill: parent
				color: "white"
				border.width: 1
				border.color: "#cccccc"
				radius: 2
				visible: false
			}

			ScrollView
			{
				id: columnValues
				horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
				Layout.preferredWidth: parent.width
				width: parent.width
				clip: true
				anchors.left: parent.left
				flickableItem.interactive: false

				ColumnLayout
				{
					spacing: 0
					id: colValue
					anchors.top: parent.top
					anchors.topMargin: 5

					Repeater
					{
						id: repeaterKeyValue
						model: modelKeyValue

						DefaultLabel
						{
							Layout.minimumHeight: 20
							anchors.left: colValue.left
							anchors.leftMargin: 5
							maximumLineCount: 1
							Layout.preferredWidth: columnValues.width - 40
							elide: Qt.ElideRight
							text:
							{
								var ret = ""
								if (index >= 0 && repeaterKeyValue.model.get(index).key !== undefined)
									ret = repeaterKeyValue.model.get(index).key
								else
									return ret
								if (!hideEqualSign)
									ret += " = "
								else
									ret += "   "
								if (index >= 0 && repeaterKeyValue.model.get(index).value !== undefined)
									ret += repeaterKeyValue.model.get(index).value
								return ret
							}
						}
					}
				}
			}

		}
	}

	Rectangle
	{
		id: slider
		height: 5
		Layout.preferredWidth: parent.width
		anchors.bottom: parent.bottom
		color: "#cccccc"
		MouseArea
		{
			anchors.fill: parent
			drag.target: slider
			drag.axis: Drag.YAxis
			acceptedButtons: Qt.LeftButton
			cursorShape: Qt.SplitVCursor
			property int pos
			onMouseYChanged:
			{
				if (pressed)
				{
					var newHeight = columnValues.Layout.minimumHeight + mouseY - pos
					if (newHeight > minHeight && newHeight < 800)
					{
						columnValues.Layout.minimumHeight = newHeight
						keyPanel.height = newHeight
					}
				}
			}

			onPressed:
			{
				pos = mouseY
			}
		}
	}
}

