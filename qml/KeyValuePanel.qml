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
import "."

ColumnLayout {
	id: root
	property alias title: titleLabel.text
	property variant _data
	property string role
	property alias model: modelKeyValue
	property int minHeight: 100
	property int maxHeight: 250
	signal expanded
	signal minimized
	spacing: 0

	function add(key, value)
	{
		modelKeyValue.append({ "key": key, "value": value })
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
					modelKeyValue.append({ "key": keys[k] === "" ? "undefined" : keys[k], "value": _data[role][keys[k]] })
			}
		}
	}

	RowLayout
	{
		Layout.preferredHeight: 20
		Layout.fillWidth: true
		DefaultLabel
		{
			id: titleLabel
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
			color: "white"
			font.pixelSize: 10
			MouseArea
			{
				anchors.fill: parent
				onClicked:
				{
					root.height = root.height === minHeight ? maxHeight : minHeight
					if (root.height === minHeight)
						minimized()
					else
						expanded()
				}
				cursorShape: Qt.PointingHandCursor
			}
		}
	}

	RowLayout
	{
		Layout.fillWidth: true
		Layout.preferredHeight: 100
		ListModel
		{
			id: modelKeyValue
		}

		Rectangle
		{
			Layout.fillWidth: true
			Layout.fillHeight: true
			color: "white"
			radius: 2
			ScrollView
			{
				id: columnValues
				horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
				anchors.fill: parent
				clip: true
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
							Layout.preferredHeight: 20
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
}

