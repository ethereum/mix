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
/** @file AboutMix.qml
 * @author Yann yann@ethdev.com
 * @date 2016
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.3
import "."

Dialog {
	id: modalAboutMix
	modality: Qt.ApplicationModal
	width: 680
	height: 300
	visible: false
	contentItem: Rectangle {
		id: containerRect
		anchors.fill: parent
		implicitHeight: modalAboutMix.height
		implicitWidth: modalAboutMix.width
		RowLayout
		{
			anchors.fill: parent
			spacing: 0
			Item
			{
				Layout.preferredHeight: parent.height
				Layout.preferredWidth: 300
				Image {
					source: "qrc:/res/Mix-1024.png"
					sourceSize.height: 300
				}
			}

			ColumnLayout
			{
				Layout.preferredWidth: 380
				Layout.fillHeight: true
				anchors.top: parent.top
				anchors.topMargin: 20
				DefaultLabel
				{
					id: mixInfo
					text: Qt.application.name + " " + Qt.application.version
					font.pointSize: appSettings.getFormattedPointSize() + 10
				}

				DefaultLabel
				{
					id: solInfo
					text: "Solidity " + appService.solidityVersionNumber
					font.pointSize: appSettings.getFormattedPointSize() + 5
				}

				Text
				{
					id: generalInfo
					text: appService.solidityVersionString
					wrapMode: Text.WrapAtWordBoundaryOrAnywhere
					Layout.preferredWidth: parent.width
					anchors.horizontalCenter: parent.horizontalCenter
				}

				DefaultLabel
				{					
					text: Qt.application.organization
					anchors.horizontalCenter: parent.horizontalCenter
				}

				DefaultLabel
				{
					text: qsTr("GNU General Public License")
					font.italic: true
				}

				DefaultLabel
				{
					text: qsTr("<a href='https://github.com/ethereum/mix'>source code</a>")
					onLinkActivated: Qt.openUrlExternally(link)
				}

				DefaultLabel
				{
					text: qsTr("<a href='http://forum.ethereum.org/categories/mix'>forum</a>")
					onLinkActivated: Qt.openUrlExternally(link)
				}

				Row
				{
					anchors.right: parent.right
					anchors.rightMargin: 10
					spacing: 5
					CopyButton
					{
						getContent: function()
						{
							var ret = {
								mix: mixInfo.text,
								solidity: solInfo.text,
								build: generalInfo.text
							}
							return JSON.stringify(ret)
						}
					}

					Button
					{
						text: qsTr("Close")
						onClicked:
						{
							modalAboutMix.visible = false
						}
					}
				}


			}
		}
	}
}
