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
/** @file DefaultCombobox.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3

ComboBox {
	id: combo
	property variant rootItem
	signal updateView()

	function updateCombobox()
	{
		updateView()
	}

	style: ComboBoxStyle
	{
	label:
		Rectangle {
		anchors.fill: parent
		color: "transparent"
		DefaultLabel {
			id: labelCombo
			anchors.verticalCenter: parent.verticalCenter
			text: currentText

			Connections
			{
				target: rootItem
				onVisibleChanged:
				{
					if (rootItem && rootItem.visible)
						labelCombo.updateHeight()
				}
			}

			Connections
			{
				target: combo
				onVisibleChanged:
				{
					labelCombo.updateHeight()
				}
				onModelChanged:
				{
					labelCombo.updateHeight()
				}
				onUpdateView:
				{
					labelCombo.updateHeight()
				}
				onCurrentTextChanged:
				{
					labelCombo.updateHeight()
				}
				onCurrentIndexChanged:
				{
					labelCombo.updateHeight()
				}
			}

			Connections
			{
				target: appSettings
				onSystemPointSizeChanged:
				{
					labelCombo.updateHeight()
				}

				Component.onCompleted:
				{
					labelCombo.updateHeight()
				}
			}

			function updateHeight()
			{
				combo.height = appSettings.systemPointSize + 10
			}
		}
	}
}
}

