import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.QEther 1.0
import org.ethereum.qml.InverseMouseArea 1.0
import "js/QEtherHelper.js" as QEtherHelper
import "js/TransactionHelper.js" as TransactionHelper
import "."

Dialog {
	id: modalStateDialog
	modality: Qt.ApplicationModal

	width: 630
	height: 480
	title: qsTr("Edit Starting Parameters")
	visible: false

	property alias minerComboBox: comboMiner
	property int stateIndex
	property var stateTransactions: []
	property var stateAccounts: []
	property var stateContracts: []
	signal accepted
	signal closed

	StateDialogStyle {
		id: stateDialogStyle
	}

	function open(index, item) {
		if (mainApplication.systemPointSize >= appSettings.systemPointSize)
		{
			width = 630
			height = 480
		}
		else
		{
			width = 630 + (11 * appSettings.systemPointSize)
			height = 480 + (7 * appSettings.systemPointSize)
		}
		stateIndex = index
		accountsModel.clear()
		stateAccounts = []
		var miner = 0
		for (var k = 0; k < item.accounts.length; k++) {
			accountsModel.append(item.accounts[k])
			stateAccounts.push(item.accounts[k])
			if (item.miner && item.accounts[k].name === item.miner.name)
				miner = k
		}
		contractsModel.clear()
		stateContracts = []
		if (item.contracts) {
			for (k = 0; k < item.contracts.length; k++) {
				contractsModel.append(item.contracts[k])
				stateContracts.push(item.contracts[k])
			}
		}

		visible = true
		comboMiner.model = stateAccounts
		comboMiner.currentIndex = miner
		forceActiveFocus()

	}

	function acceptAndClose() {
		close()
		accepted()
	}

	function close() {
		visible = false
		closed()
	}

	function getItem() {
		var item = {
			accounts: stateAccounts,
			contracts: stateContracts
		}
		for (var k = 0; k < stateAccounts.length; k++) {
			if (stateAccounts[k].name === comboMiner.currentText) {
				item.miner = stateAccounts[k]
				break
			}
		}
		return item
	}

	contentItem: ColumnLayout {
		implicitHeight: modalStateDialog.height
		implicitWidth: modalStateDialog.width
		anchors.fill: parent
		anchors.margins: 10
		ListModel {
			id: contractsModel

			function removeContract(_i) {
				contractsModel.remove(_i)
				stateContracts.splice(_i, 1)
			}
		}

		ListModel {
			id: accountsModel

			function removeAccount(_i) {
				accountsModel.remove(_i)
				stateAccounts.splice(_i, 1)
			}
		}

		ColumnLayout {
			id: dialogContent
			anchors.top: parent.top
			width: parent.width

			ColumnLayout {
				Layout.fillWidth: true

				RowLayout {
					Layout.preferredWidth: parent.width
					DefaultLabel {
						id: contractsLabel
						text: qsTr("Genesis Contracts")
					}

					DefaultButton {
						Layout.alignment: Qt.AlignRight
						id: importStateButton
						tooltip: qsTr("Import genesis state from JSON file")
						text: qsTr("Import...")
						onClicked: {
							importJsonFileDialog.open()
						}
					}

					QFileDialog {
						id: importJsonFileDialog
						visible: false
						title: qsTr("Select State File")
						nameFilters: Qt.platform.os === "osx" ? [] : [qsTr("JSON files (*.json)", "All files (*)")] //qt 5.4 segfaults with filter string on OSX
						onAccepted: {
							var path = importJsonFileDialog.fileUrl.toString()
							var jsonData = fileIo.readFile(path)
							if (jsonData) {
								var json = JSON.parse(jsonData)
								for (var address in json) {
									var account = {
										address: address,
										name: (json[address].name ? json[address].name : address),
										balance: QEtherHelper.createEther(json[address].wei, QEther.Wei),
										code: json[address].code,
										storage: json[address].storage
									}
									if (account.code) {
										contractsModel.append(account)
										stateContracts.push(account)
									} else {
										accountsModel.append(account)
										stateAccounts.push(account)
									}
								}
							}
						}
					}
				}

				TableView {

					id: genesisContractsView
					Layout.fillWidth: true
					Layout.fillHeight: true
					model: contractsModel
					headerVisible: false
					TableViewColumn {
						role: "name"
						title: qsTr("Name")
						width: 260
						delegate: Item {
							RowLayout {
								height: 25
								width: parent.width
								anchors.verticalCenter: parent.verticalCenter
								DefaultImgButton {
									action: deleteContractAction
									anchors.verticalCenter: parent.verticalCenter
									Image {
										anchors.fill: parent
										source: "qrc:/qml/img/delete-block-icon@2x.png"
									}
									tooltip: qsTr("Delete Contract")
									onClicked: {
										stateContracts.splice(styleData.row, 1)
										contractsModel.remove(styleData.row)
									}
								}

								DefaultTextField {
									Layout.fillWidth: true
									anchors.verticalCenter: parent.verticalCenter
									onTextChanged: {
										if (styleData.row > -1)
											stateContracts[styleData.row].name = text
									}
									text: styleData.value
								}
							}
						}
					}

					TableViewColumn {
						role: "balance"
						title: qsTr("Balance")
						width: 230
						delegate: Item {
							Ether {
								width: parent.width
								anchors.verticalCenter: parent.verticalCenter
								edit: true
								displayFormattedValue: false
								value: styleData.value
							}
						}
					}
					rowDelegate: Rectangle {
						color: styleData.alternate ? "transparent" : "#f0f0f0"
						height: 30
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				RowLayout {
					Layout.preferredWidth: parent.width
					DefaultLabel {
						id: accountsLabel
						Layout.preferredWidth: 85
						text: qsTr("Accounts")
					}

					Row
					{
						Layout.alignment: Qt.AlignRight
						spacing: 5
						DefaultImgButton
						{
							id: addAccount
							iconSource: "qrc:/qml/img/edit_combox.png"
							tooltip: qsTr("Add new account")
							onClicked:
							{
								newAddressWin.accounts = stateAccounts
								newAddressWin.open()
							}
						}

						CopyButton
						{
							id: cpBtn
							getContent: function() {
								return JSON.stringify(stateAccounts, null, "\t");
							}
						}
					}
				}

				MessageDialog {
					id: alertAlreadyUsed
					text: qsTr("This account is in use. You cannot remove it. The first account is used to deploy config contract and cannot be removed.")
					icon: StandardIcon.Warning
					standardButtons: StandardButton.Ok
				}

				TableView {
					Layout.fillWidth: true
					Layout.fillHeight: true

					id: accountsView
					model: accountsModel
					headerVisible: false
					TableViewColumn {
						role: "name"
						title: qsTr("Name")
						delegate: Item {
							Rectangle
							{
								anchors.fill: parent
								color: "transparent"
								RowLayout {
									anchors.top: parent.top
									anchors.topMargin: 10
									anchors.horizontalCenter: parent.horizontalCenter
									anchors.verticalCenter: parent.verticalCenter
									width: parent.width - 20
									MessageDialog
									{
										id: deleteAccountMsg
										text: qsTr("Are you sure to delete this account?")
										onYes:
										{
											stateAccounts.splice(styleData.row, 1)
											accountsView.model.remove(styleData.row)
										}
										standardButtons: StandardButton.Yes | StandardButton.No
									}

									Component.onCompleted:
									{
										addressCopy.originalText = stateAccounts[styleData.row].address
									}

									Layout.preferredWidth: parent.width
									Layout.minimumHeight: 20
									spacing: 5

									Rectangle
									{
										Layout.fillWidth: true
										Rectangle
										{
											border.color: "#cccccc"
											border.width: 1
											width: parent.width
											color: "transparent"
											radius: 4
											height: labelUser.height
											anchors.verticalCenter: parent.verticalCenter
											DefaultText
											{
												anchors.verticalCenter: parent.verticalCenter
												anchors.left: parent.left
												anchors.leftMargin: 2
												id: labelUser
												text: styleData.value
												width: parent.width
												elide: Text.ElideRight
												MouseArea
												{
													anchors.fill: parent
													onDoubleClicked:
													{
														parent.visible = false
														parent.parent.visible = false
														addressField.visible = true
														inverseMouseArea.active = true
														addressField.forceActiveFocus()
													}
												}
											}
										}

										DefaultTextField
										{
											id: addressField
											property bool first: true
											visible: false
											anchors.verticalCenter: parent.verticalCenter
											width: parent.width
											onTextChanged: {
												if (styleData.row > -1 && stateAccounts[styleData.row])
												{
													stateAccounts[styleData.row].name = text
													var index = comboMiner.currentIndex
													comboMiner.model = stateAccounts
													comboMiner.currentIndex = index
												}
												if (first)
												{
													addressField.cursorPosition = 0
													first = false
												}
											}
											text: {
												return styleData.value
											}
											Keys.onEnterPressed: {
												hide()
											}

											Keys.onReturnPressed: {
												hide()
											}

											function hide()
											{
												labelUser.visible = true
												labelUser.parent.visible = true
												addressField.visible = false
												labelUser.text = addressField.text
												inverseMouseArea.active = false
											}

											InverseMouseArea
											{
												id: inverseMouseArea
												anchors.fill: parent
												active: false
												onClickedOutside: {
													parent.hide()
												}
											}
										}
									}

									Ether {
										anchors.verticalCenter: parent.verticalCenter
										inputWidth: 100
										Layout.minimumWidth: 210
										edit: true
										displayFormattedValue: false
										value: {
											if (stateAccounts[styleData.row])
												return stateAccounts[styleData.row].balance
										}
										displayUnitSelection: true
										Component.onCompleted: {
											formatInput()
										}
									}


									DisableInput
									{
										anchors.verticalCenter: parent.verticalCenter
										id: addressCopy
										Layout.preferredWidth: 150

										DefaultImgButton {
											height: 25
											width: 25
											anchors.verticalCenter: parent.verticalCenter
											anchors.left: parent.right
											anchors.leftMargin: 50
											anchors.top: parent.top
											anchors.topMargin: -1
											tooltip: qsTr("Delete Account")
											onClicked: deleteAccountMsg.open()
											Image {
												anchors.fill: parent
												source: "qrc:/qml/img/delete-block-icon@2x.png"
											}
										}
									}

									Rectangle
									{
										Layout.preferredWidth: 85
									}
								}
							}
						}
					}

					rowDelegate: Rectangle {
						color: styleData.alternate ? "transparent" : "#f0f0f0"
						height: 60
					}
				}
			}

			NewAccount
			{
				id: newAddressWin
				onAccepted:
				{
					accountsModel.append(ac)
					stateAccounts.push(ac)
					clientModel.addAccount(ac.secret);
					projectModel.saveProject()
				}
			}

			ColumnLayout {
				DefaultLabel {
					Layout.preferredWidth: 50
					text: qsTr("Miner")
				}

				DefaultCombobox {
					id: comboMiner
					textRole: "name"
					Layout.fillWidth: true
				}
			}
		}

		Row {
			id: validationRow
			anchors.bottom: parent.bottom
			layoutDirection: Qt.RightToLeft
			width: parent.width
			anchors.right: parent.right
			spacing: 10
			height: 30

			DefaultButton {
				anchors.top: parent.top
				anchors.topMargin: 7
				text: qsTr("Cancel")
				onClicked: close()
			}

			DefaultButton {
				anchors.top: parent.top
				anchors.topMargin: 7
				text: qsTr("OK")
				onClicked: {
					close()
					accepted()
				}
			}
		}
	}
}
