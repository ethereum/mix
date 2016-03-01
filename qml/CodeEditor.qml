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
/** @file CodeEditor.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import "."

Item {
	signal editorTextChanged

	function setText(text) {
		codeEditor.text = text;
	}

	function getText() {
		return codeEditor.text;
	}

	function setFocus() {
		codeEditor.forceActiveFocus();
	}

	anchors.fill: parent
	id: contentView
	width: parent.width
	height: parent.height * 0.7

	Rectangle {
		id: lineColumn
		property int rowHeight: codeEditor.font.pixelSize + 3
		color: "#202020"
		width: 50
		height: parent.height
		Column {
			y: -codeEditor.flickableItem.contentY + 4
			width: parent.width
			Repeater {
				model: Math.max(codeEditor.lineCount + 2, (lineColumn.height/lineColumn.rowHeight))
				delegate: DefaultText {
					id: text
					color: codeEditor.textColor
					font: codeEditor.font
					width: lineColumn.width - 4
					horizontalAlignment: Text.AlignRight
					verticalAlignment: Text.AlignVCenter
					height: lineColumn.rowHeight
					renderType: Text.NativeRendering
					text: index + 1
				}
			}
		}
	}

	DefaultTextArea {
		id: codeEditor
		textColor: "#EEE8D5"
		style: TextAreaStyle {
			backgroundColor: "#002B36"
		}

		anchors.left: lineColumn.right
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		wrapMode: TextEdit.NoWrap
		frameVisible: false

		height: parent.height
		font.family: "Monospace"
		width: parent.width

		tabChangesFocus: false
		Keys.onPressed: {
			if (event.key === Qt.Key_Tab) {
				codeEditor.insert(codeEditor.cursorPosition, "\t");
				event.accepted = true;
			}
			if (event.modifiers().testFlag(Qt.Key_Control))//Qt::ControlModifier))
				if (event.key() == Qt.Key_Plus)
				{
					codeEditor.font.pixelSize = codeEditor.font.pixelSize() * 0.20;
				} else if (event.key() == Qt.Key_Minus)
				{
					codeEditor.font.pixelSize = codeEditor.font.pixelSize() / 0.20;
				}




		}
		onTextChanged: {
			editorTextChanged();
		}

	}
}
