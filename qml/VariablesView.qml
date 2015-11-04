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
			anchors.fill: parent
			anchors.leftMargin: 10

			function set(_members, _values)
			{
				typeLoader.set(_members, _values)
			}

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
				context: "variable"
				anchors.fill: parent
			}
		}
	}

	function setData(members, values)  {
		storage.item.set(members, values)
		if (storage.collapsed && Object.keys(values).length > 0)
			storage.show()
	}
}

