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
	title: qsTr("About Mix")
	modality: Qt.ApplicationModal
	width: 790
	height: 450
	visible: false
	Layout.maximumHeight: Layout.minimumHeight
	Layout.maximumWidth: Layout.minimumWidth

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
				Layout.preferredWidth: 400
				Layout.fillHeight: true
				anchors.top: parent.top
				anchors.topMargin: 20
				DefaultLabel
				{
					id: mixInfo
					text: Qt.application.name + " " + Qt.application.version
					font.pointSize: appSettings.getFormattedPointSize() + 10
					font.bold: true
				}

				DefaultLabel
				{
					text: qsTr("\nGNU General Public License")
					font.italic: true
				}

				DefaultLabel
				{
					text: qsTr("Copyright (c) 2015, 2016. All Rights Reserved.")
				}

				DefaultLabel
				{
					text: qsTr("The program is provided AS IS with NO WARRANTY OF ANY KIND,\nINCLUDING THE WARRANTY OF DESIGN, MERCHANTABILITY\nAND FITNESS FOR A PARTICULAR PURPOSE.")
				}

				DefaultLabel
				{
					text: qsTr("<a href='https://github.com/ethereum/mix'><font color=\"cornflowerblue\" size=\"3\">Source code</font></a>")
					onLinkActivated: Qt.openUrlExternally(link)
				}

				DefaultLabel
				{
					text: qsTr("<a href='http://forum.ethereum.org/categories/mix'><font color=\"cornflowerblue\" size=\"3\">Forum</font></a>")
					onLinkActivated: Qt.openUrlExternally(link)
				}

				DefaultLabel
				{
					id: solInfo
					text: "\nSolidity " + appService.solidityVersionNumber
					font.pointSize: appSettings.getFormattedPointSize() + 5
				}

				TextArea
				{
					id: generalInfo
					text: appService.solidityVersionString
					Layout.preferredWidth: parent.width
					Layout.preferredHeight: 50
					anchors.horizontalCenter: parent.horizontalCenter
					font.pointSize: appSettings.getFormattedPointSize()
					style: TextFieldStyle
					{
						textColor: "black"
						background: Rectangle {
							  border.color: "transparent"
						}
						selectedTextColor: "white"
						selectionColor: "gray"
					}
				}

				DefaultLabel
				{
					text: "Qt " + appService.qtVersion
					font.pointSize: appSettings.getFormattedPointSize() + 2
					anchors.left: parent.left
					anchors.horizontalCenter: parent.horizontalCenter
				}

				DefaultLabel
				{
					anchors.left: parent.left
					text: Qt.application.organization
					font.pointSize: appSettings.getFormattedPointSize() + 5
					anchors.horizontalCenter: parent.horizontalCenter
				}

				DefaultLabel
				{
					text: qsTr("<a href='https://ethereum.org/'><font color=\"cornflowerblue\" size=\"3\">Visit us\n</font></a>")
					onLinkActivated: Qt.openUrlExternally(link)
				}

				Row
				{
					anchors.right: parent.right
					anchors.rightMargin: 10
					spacing: 5
					CopyButton
					{
						id: copyButton
						getContent: function()
						{
							var ret = {
								mix: mixInfo.text,
								solidity: solInfo.text,
								build: generalInfo.text,
								qt: appService.qtVersion
							}
							return JSON.stringify(ret)
						}
					}

					DefaultButton
					{
						text: qsTr("Close")
						height: copyButton.height
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
