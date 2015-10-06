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

	width: 750
	height: 180

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
		anchors.fill: parent
		ColumnLayout
		{
			anchors.fill: parent
			anchors.margins: 10
			onWidthChanged: {
				addressText.Layout.preferredWidth = width - address.width - 55
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
				DefaultLabel
				{
					text: qsTr("Balance")
					id: balanceLabel
					Layout.preferredWidth: 70
				}

				Ether
				{
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
				anchors.right: parent.right;

				DefaultButton {
					text: qsTr("Cancel");
					onClicked:
					{
						newAddressWin.close()
					}
				}

				DefaultButton {
					id: okButton;
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
						var ac = projectModel.stateListModel.newAccount(balance.value.toWei().value(), QEther.Wei, newAddressWin.secret.toLowerCase(), nickNameInput.text)
						newAddressWin.addAccount(ac)
						newAddressWin.close()
						addressText.originalText = ""
						nickNameInput.text = ""
					}
				}
			}
		}
	}
}

