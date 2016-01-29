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
/** @file VariablesView.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

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
			flickableItem.interactive: false

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

