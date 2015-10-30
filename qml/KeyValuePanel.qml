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
						Row
						{
							Layout.minimumHeight: 20
							spacing: 5
							anchors.left: colValue.left
							anchors.leftMargin: 5
							DefaultLabel
							{
								maximumLineCount: 1
								text: {
									if (index >= 0 && repeaterKeyValue.model.get(index).key !== undefined)
										return repeaterKeyValue.model.get(index).key
									else
										return ""
								}
							}

							DefaultLabel
							{
								text: "="
							}

							DefaultLabel
							{
								maximumLineCount: 1
								text: {
									if (index >= 0 && repeaterKeyValue.model.get(index).value !== undefined)
										return repeaterKeyValue.model.get(index).value
									else
										return ""
								}
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

