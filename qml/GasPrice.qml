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
/** @file GasPrice.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper
import org.ethereum.qml.QEther 1.0

ColumnLayout
{
	property bool defaultGasPrice
	property variant gasPrice
	property var defaultUnit

	function init(value)
	{
		gasPriceInput.value = QEtherHelper.createEther(value, QEther.Wei)
		gasPriceDefault.value = QEtherHelper.createEther(value, QEther.Wei)
		gasPrice = QEtherHelper.createEther(value, QEther.Wei)
		gasPriceInput.formatInput()
	}

	function toHexWei()
	{
		var wei = gasPrice.toWei()
		if (wei !== null)
			return "0x" + wei.hexValue()
		else
			return "0x"
	}

	Component.onCompleted:
	{
		gasPriceDefaultCheckbox.checked = defaultGasPrice
		if (!gasPriceInput.value)
		{
			gasPriceInput.value = QEtherHelper.createEther("0", QEther.Finney)
			gasPrice = QEtherHelper.createEther("0", QEther.Finney)
		}
	}

	RowLayout
	{
		Layout.fillWidth: true
		CheckBox
		{
			id: gasPriceDefaultCheckbox
			onCheckedChanged:
			{
				gasPriceInput.readOnly = checked
				if (checked)
					gasPrice = gasPriceDefault.value
				else
					gasPrice = gasPriceInput.value
				gasPriceChanged()
			}
		}

		DefaultLabel
		{
			text: qsTr("Default:")
		}

		Ether
		{
			id: gasPriceDefault
			displayUnitSelection: false
			displayFormattedValue: true
			edit: false
		}
	}

	RowLayout
	{
		Layout.fillWidth: true
		DefaultLabel
		{
			text: qsTr("Yours:")
		}

		Ether
		{
			id: gasPriceInput
			displayUnitSelection: true
			displayFormattedValue: false
			edit: true
			readOnly: true
			Layout.preferredWidth: 200
		}
	}

	Connections
	{
		target: gasPriceInput
		onValueChanged:
		{
			update()
		}
		onAmountChanged:
		{
			update()
		}
		onUnitChanged:
		{
			update()
		}

		function update()
		{
			if (!gasPriceDefaultCheckbox.checked)
			{
				gasPrice = gasPriceInput.value
				gasPriceChanged()
			}
		}
	}
}


