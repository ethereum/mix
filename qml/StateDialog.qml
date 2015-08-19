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
	id: modalStateDialog
	modality: Qt.ApplicationModal

	width: 630
	height: 660
	title: qsTr("Edit Genesis Parameters")
	visible: false

	property alias isDefault: defaultCheckBox.checked
	property alias minerComboBox: comboMiner
	property int stateIndex
	property var stateTransactions: []
	property var stateAccounts: []
	property var stateContracts: []
	signal accepted

	StateDialogStyle {
		id: stateDialogStyle
	}

	function open(index, item, setDefault) {
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

		stateContracts = []
		if (item.contracts) {
			for (k = 0; k < item.contracts.length; k++) {
				contractsModel.append(item.contracts[k])
				stateContracts.push(item.contracts[k])
			}
		}

		visible = true
		isDefault = setDefault
		console.log(isDefault)
		defaultCheckBox.checked = isDefault
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
		item.defaultState = defaultCheckBox.checked
		return item
	}

	contentItem: Rectangle {
		color: stateDialogStyle.generic.backgroundColor
		Rectangle {
			color: stateDialogStyle.generic.backgroundColor
			anchors.top: parent.top
			anchors.margins: 10
			anchors.fill: parent
			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 10
				ColumnLayout {
					id: dialogContent
					anchors.top: parent.top

					RowLayout {
						Layout.fillWidth: true

						Rectangle {
							Layout.preferredWidth: 85
							DefaultLabel {
								id: contractsLabel
								Layout.preferredWidth: 85
								wrapMode: Text.WrapAnywhere
								text: qsTr("Genesis\nContracts")
							}

							Button {
								id: importStateButton
								anchors.top: contractsLabel.bottom
								anchors.topMargin: 10
								action: importStateAction
							}

							Action {
								id: importStateAction
								tooltip: qsTr("Import genesis state from JSON file")
								text: qsTr("Import...")
								onTriggered: {
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
							model: contractsModel
							headerVisible: false
							TableViewColumn {
								role: "name"
								title: qsTr("Name")
								width: 230
								delegate: Item {
									RowLayout {
										height: 25
										width: parent.width
										anchors.verticalCenter: parent.verticalCenter
										Button {
											iconSource: "qrc:/qml/img/delete_sign.png"
											action: deleteContractAction
										}

										Action {
											id: deleteContractAction
											tooltip: qsTr("Delete Contract")
											onTriggered: {
												stateContracts.splice(styleData.row, 1)
												contractsModel.remove(styleData.row)
											}
										}

										DefaultTextField {
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
								width: 200
								delegate: Item {
									Ether {
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

					CommonSeparator {
						Layout.fillWidth: true
					}

					RowLayout {
						Layout.fillWidth: true

						Rectangle {
							Layout.preferredWidth: 85
							DefaultLabel {
								id: accountsLabel
								Layout.preferredWidth: 85
								text: qsTr("Accounts")
							}

							Button
							{
								id: addAccount
								anchors.top: accountsLabel.bottom
								anchors.topMargin: 2
								text: qsTr("Add")
								onClicked:
								{
									newAddressWin.open()
								}
							}

							Button
							{
								anchors.top: addAccount.bottom
								anchors.topMargin: 2
								text: qsTr("Copy")
								onClicked:
								{
									clipboard.text = JSON.stringify(stateAccounts, null, "\t");
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
							id: accountsView
							Layout.fillWidth: true
							model: accountsModel
							headerVisible: false
							TableViewColumn {
								role: "name"
								title: qsTr("Name")
								width: 230
								delegate: Item {
									RowLayout {
										height: 25
										width: parent.width
										Button {
											iconSource: "qrc:/qml/img/delete_sign.png"
											action: deleteAccountAction
										}

										Action {
											id: deleteAccountAction
											tooltip: qsTr("Delete Account")
											onTriggered: {
												stateAccounts.splice(styleData.row, 1)
												accountsView.model.remove(styleData.row)
											}
										}

										DefaultTextField {
											anchors.verticalCenter: parent.verticalCenter
											onTextChanged: {
												if (styleData.row > -1) {
													stateAccounts[styleData.row].name = text
													var index = comboMiner.currentIndex
													comboMiner.model = stateAccounts
													comboMiner.currentIndex = index
												}
											}
											text: {
												return styleData.value
											}
										}
									}
								}
							}

							TableViewColumn {
								role: "balance"
								title: qsTr("Balance")
								width: 200
								delegate: Item {
									Ether {
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

					Dialog {
						id: newAddressWin
						modality: Qt.ApplicationModal
						title: qsTr("New Account");

						width: 300
						height: 100

						visible: false

						function addAccount(ac)
						{
							accountsModel.append(ac)
							stateAccounts.push(ac)
							clientModel.addAccount(ac.secret);
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
									}

									TextField
									{
										Layout.preferredWidth: 230
										id: input
									}
								}

								RowLayout
								{
									id: error
									visible: false
									DefaultLabel
									{
										color: "red"
										text: qsTr("bad formatting")
									}
								}

								RowLayout
								{
									anchors.bottom: parent.bottom
									anchors.right: parent.right;

									Button {
										id: okButton;
										text: qsTr("OK");
										onClicked: {
											var ac;
											if (input.text === "")
												ac = projectModel.stateListModel.newAccount("O", QEther.Wei)
											else
											{
												for (var k in stateAccounts)
												{
													if (stateAccounts[k].secret === input.text)
													{
														input.text = ""
														newAddressWin.close()
													}
												}

												var secret = input.text
												secret = secret.toLowerCase()
												var hexCheck = new RegExp("[0-9a-f]+");
												if (secret.length !== 64 || !hexCheck.test(secret))
												{
													error.visible = true
													return
												}
												ac = projectModel.stateListModel.newAccount("O", QEther.Wei, input.text)
											}
											error.visible = false
											newAddressWin.addAccount(ac)
											newAddressWin.close()
											input.text = ""
										}
									}

									Button {
										text: qsTr("Cancel");
										onClicked:
										{
											error.visible = false
											newAddressWin.close()
										}
									}
								}
							}
						}
					}

					CommonSeparator {
						Layout.fillWidth: true
					}

					RowLayout {
						Layout.fillWidth: true
						DefaultLabel {
							Layout.preferredWidth: 85
							text: qsTr("Miner")
						}
						ComboBox {
							id: comboMiner
							textRole: "name"
							Layout.fillWidth: true
						}
					}

					CommonSeparator {
						Layout.fillWidth: true
					}

					RowLayout {
						Layout.fillWidth: true
						DefaultLabel {
							Layout.preferredWidth: 85
							text: qsTr("Default")
						}
						CheckBox {
							id: defaultCheckBox
							Layout.fillWidth: true
						}
					}

					CommonSeparator {
						Layout.fillWidth: true
					}

				}

				RowLayout {
					anchors.bottom: parent.bottom
					anchors.right: parent.right

					Button {
						text: qsTr("OK")
						onClicked: {
							close()
							accepted()
						}
					}
					Button {
						text: qsTr("Cancel")
						onClicked: close()
					}
				}

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
			}
		}
	}
}
