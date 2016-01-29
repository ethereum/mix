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
/** @file TransactionLog.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import org.ethereum.qml.RecordLogEntry 1.0
import org.ethereum.qml.InverseMouseArea 1.0

Item {
	property ListModel fullModel: ListModel{}
	property ListModel transactionModel: ListModel{}
	property ListModel callModel: ListModel{}
	property int selectedStateIndex: statesCombo.selectedIndex

	ColumnLayout {
		anchors.fill: parent
		RowLayout {
			anchors.right: parent.right
			anchors.left: parent.left
			Connections
			{
				id: compilationStatus
				target: codeModel
				property bool compilationComplete: false
				onCompilationComplete: compilationComplete = true
				onCompilationError: compilationComplete = false
			}

			Connections
			{
				target: projectModel
				onProjectSaved:
				{
					if (projectModel.appIsClosing || projectModel.projectIsClosing)
						return;
					if (compilationStatus.compilationComplete && codeModel.hasContract && !clientModel.running)
						projectModel.stateListModel.debugDefaultState();
				}
				onProjectClosed:
				{
					fullModel.clear();
					transactionModel.clear();
					callModel.clear();
				}
			}

			StatesComboBox
			{
				id: statesCombo
				items: projectModel.stateListModel
				onSelectCreate: projectModel.stateListModel.addState()
				onEditItem: projectModel.stateListModel.editState(item)
				colorItem: "#808080"
				colorSelect: "#4a90e2"
				color: "white"
				Connections {
					target: projectModel.stateListModel
					onStateRun: {
						if (statesCombo.selectedIndex !== index)
							statesCombo.setSelectedIndex(index)
					}
					onStateListModelReady: {
						statesCombo.setSelectedIndex(projectModel.stateListModel.defaultStateIndex)
					}
					onStateDeleted: {
						if (index === statesCombo.selectedIndex)
							statesCombo.setSelectedIndex(0);
					}
				}
			}

			CheckBox
			{
				text: qsTr("Mine")
				onCheckedChanged: {
					mineAction.enabled = !checked;
					mineTimer.running = checked;
				}
			}

			Timer
			{
				id: mineTimer
				repeat: true;
				interval: 12000
				running: false
				onTriggered:
				{
					//clientModel.mine();
				}
			}

			DefaultCombobox {
				id: itemFilter
				rootItem: parent
				function getCurrentModel()
				{
					return currentIndex === 0 ? fullModel : currentIndex === 1 ? transactionModel : currentIndex === 2 ? callModel : fullModel;
				}

				model: ListModel {
					ListElement { text: qsTr("Calls and Transactions"); value: 0;  }
					ListElement { text: qsTr("Only Transactions"); value: 1;  }
					ListElement { text: qsTr("Only Calls"); value: 2;  }
				}

				onCurrentIndexChanged:
				{
					logTable.model = itemFilter.getCurrentModel();
				}
			}
		}
		TableView {
			id: logTable
			Layout.fillWidth: true
			Layout.fillHeight: true
			model: fullModel

			TableViewColumn {
				role: "transactionIndex"
				title: qsTr("#")
				width: 40
			}
			TableViewColumn {
				role: "contract"
				title: qsTr("Contract")
				width: 100
			}
			TableViewColumn {
				role: "function"
				title: qsTr("Function")
				width: 120
			}
			TableViewColumn {
				role: "value"
				title: qsTr("Value")
				width: 60
			}
			TableViewColumn {
				role: "address"
				title: qsTr("Destination")
				width: 130
			}
			TableViewColumn {
				role: "returned"
				title: qsTr("Returned")
				width: 120
			}
			TableViewColumn {
				role: "gasUsed"
				title: qsTr("Gas Used")
				width: 120
			}
			onActivated:  {
				var item = logTable.model.get(row);
				if (item.type === RecordLogEntry.Transaction)
					clientModel.debugRecord(item.recordIndex);
				else
					clientModel.emptyRecord();
			}
			Keys.onPressed: {
				if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && currentRow >=0 && currentRow < logTable.model.count) {
					var item = logTable.model.get(currentRow);
					clipboard.text = item.returned;
				}
			}
		}
	}
	Connections {
		target: clientModel
		onStateCleared: {
			fullModel.clear();
			transactionModel.clear();
			callModel.clear();
		}
		onNewRecord: {
			fullModel.append(_r);
			if (!_r.call)
				transactionModel.append(_r);
			else
				callModel.append(_r);
		}
		onMiningComplete: {
			fullModel.append(clientModel.lastBlock);
			transactionModel.append(clientModel.lastBlock);
		}
	}
}
