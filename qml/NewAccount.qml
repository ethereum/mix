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
/** @file NewAccount.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.QEther 1.0
import "js/QEtherHelper.js" as QEtherHelper
import "js/TransactionHelper.js" as TransactionHelper
import "."

Dialog {
	id: newAddressWin
	modality: Qt.ApplicationModal
	title: qsTr("New Account");

	width: 400
	height: 150

	property var accounts
	property string secret

	signal accepted(var ac)

	visible: false

	function addAccount(ac)
	{
		accepted(ac)
	}

	onVisibleChanged:
	{
		if (visible)
		{
			addressText.text = ""
			balance.value = QEtherHelper.createEther("0", QEther.Wei)
			secret = clientModel.newSecret()
			addressText.originalText = clientModel.address(secret)
		}
	}

	contentItem: Rectangle {
		implicitHeight: newAddressWin.height
		implicitWidth: newAddressWin.width
		ColumnLayout
		{
			anchors.fill: parent
			anchors.margins: 10
			onWidthChanged: {
				addressText.Layout.preferredWidth = width - address.width - 50
			}

			Connections
			{
				target: appSettings
				onSystemPointSizeChanged:
				{
					updateLayout()
				}

				Component.onCompleted:
				{
					updateLayout()
				}

				function updateLayout()
				{
					if (mainApplication.systemPointSize >= appSettings.systemPointSize)
					{
						newAddressWin.width = 400
						newAddressWin.height = 150
						address.Layout.preferredWidth = 70
						balanceLabel.Layout.preferredWidth = 70
						nickName.Layout.preferredWidth = 70
					}
					else
					{
						newAddressWin.width = 400 + 4 * appSettings.systemPointSize
						newAddressWin.height = 150 + 4 * appSettings.systemPointSize
						address.Layout.preferredWidth = 70 + 4 * appSettings.systemPointSize
						balanceLabel.Layout.preferredWidth = 70 + 4 * appSettings.systemPointSize
						nickName.Layout.preferredWidth = 70 + 4 * appSettings.systemPointSize
					}
				}
			}

			RowLayout
			{
				DefaultLabel
				{
					text: qsTr("Address")
					id: address
					Layout.preferredWidth: 70
				}

				DisableInput
				{
					id: addressText
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			RowLayout
			{
				Layout.fillWidth: true
				Layout.preferredWidth: parent.width
				DefaultLabel
				{
					text: qsTr("Balance")
					id: balanceLabel
					Layout.preferredWidth: 70
				}

				Ether
				{
					Layout.preferredWidth: parent.width - balanceLabel.width - 5
					width: parent.width - balanceLabel.width - 5
					edit: true
					readOnly: false
					displayUnitSelection: true
					id: balance
				}
			}


			RowLayout
			{
				DefaultLabel
				{
					text: qsTr("Nickname")
					id: nickName
					Layout.preferredWidth: 70
				}

				DefaultTextField
				{
					id: nickNameInput
					anchors.verticalCenter: parent.verticalCenter
					Layout.fillWidth: true
				}
			}

			RowLayout
			{
				anchors.bottom: parent.bottom
				anchors.right: parent.right

				DefaultButton {
					id: okButton;
					activeFocusOnPress : true
					text: qsTr("OK");
					enabled: newAddressWin.secret !== ""
					onClicked: {
						if (accounts)
							for (var k in accounts)
							{
								if (accounts[k].secret === newAddressWin.secret)
								{
									newAddressWin.close()
									return
								}
							}
						var bal = balance.value.toWei()
						var balanceStr = "0"
						if (bal !== null)
							balanceStr = bal.value()
						var ac = projectModel.stateListModel.newAccount(balanceStr, QEther.Wei, newAddressWin.secret.toLowerCase(), nickNameInput.text)
						newAddressWin.addAccount(ac)
						newAddressWin.close()
						addressText.originalText = ""
						nickNameInput.text = ""
					}
				}

				DefaultButton {
					text: qsTr("Cancel");
					onClicked:
					{
						newAddressWin.close()
					}
				}
			}
		}
	}
}

