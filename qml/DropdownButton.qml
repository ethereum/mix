import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import org.ethereum.qml.InverseMouseArea 1.0

Item
{
	property string tooltip
	property var actions: []
	property string imageSource: "qrc:/qml/img/showmoreactions.png"
	id: root
	function init()
	{
		actionsModel.clear()
		actionLabels.height = 0
		for (var k in actions)
			actionsModel.append({ index: k, label: actions[k].label })
	}

	InverseMouseArea
	{
		id: inverseMouse
		anchors.fill: parent
		active: false
		onClickedOutside: {
			for (var k = 0; k < actionsModel.count; k++)
			{
				if (actionsRepeater.itemAt(k).containsMouse())
					return
			}
			actionLabels.visible = false
			inverseMouse.active = false
		}
	}

	ScenarioButton
	{
		id: labelButton
		roundLeft: false
		roundRight: false
		width: parent.width
		height: parent.height
		sourceImg: imageSource
		text: tooltip
		onClicked:
		{
			btnClicked()
		}

		function btnClicked()
		{
			if (actionLabels.visible)
				actionLabels.visible = false
			else
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
				actionLabels.visible = true
				inverseMouse.active = true
			}
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
				if (actionLabels.visible)
				{
					actionLabels.visible = falses
					labelButton.btnClicked()
				}
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
				id: actionsRepeater
				model: actionsModel
				Rectangle
				{
					function containsMouse()
					{
						return mouseAreaAction.containsMouse
					}
					color: mouseAreaAction.containsMouse ? "#cccccc" : "transparent"
					width: actionLabels.width
					height: labelAction.height + 10

					Component.onCompleted:
					{
						actionLabels.height += height + actionsCol.spacing
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
