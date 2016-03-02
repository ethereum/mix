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
/** @file Debugger.qml
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
import Qt.labs.settings 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "."

Rectangle {
	id: debugPanel

	property alias debugSlider: statesSlider
	property alias solLocals: solLocals
	property alias solStorage: solStorage
	property alias solCallStack: solCallStack
	property alias vmCallStack: callStack
	property alias vmStorage: storage
	property alias vmMemory: memoryDump
	property alias vmCallData: callDataDump
	signal debugExecuteLocation(string documentId, var location, var gasUsed)
	property string compilationErrorMessage
	property bool assemblyMode: false
	signal panelClosed
	objectName: "debugPanel"
	color: "#ededed"
	clip: true

	Keys.onPressed:
	{
		if (event.key === Qt.Key_Right)
		{
			Debugger.stepOverForward()
		}
		else if (event.key === Qt.Key_Left)
		{
			Debugger.stepOverBack()
		}
	}
	onVisibleChanged:
	{
		if (visible)
		{
			debugScrollArea.updateLayout()
			forceActiveFocus();
		}
	}

	onAssemblyModeChanged:
	{
		Debugger.updateMode();
		machineStates.updateHeight();

		if (assemblyMode)
		{
			callStack.updateView()
			storage.updateView()
			memoryDump.updateView()
			callDataDump.updateView()
		}
	}

	function setTr(tr)
	{
	}

	function displayCompilationErrorIfAny()
	{
		debugScrollArea.visible = false;
		compilationErrorArea.visible = true;
		machineStates.visible = false;
		var errorInfo = ErrorLocationFormater.extractErrorInfo(compilationErrorMessage, false);
		errorLocation.text = errorInfo.errorLocation;
		errorDetail.text = errorInfo.errorDetail;
		errorLine.text = errorInfo.line;
	}

	function update(data, giveFocus)
	{
		if (data === null)
			Debugger.init(null);
		else if (data.states.length === 0)
			Debugger.init(null);
		else if (codeModel.hasContract)
		{
			Debugger.init(data);
			trName.text = data.label
			debugScrollArea.visible = true;
			machineStates.visible = true;
			callStack.collapse()
			storage.collapse()
			memoryDump.collapse()
			callDataDump.collapse()
		}
		if (giveFocus)
			forceActiveFocus();
	}

	function setBreakpoints(bp)
	{
		Debugger.setBreakpoints(bp);
	}

	Connections {
		target: clientModel
		onDebugDataReady:  {
			update(_debugData, false);
		}
	}

	Connections {
		target: codeModel
		onCompilationComplete: {
			debugPanel.compilationErrorMessage = "";
		}

		onCompilationError: {
			debugPanel.compilationErrorMessage = _error;
		}
	}

	Settings {
		id: splitSettings
		property alias callStackHeight: callStackRect.height
		property alias storageHeightSettings: storageRect.height
		property alias memoryDumpHeightSettings: memoryRect.height
		property alias callDataHeightSettings: callDataRect.height
	}

	ColumnLayout {
		id: debugScrollArea
		anchors.fill: parent
		spacing: 0
		function updateLayout()
		{
			if (mainApplication.systemPointSize >= appSettings.systemPointSize)
			{
				rowHeader.Layout.preferredHeight = 20
				labelTx.Layout.preferredHeight = 20
			}
			else
			{
				rowHeader.Layout.preferredHeight = 20 + appSettings.systemPointSize
				labelTx.Layout.preferredHeight = 20 + appSettings.systemPointSize
			}
		}

		Connections
		{
			target: appSettings
			onSystemPointSizeChanged:
			{
				debugScrollArea.updateLayout()
			}
		}

		RowLayout
		{
			Layout.preferredWidth: parent.width
			Layout.minimumHeight: 30
			Rectangle
			{
				id: rowHeader
				Layout.preferredWidth: parent.width
				Layout.preferredHeight: parent.height
				color: "transparent"
				DefaultText {
					anchors.centerIn: parent
					text: qsTr("Current Transaction")
				}

				DefaultButton {
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					Component.onCompleted:
					{
						updateLabel()
					}

					function updateLabel()
					{
						if (mainContent.debuggerPanel.assemblyMode)
							text = qsTr("Solidity")
						else
							text = qsTr("VM")
					}
					onClicked:
					{
						mainContent.debuggerPanel.assemblyMode = !mainContent.debuggerPanel.assemblyMode;
						updateLabel()
					}
				}

				DefaultButton {
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					text: qsTr("Scenario View")
					onClicked:
					{
						Debugger.init(null);
						panelClosed()
					}
				}
			}
		}

		RowLayout
		{
			Layout.preferredWidth: parent.width
			Layout.minimumHeight: 20
			Rectangle
			{
				id: labelTx
				Layout.preferredWidth: parent.width
				Layout.preferredHeight: parent.height
				color: "#accbf2"
				DefaultText {
					id: trName
					color: "white"
					anchors.centerIn: parent
				}
			}
		}

		RowLayout
		{
			Layout.preferredWidth: debugScrollArea.width

			DefaultLabel
			{
				anchors.horizontalCenter: parent.horizontalCenter
				visible: mainContent.rightPane.bc.buildUseOptimizedCode
				text: qsTr("The last rebuild uses Solidity optimized code. Please do not use optimize code when debugging a transaction.")
				color: "orange"
				width: debugScrollArea.width - 50
				elide: Qt.ElideRight
				maximumLineCount: 1
			}
		}


		ScrollView
		{
			property int sideMargin: 5
			id: machineStates
			Layout.fillWidth: true
			Layout.fillHeight: true
			flickableItem.interactive: false
			function updateHeight() {
				var h = buttonRow.childrenRect.height;
				if (assemblyMode)
					h += assemblyCodeRow.childrenRect.height + callStackRect.childrenRect.height + storageRect.childrenRect.height + memoryRect.childrenRect.height + callDataRect.childrenRect.height;
				else
					h += solVar.childrenRect.height
				statesLayout.height = h + 120;
			}

			Component.onCompleted: updateHeight();

			ColumnLayout {
				id: statesLayout
				anchors.top: parent.top
				anchors.topMargin: 10
				anchors.left: parent.left;
				anchors.leftMargin: machineStates.sideMargin
				width: debugScrollArea.width - machineStates.sideMargin * 2 - 20
				spacing: machineStates.sideMargin

				Rectangle {
					// step button + slider
					id: buttonRow
					height: 23
					Layout.fillWidth: true
					color: "transparent"

					Rectangle {
						anchors.fill: parent
						color: "transparent"
						RowLayout {
							anchors.fill: parent
							id: jumpButtons
							spacing: 3
							layoutDirection: Qt.LeftToRight

							StepActionImage
							{
								id: runBackAction;
								enabledStateImg: "qrc:/qml/img/jumpoutback.png"
								disableStateImg: "qrc:/qml/img/jumpoutbackdisabled.png"
								onClicked: Debugger.runBack()
								width: 23
								buttonShortcut: "Ctrl+Shift+F5"
								buttonTooltip: qsTr("Run Back")
								visible: false
							}

							StepActionImage
							{
								id: jumpOutBackAction;
								enabledStateImg: "qrc:/qml/img/jumpoutback.png"
								disableStateImg: "qrc:/qml/img/jumpoutbackdisabled.png"
								onClicked: Debugger.stepOutBack()
								width: 23
								buttonShortcut: "Ctrl+Shift+F11"
								buttonTooltip: qsTr("Step Out Back")
							}

							StepActionImage
							{
								id: jumpIntoBackAction
								enabledStateImg: "qrc:/qml/img/jumpintoback.png"
								disableStateImg: "qrc:/qml/img/jumpintobackdisabled.png"
								onClicked: Debugger.stepIntoBack()
								width: 23
								buttonShortcut: "Ctrl+F11"
								buttonTooltip: qsTr("Step Into Back")
							}

							StepActionImage
							{
								id: jumpOverBackAction
								enabledStateImg: "qrc:/qml/img/jumpoverback.png"
								disableStateImg: "qrc:/qml/img/jumpoverbackdisabled.png"
								onClicked: Debugger.stepOverBack()
								width: 23
								buttonShortcut: "Ctrl+F10"
								buttonTooltip: qsTr("Step Over Back")
							}

							StepActionImage
							{
								id: jumpOverForwardAction
								enabledStateImg: "qrc:/qml/img/jumpoverforward.png"
								disableStateImg: "qrc:/qml/img/jumpoverforwarddisabled.png"
								onClicked: Debugger.stepOverForward()
								width: 23
								buttonShortcut: "F10"
								buttonTooltip: qsTr("Step Over Forward")
							}

							StepActionImage
							{
								id: jumpIntoForwardAction
								enabledStateImg: "qrc:/qml/img/jumpintoforward.png"
								disableStateImg: "qrc:/qml/img/jumpintoforwarddisabled.png"
								onClicked: Debugger.stepIntoForward()
								width: 23
								buttonShortcut: "F11"
								buttonTooltip: qsTr("Step Into Forward")
							}

							StepActionImage
							{
								id: jumpOutForwardAction
								enabledStateImg: "qrc:/qml/img/jumpoutforward.png"
								disableStateImg: "qrc:/qml/img/jumpoutforwarddisabled.png"
								onClicked: Debugger.stepOutForward()
								width: 45
								buttonShortcut: "Shift+F11"
								buttonTooltip: qsTr("Step Out Forward")
								buttonRight: true
							}

							StepActionImage
							{
								id: runForwardAction
								enabledStateImg: "qrc:/qml/img/jumpoutforward.png"
								disableStateImg: "qrc:/qml/img/jumpoutforwarddisabled.png"
								onClicked: Debugger.runForward()
								width: 45
								buttonShortcut: "Ctrl+F5"
								buttonTooltip: qsTr("Run Forward")
								buttonRight: true
							}

							Rectangle {
								anchors.top: parent.top
								anchors.bottom: parent.bottom
								anchors.right: parent.right
								color: "transparent"
								Layout.fillWidth: true
								Layout.minimumWidth: parent.width * 0.2
								Layout.alignment: Qt.AlignRight

								Slider {
									id: statesSlider
									anchors.fill: parent
									tickmarksEnabled: true
									stepSize: 1.0
									onValueChanged:
									{
										Debugger.jumpTo(value)
									}

									style: SliderStyle {
										groove: Rectangle {
											implicitHeight: 3
											color: "#accbf2"
											radius: 8
										}
										handle: Rectangle {
											anchors.centerIn: parent
											color: control.pressed ? "white" : "lightgray"
											border.color: "gray"
											border.width: 1
											implicitWidth: 10
											implicitHeight: 10
											radius: 12
										}
									}
								}
							}
						}
					}
				}

				Rectangle {
					// Assembly code
					id: assemblyCodeRow
					Layout.fillWidth: true
					height: 405
					implicitHeight: 405
					color: "transparent"
					visible: assemblyMode

					Rectangle
					{
						id: stateListContainer
						anchors.top : parent.top
						anchors.bottom: parent.bottom
						anchors.left: parent.left
						width: parent.width * 0.4
						height: parent.height
						border.width: 1
						border.color: "#deddd9"
						color: "white"
						TableView {
							id: statesList
							anchors.fill: parent
							anchors.leftMargin: 3
							anchors.rightMargin: 3
							anchors.topMargin: 3
							anchors.bottomMargin: 3
							clip: true
							headerDelegate: null
							itemDelegate: renderDelegate
							model: ListModel {}
							TableViewColumn {
								role: "line"
								width: parent.width - 10
							}

							rowDelegate:
								Component
								{
									id: rowItems
									Rectangle
									{
										Component.onCompleted:
										{
											rect.updateLayout()
										}

										id: rect
										Connections
										{
											target: appSettings
											onSystemPointSizeChanged:
											{
												rect.updateLayout()
											}
										}

										function updateLayout()
										{
											if (mainApplication.systemPointSize >= appSettings.systemPointSize)
												rect.height = 20
											else
												rect.height = 20 + appSettings.systemPointSize
										}

										height: 20
										color: "transparent"
									}
								}

						}

						Component {
							id: highlightBar
							Rectangle {
								radius: 4
								anchors.fill: parent
								y: statesList.currentItem.y
								color: "#4A90E2"
							}
						}

						Component {
							id: renderDelegate
							Item {
								Rectangle {
									radius: 4
									anchors.fill: parent
									color: "#4A90E2"
									visible: styleData.selected;
								}

								RowLayout {
									id: wrapperItem
									anchors.fill: parent
									spacing: 5
									DefaultText {
										anchors.left: parent.left
										anchors.leftMargin: 10
										width: 15
										color: "#b2b3ae"
										text: styleData.value.split(' ')[0]
										font.family: "monospace"
										wrapMode: Text.NoWrap
										id: id
									}
									DefaultText {
										anchors.left: id.right;
										wrapMode: Text.NoWrap
										color: styleData.selected ? "white" : "black"
										font.family: "monospace"
										text: styleData.value.replace(styleData.value.split(' ')[0], '')
									}
								}
							}
						}
					}

					Rectangle {
						id: debugInfoContainer
						width: parent.width * 0.6 - machineStates.sideMargin
						anchors.top : parent.top
						anchors.bottom: parent.bottom
						anchors.right: parent.right
						height: parent.height
						color: "transparent"
						ColumnLayout
						{
							anchors.fill: parent
							spacing: 0

							DebugBasicInfo {
								id: currentStep
								titleStr: qsTr("Current Step")
								Layout.fillWidth: true
								height: 30
							}
							DebugBasicInfo {
								id: mem
								titleStr: qsTr("Adding Memory")
								Layout.fillWidth: true
								height: 30
							}
							DebugBasicInfo {
								id: stepCost
								titleStr: qsTr("Step Cost")
								Layout.fillWidth: true
								height: 30
							}
							DebugBasicInfo {
								id: gasSpent
								titleStr: qsTr("Total Gas Spent")
								Layout.fillWidth: true
								height: 30
							}
							DebugInfoList
							{
								Layout.fillHeight: true
								Layout.fillWidth: true
								id: stack
								collapsible: false
								title : qsTr("Stack")
								itemDelegate: Item {
									id: renderedItem
									width: parent.width
									RowLayout
									{
										anchors.fill: parent
										Rectangle
										{
											id: indexColumn
											color: "#f7f7f7"
											Layout.fillWidth: true
											Layout.minimumWidth: 30
											Layout.preferredWidth: 30
											Layout.maximumWidth: 30
											Layout.minimumHeight: parent.height
											DefaultText {
												anchors.centerIn: parent
												anchors.leftMargin: 5
												font.family: "monospace"
												color: "#4a4a4a"
												text: styleData.row;
											}
										}

										Rectangle
										{
											anchors.left: indexColumn.right
											Layout.fillWidth: true
											Layout.minimumWidth: 15
											Layout.preferredWidth: 15
											Layout.minimumHeight: parent.height
											DefaultText {
												anchors.left: parent.left
												anchors.leftMargin: 5
												font.family: "monospace"
												anchors.verticalCenter: parent.verticalCenter
												color: "#4a4a4a"
												text: styleData.value
											}
										}
									}

									Rectangle {
										id: separator
										width: parent.width;
										height: 1;
										color: "#cccccc"
										anchors.bottom: parent.bottom
									}
								}
							}
						}
					}
				}

			Column
			{
				Layout.fillHeight: true
				Layout.fillWidth: true
				visible: !assemblyMode
				id: solVar
				KeyValuePanel
				{
					title: qsTr("Call Stack")
					id: solCallStack
					width: splitInfoList.width
					hideEqualSign: true
					function setData(values)  {
						_data = values
						computeData()
					}

					function computeData()
					{
						model.clear()
						for (var k in _data)
							model.append({ "key": k, "value": JSON.stringify(_data[k]) })
					}
				}


				KeyValuePanel
				{
					title: qsTr("Locals")
					id: solLocals
					width: splitInfoList.width
					prettyJSON: true
					property var locals
					function setData(_members, _values)  {
						locals = _values
						init()
					}

					function computeData()
					{
						solLocals.clear()
						for (var k in locals)
							solLocals.add(k, JSON.stringify(locals[k]))
						solLocals.updateToJSON()
					}
				}

				KeyValuePanel
				{
					title: qsTr("Members")
					id: solStorage
					width: splitInfoList.width
					prettyJSON: true
					property var members
					function setData(_members, _values)  {
						members = _values
						init()
					}

					function computeData()
					{
						solStorage.clear()
						for (var k in members)
							solStorage.add(k, JSON.stringify(members[k]))
						solStorage.updateToJSON()
					}
				}
			}

				SplitView
				{
					id: splitInfoList
					Layout.fillHeight: true
					Layout.fillWidth: true
					orientation: Qt.Vertical

					Rectangle
					{
						id: callStackRect;
						color: "transparent"
						Layout.minimumHeight: 25
						Layout.maximumHeight: 800
						onHeightChanged: machineStates.updateHeight();
						visible: assemblyMode
						CallStack {
							anchors.fill: parent
							id: callStack
							onRowActivated: Debugger.displayFrame(index);
						}
					}

					Rectangle
					{
						id: storageRect
						color: "transparent"
						width: parent.width
						Layout.minimumHeight: 25
						Layout.maximumHeight: 800
						onHeightChanged: machineStates.updateHeight();
						visible: assemblyMode
						StorageView {
							anchors.fill: parent
							id: storage
						}
					}

					Rectangle
					{
						id: memoryRect;
						color: "transparent"
						width: parent.width
						Layout.minimumHeight: 25
						Layout.maximumHeight: 800
						onHeightChanged: machineStates.updateHeight();
						visible: assemblyMode
						DebugInfoList {
							id: memoryDump
							anchors.fill: parent
							collapsible: true
							title: qsTr("Memory Dump")
							itemDelegate:
								Item {
								height: 29
								width: parent.width - 3;
								ItemDelegateDataDump {}
							}
						}
					}

					Rectangle
					{
						id: callDataRect
						color: "transparent"
						width: parent.width
						Layout.minimumHeight: 25
						Layout.maximumHeight: 800
						onHeightChanged: machineStates.updateHeight();
						visible: assemblyMode
						DebugInfoList {
							id: callDataDump
							anchors.fill: parent
							collapsible: true
							title: qsTr("Call Data")
							itemDelegate:
								Item {
								height: 29
								width: parent.width - 3;
								ItemDelegateDataDump {}
							}
						}
					}
					Rectangle
					{
						id: bottomRect;
						width: parent.width
						Layout.minimumHeight: 20
						color: "transparent"
					}
				}
			}
		}
	}
}
