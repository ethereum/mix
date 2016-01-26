import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1

Item
{
	property var actions: []
	id: root
	function init()
	{
		actionsModel.clear()
		actionLabels.height = 0
		for (var k in actions)
			actionsModel.append({ index: k, label: actions[k].label })
	}

	ScenarioButton
	{
		id: labelButton
		roundLeft: true
		roundRight: true
		width: 40
		height: 30
		sourceImg: "qrc:/qml/img/plus.png"
		text: qsTr("Add Transaction/Block")
		onClicked:
		{
			btnClicked()
		}

		function btnClicked()
		{
			parent.init()
			var top = labelButton;
			while (top.parent)
				top = top.parent
			actionLabels.parent = top
			var globalCoord = labelButton.mapToItem(null, 0, 0);
			actionLabels.x = globalCoord.x + labelButton.width
			actionLabels.y = globalCoord.y
			actionLabels.z = 50
			actionLabels.visible = !actionLabels.visible
		}
	}

	Rectangle
	{
		id: actionLabels
		visible: false
		width: (5 * appSettings.systemPointSize) + minWidth
		property int minHeight: 35
		property int minWidth: 150
		Connections
		{
			target: appSettings
			onSystemPointSizeChanged:
			{
				updateSize()
			}

			Component.onCompleted:
			{
				updateSize()
			}

			function updateSize()
			{
				actionLabels.visible = false
				labelButton.btnClicked()
			}
		}

		ColumnLayout
		{
			id: actionsCol
			spacing: 5
			ListModel
			{
				id: actionsModel
			}

			Repeater
			{
				model: actionsModel
				Rectangle
				{
					color: mouseAreaAction.containsMouse ? "#cccccc" : "transparent"
					width: actionLabels.width
					height: labelAction.height + 10

					Component.onCompleted:
					{
						actionLabels.height = actionLabels.height + height
					}

					DefaultLabel
					{
						text: actions[index].label
						elide: Text.ElideRight
						id: labelAction
						anchors.left: parent.left
						anchors.leftMargin: 10
						anchors.verticalCenter: parent.verticalCenter
						MouseArea
						{
							id: mouseAreaAction
							anchors.fill: parent
							hoverEnabled: true
							onClicked:
							{
								actions[index].action()
								actionLabels.visible = false
							}
						}
					}
				}
			}
		}
	}
}
