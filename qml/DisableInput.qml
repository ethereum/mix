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
/** @file DisableInput.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper

DefaultTextField
{
	id: rootDisableInput
	readOnly: true
	property var originalText
	property string tooltip

	function init()
	{
		if (originalText)
		{
			text = originalText
			cursorPosition = 0
		}
	}

	onOriginalTextChanged:
	{
		init()
	}

	Component.onCompleted:
	{
		init()
	}

	style: TextFieldStyle {
		background: Rectangle
		{
		width: rootDisableInput.width
		color: "#cccccc"
		radius: 2
	}
}

	CopyButton
	{
		id: buttonCopy
		anchors.right: parent.right
		anchors.rightMargin: 1
		anchors.verticalCenter: parent.verticalCenter
		height: parent.height - 2
		width: 30
		tooltip: localPackageUrl.tooltip
		getContent: function()
		{
			return rootDisableInput.originalText;
		}
	}
}

