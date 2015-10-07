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

	width: 530
	height: 660
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

	contentItem: Rectangle {
		color: stateDialogStyle.generic.backgroundColor
		implicitHeight: modalStateDialog.height
		implicitWidth: modalStateDialog.width
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
								text: qsTr("Genesis\nContracts")
								anchors.horizontalCenter: parent.horizontalCenter
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

							DefaultButton {
								id: importStateButton
								anchors.top: genesisContractsView.top
								anchors.right: genesisContractsView.left
								tooltip: qsTr("Import genesis state from JSON file")
								text: qsTr("Import...")
								onClicked: {
									importJsonFileDialog.open()
								}
							}

							id: genesisContractsView
							Layout.fillWidth: true
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
											iconSource: "qrc:/qml/img/delete_sign.png"
											action: deleteContractAction
											anchors.verticalCenter: parent.verticalCenter
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

					CommonSeparator {
						Layout.fillWidth: true
					}

					RowLayout {
						Layout.fillWidth: true
						Layout.preferredHeight: 300
						Rectangle {
							Layout.preferredWidth: 85
							DefaultLabel {
								id: accountsLabel
								Layout.preferredWidth: 85
								anchors.horizontalCenter: parent.horizontalCenter
								text: qsTr("Accounts")
							}							
						}

						MessageDialog {
							id: alertAlreadyUsed
							text: qsTr("This account is in use. You cannot remove it. The first account is used to deploy config contract and cannot be removed.")
							icon: StandardIcon.Warning
							standardButtons: StandardButton.Ok
						}						

						TableView {
							Layout.preferredHeight: 300
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
								anchors.top: accountsView.top
								anchors.right: accountsView.left
							}

							CopyButton
							{
								id: cpBtn
								getContent: function() {
									return JSON.stringify(stateAccounts, null, "\t");
								}
								anchors.top: addAccount.bottom
								anchors.right: addAccount.right
							}

							id: accountsView
							Layout.fillWidth: true
							model: accountsModel
							headerVisible: false
							TableViewColumn {
								role: "name"
								title: qsTr("Name")
								width: 400
								delegate: Item {
									Rectangle
									{
										anchors.fill: parent
										color: "transparent"
										height: 100
										RowLayout {
											anchors.top: parent.top
											anchors.topMargin: 10
											anchors.left: parent.left
											anchors.leftMargin: 10
											Action {
												id: deleteAccountAction
												tooltip: qsTr("Delete Account")
												onTriggered: deleteAccountMsg.open()
											}

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

											Rectangle
											{
												Layout.preferredWidth: 100
												Layout.preferredHeight: 20
												color: "transparent"
												Rectangle
												{
													border.color: "#cccccc"
													border.width: 1
													width: 100
													color: "transparent"
													radius: 4
													height: 20
													anchors.verticalCenter: parent.verticalCenter
													DefaultText
													{
														anchors.verticalCenter: parent.verticalCenter
														anchors.left: parent.left
														anchors.leftMargin: 2
														id: labelUser
														text: styleData.value
														width: 100
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

												DefaultTextField {
													id: addressField
													property bool first: true
													visible: false
													anchors.verticalCenter: parent.verticalCenter
													width: 100
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

												DisableInput
												{
													anchors.top: parent.bottom
													anchors.topMargin: 5
													id: addressCopy
													width: 100
												}
											}

											Ether {
												anchors.verticalCenter: parent.verticalCenter
												inputWidth: 100
												anchors.top: parent.top
												height: 100
												Layout.preferredWidth: 200
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

												DefaultImgButton {
													iconSource: "qrc:/qml/img/delete-block-icon@2x.png"
													action: deleteAccountAction
													anchors.verticalCenter: parent.verticalCenter
													anchors.left: parent.right
													anchors.leftMargin: 10
												}
											}
										}
									}
								}
							}

							rowDelegate: Rectangle {
								color: styleData.alternate ? "transparent" : "#f0f0f0"
								height: 80
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

					CommonSeparator {
						Layout.fillWidth: true
					}

					RowLayout {
						Layout.fillWidth: true

						Rectangle {
							Layout.preferredWidth: 85
							DefaultLabel {
								anchors.verticalCenter: parent.verticalCenter
								anchors.horizontalCenter: parent.horizontalCenter
								text: qsTr("Miner")
							}
						}

						DefaultCombobox {
							id: comboMiner
							textRole: "name"
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

					DefaultButton {
						text: qsTr("OK")
						onClicked: {
							close()
							accepted()
						}
					}
					DefaultButton {
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
