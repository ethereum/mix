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
/** @file StorageView.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import "."

DebugInfoList
{
	id: storage
	collapsible: true
	title : qsTr("Storage")
	itemDelegate:
		Item {
		anchors.fill: parent
		RowLayout
		{
			id: row
			anchors.fill: parent
			Rectangle
			{
				color: "#f7f7f7"
				Layout.fillWidth: true
				Layout.minimumWidth: parent.width / 2
				Layout.maximumWidth: parent.width / 2
				DefaultText {
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					font.family: "monospace"
					anchors.leftMargin: 5
					color: "#4a4a4a"
					text: styleData.value.split('\t')[0];
					width: parent.width - 5
					elide: Text.ElideRight
				}
			}
			Rectangle
			{
				color: "transparent"
				Layout.fillWidth: true
				Layout.minimumWidth: parent.width / 2
				Layout.maximumWidth: parent.width / 2
				DefaultText {
					maximumLineCount: 1
					clip: true
					anchors.leftMargin: 5
					width: parent.width - 5
					wrapMode: Text.WrapAnywhere
					anchors.left: parent.left
					font.family: "monospace"
					anchors.verticalCenter: parent.verticalCenter
					color: "#4a4a4a"
					text: styleData.value.split('\t')[1];
					elide: Text.ElideRight
				}
			}
		}

		Rectangle {
			anchors.top: row.bottom
			width: parent.width;
			height: 1;
			color: "#cccccc"
			anchors.bottom: parent.bottom
		}
	}
}

