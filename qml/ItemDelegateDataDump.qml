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
/** @file ItemDelegateDataDump.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1
import "."

Rectangle {
	anchors.fill: parent
	RowLayout
	{
		id: row;
		anchors.fill: parent
		spacing: 2
		Rectangle
		{
			id: firstCol;
			color: "#f7f7f7"
			Layout.fillWidth: true
			Layout.minimumWidth: 35
			Layout.preferredWidth: 35
			Layout.maximumWidth: 35
			Layout.minimumHeight: parent.height
			DefaultText {
				anchors.verticalCenter: parent.verticalCenter
				anchors.left: parent.left
				anchors.leftMargin: 3
				font.family: "monospace"
				font.bold: true
				color: "#4a4a4a"
				text: modelData[0]
			}
		}

		Rectangle
		{
			Layout.fillWidth: true
			Layout.minimumWidth: 110
			Layout.preferredWidth: 110
			Layout.maximumWidth: 110
			Layout.minimumHeight: parent.height
			Text {
				font.family: "monospace"
				font.bold: true
				anchors.verticalCenter: parent.verticalCenter
				anchors.left: parent.left
				anchors.leftMargin: 4
				color: "#4a4a4a"
				text: modelData[1]
			}
		}
	}

	Rectangle {
		width: parent.width;
		height: 1;
		color: "#cccccc"
		anchors.bottom: parent.bottom
	}
}
