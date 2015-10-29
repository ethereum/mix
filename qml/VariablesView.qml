import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

DebugInfoList
{
	id: storage
	collapsible: true
	title : qsTr("Storage")
	componentDelegate: structComp

	Component
	{
		id: structComp

		ScrollView
		{
			id: scrollVar
			property alias members: typeLoader.members
			property alias value: typeLoader.value
			anchors.fill: parent
			anchors.leftMargin: 10
			StructView
			{
				function updateLayout()
				{
					if (mainApplication.systemPointSize >= appSettings.systemPointSize)
					{
						typeLoader.anchors.leftMargin = 1
						typeLoader.anchors.topMargin = 1
					}
					else
					{
						typeLoader.anchors.leftMargin = 1 + (7 * appSettings.systemPointSize)
						typeLoader.anchors.topMargin = 1 + appSettings.systemPointSize
					}
				}

				Component.onCompleted:
				{
					updateLayout()
				}

				Connections
				{
					target: appSettings
					onSystemPointSizeChanged:
					{
						typeLoader.updateLayout()
					}
				}
				anchors.left: parent.left
				anchors.leftMargin: 1
				anchors.top: parent.top
				anchors.topMargin: 1
				id: typeLoader
				members: []
				value: {}
				context: "variable"
				width: parent.width
			}
		}
	}

	function setData(members, values)  {
		storage.item.value = {};
		storage.item.members = [];
		storage.item.value = values; //TODO: use a signal for this?
		storage.item.members = members;
		if (storage.collapsed && Object.keys(values).length > 0)
			storage.show()
	}
}

