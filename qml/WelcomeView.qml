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
/**
 * @file WelcomeView.qml
 * @author Liana liana@ethdev.com
 * @date 2016
 * Mix: Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.0
import QtWebEngine 1.0
import QtWebEngine.experimental 1.0
import Qt.labs.settings 1.0
import HttpServer 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/QEtherHelper.js" as QEtherHelper
import "."

Item {
	id: welcomeView

	visible: false

	Rectangle
	{
		color: welcomeViewStyleId.bgColor
		anchors.fill: parent
		ColumnLayout
		{
			anchors.fill: parent
			anchors.top: parent.top
			anchors.verticalCenter: parent.verticalCenter
			anchors.topMargin: 50
			anchors.leftMargin: 50
			spacing: 50

			RowLayout
			{
				Image {
					source: "qrc:/res/Mix-1024.png"
					sourceSize.height: 300
					anchors.left: parent.left
				}
				anchors.left: parent.left
				ColumnLayout
				{
					Layout.fillHeight: true
					Layout.fillWidth: true
					anchors.top: parent.top
					anchors.topMargin: 80
					spacing: 50
					DefaultCompleteButton
					{
						imageSource: "qrc:/qml/img/openedfolder.png"
						labelText: "Open Project"
						onClicked:
						{
							openProjectFileDialog.open();
						}
					}
					DefaultCompleteButton
					{
						imageSource: "qrc:/qml/img/createfolder.png"
						labelText: "New Project"
						onClicked:
						{
							projectModel.createProject()
						}
					}
				}
			}

			DefaultLabel
			{
				text: "To get started"
				font.pixelSize: 32
				color: welcomeViewStyleId.headerColor
			}
			DefaultText {
				text: '<a href="https://github.com/ethereum/wiki/wiki/Mix:-The-DApp-IDE#deployment-to-network"><font color="coral" size="4">Mix: The DApp IDE</font></a>'
				onLinkActivated: Qt.openUrlExternally(link)
			}
			DefaultText {
				text: '<a href="http://solidity.readthedocs.org/en/latest/"><font color="coral" size="4">Solidity Documentation</font></a>'
				onLinkActivated: Qt.openUrlExternally(link)
			}
			Splitter { anchors.fill: parent }
		}
	}
}


