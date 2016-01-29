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
/** @file StepActionImage.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1

Rectangle {
	id: buttonActionContainer
	property string disableStateImg
	property string enabledStateImg
	property string buttonTooltip
	property string buttonShortcut
	property bool buttonLeft
	property bool buttonRight
	signal clicked

	color: "transparent"
	width: 35
	height: 24
	
	function enabled(state)
	{
		buttonAction.enabled = state;
		if (state)
			debugImage.source = enabledStateImg;
		else
			debugImage.source = disableStateImg;
	}

	Rectangle {
		color: "#DCDADA"
		width: 10
		height: 24
		radius: 4
		x: 0
		visible: buttonLeft

		Rectangle {
			anchors {
				left: parent.left
		        right: parent.right
		        top: parent.top
		        bottom: parent.bottom
				bottomMargin: debugImg.pressed ? 0 : 1;
				topMargin: debugImg.pressed ? 1 : 0;
			}
			color: "#FCFBFC"
			radius: 3
		}	 
	}

	Rectangle {
		color: "#DCDADA"
		width: 10
		height: 24
		radius: 4
		x: 25
		visible: buttonRight

		Rectangle {
			anchors {
				left: parent.left
		        right: parent.right
		        top: parent.top
		        bottom: parent.bottom
				bottomMargin: debugImg.pressed ? 0 : 1;
				topMargin: debugImg.pressed? 1 : 0;
			}
			color: "#FCFBFC"
			radius: 3
		}	 
	}

	Rectangle {
		id: contentRectangle
		width: 25
		height: 24
		color: "#DCDADA"
		x: 5

		Rectangle {
			anchors {
				left: parent.left
		        right: parent.right
		        top: parent.top
		        bottom: parent.bottom
				bottomMargin: debugImg.pressed ? 0 : 1;
				topMargin: debugImg.pressed ? 1 : 0;
			}
			color: "#FCFBFC"

			Image {
				id: debugImage
				source: enabledStateImg
				anchors.centerIn: parent
				anchors.topMargin: debugImg.pressed ? 1 : 0;
				
				fillMode: Image.PreserveAspectFit
				width: 15
				height: 15
			}

		}

		DefaultButton {
			anchors.fill: parent
			id: debugImg
			action: buttonAction
			style: ButtonStyle {
				background: Rectangle {
					color: "transparent"
				}
			}
		}

		Action {
			tooltip: buttonTooltip
			id: buttonAction
			shortcut: buttonShortcut
			onTriggered: {
				buttonActionContainer.clicked();
			}
		}
	}
}
