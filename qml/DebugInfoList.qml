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
/** @file DebugInfoList.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1

ColumnLayout {
	id: root
	property string title
	property variant listModel;
	property bool collapsible;
	property bool collapsed;
	property bool enableSelection: false;
	property real storedHeight: 0;
	property Component itemDelegate
	property Component componentDelegate
	property alias item: loader.item
	property variant tableView
	signal rowActivated(int index)
	spacing: 0

	function updateView()
	{
		tableView.updateView()
	}

	function collapse()
	{
		storedHeight = childrenRect.height;
		storageContainer.collapse();
	}

	function show()
	{
		storageContainer.expand();
	}

	Component.onCompleted:
	{
		if (storageContainer.parent.parent.height === 25)
			storageContainer.collapse();
		else
		{
			if (storageContainer.parent.parent.height === 0)
				storageContainer.parent.parent.height = 200;
			storageContainer.expand();
		}
	}

	RowLayout {
		id: header
		Image {
			source: "img/closedtriangleindicator.png"
			width: 15
			height: 15
			id: storageImgArrow
		}

		DefaultText {
			anchors.left: storageImgArrow.right
			color: "#8b8b8b"
			text: title
			id: storageListTitle
		}

		MouseArea
		{
			enabled: collapsible
			anchors.fill: parent
			onClicked: {
				if (collapsible)
				{
					if (collapsed)
						storageContainer.expand();
					else
						storageContainer.collapse();
				}
			}
		}
	}

	Rectangle
	{
		id: storageContainer
		border.width: 1
		border.color: "#deddd9"
		Layout.fillWidth: true
		Layout.fillHeight: true

		function collapse() {
			storedHeight = root.childrenRect.height
			storageImgArrow.source = "qrc:/qml/img/closedtriangleindicator.png"
			if (storageContainer.parent.parent.height > 100)
				storageContainer.parent.parent.height = 100
			collapsed = true
		}

		function expand() {
			storageImgArrow.source = "qrc:/qml/img/opentriangleindicator.png"
			collapsed = false
			storedHeight = 200
			storageContainer.parent.parent.height = storedHeight
		}

		Loader
		{
			id: loader
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.topMargin: 3
			anchors.leftMargin: 3
			width: parent.width - 3
			height: parent.height - 6
			onHeightChanged: {
				if (height <= 0 && collapsible)
					storageContainer.collapse();
				else if (height > 0 && collapsed)
					storageContainer.expand();
			}
			sourceComponent: componentDelegate ? componentDelegate : table
		}

		Component
		{
			id: table
			TableView
			{
				clip: true;
				alternatingRowColors: false
				anchors.fill: parent
				model: listModel
				selectionMode: enableSelection ? SelectionMode.SingleSelection : SelectionMode.NoSelection
				headerDelegate: null
				itemDelegate: root.itemDelegate
				onActivated: rowActivated(row);
				Keys.onPressed: {
					if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && currentRow >=0 && currentRow < listModel.length) {
						var str = "";
						for (var i = 0; i < listModel.length; i++)
							str += listModel[i] + "\n";
						clipboard.text = str;
					}
				}
				id: view

				TableViewColumn {
					role: "modelData"
					width: parent.width
				}

				onModelChanged: updateView()
				onRowCountChanged: updateView()
				function updateView()
				{
					if (collapsed && rowCount > 0)
						storageContainer.expand()
				}

				Component.onCompleted: {
					tableView = view
					rowDelegate = rowItems
				}
			}
		}

		Component
		{
			id: rowItems
			Rectangle
			{
				Component.onCompleted:
				{
					rect.updateLayout()
				}

				id: rect
				Connections
				{
					target: appSettings
					onSystemPointSizeChanged:
					{
						rect.updateLayout()
					}
				}

				function updateLayout()
				{
					if (mainApplication.systemPointSize >= appSettings.systemPointSize)
						rect.height = 20
					else
						rect.height = 20 + appSettings.systemPointSize
				}

				height: 20
				color: "transparent"
			}
		}
	}
}
