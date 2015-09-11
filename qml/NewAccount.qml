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
		}
	}

	contentItem: Rectangle {
		anchors.fill: parent
		ColumnLayout
		{
			anchors.fill: parent
			anchors.margins: 10
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
					Layout.preferredWidth: 575
				}

				Button
				{
					property string secret
					anchors.left: parent.right
					anchors.leftMargin: 7
					anchors.verticalCenter: parent.verticalCenter
					iconSource: "qrc:/qml/img/Write.png"
					tooltip: qsTr("Generate account")
					onClicked: {
						secret = clientModel.newSecret()
						addressText.originalText = clientModel.address(secret)
					}
					id: btnNewAddress
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

				TextField
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

				Button {
					text: qsTr("Cancel");
					onClicked:
					{
						newAddressWin.close()
					}
				}

				Button {
					id: okButton;
					text: qsTr("OK");
					enabled: btnNewAddress.secret !== ""
					onClicked: {
						if (accounts)
							for (var k in accounts)
							{
								if (accounts[k].secret === btnNewAddress.secret)
								{
									newAddressWin.close()
									return
								}
							}
						var ac = projectModel.stateListModel.newAccount(balance.value.toWei().value(), QEther.Wei, btnNewAddress.secret.toLowerCase(), nickNameInput.text)
						newAddressWin.addAccount(ac)
						newAddressWin.close()
						btnNewAddress.secret = ""
						addressText.originalText = ""
						nickNameInput.text = ""
					}
				}
			}
		}
	}
}

