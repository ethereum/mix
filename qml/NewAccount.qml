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

	width: 690
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
					text: qsTr("Secret")
					Layout.preferredWidth: 70
				}

				TextField
				{
					Layout.preferredWidth: 550
					id: input
					onTextChanged: {
						var hexCheck = new RegExp("[0-9a-f]+");
						addressText.originalText = clientModel.address(input.text)
						if (input.text.length !== 64 || !hexCheck.test(input.text))
							okButton.enabled = false
						else
							okButton.enabled = true
					}

					Button
					{
						anchors.left: parent.right
						anchors.leftMargin: 7
						anchors.verticalCenter: parent.verticalCenter
						iconSource: "qrc:/qml/img/Write.png"
						tooltip: qsTr("Generate secret")
						onClicked: {
							input.text = clientModel.newSecret();
						}
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
					Layout.preferredWidth: 595
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
					Layout.preferredWidth: 595
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
					enabled: input.text !== ""
					onClicked: {
						if (accounts)
							for (var k in accounts)
							{
								if (accounts[k].secret === input.text)
								{
									input.text = ""
									newAddressWin.close()
								}
							}

						var secret = input.text
						secret = secret.toLowerCase()
						var hexCheck = new RegExp("[0-9a-f]+");
						var ac = projectModel.stateListModel.newAccount(balance.value.toWei().value(), QEther.Wei, input.text, nickNameInput.text)
						newAddressWin.addAccount(ac)
						newAddressWin.close()
						input.text = ""
						nickNameInput.text = ""
					}
				}
			}
		}
	}
}

