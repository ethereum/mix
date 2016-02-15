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
/** @file MainContent.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0
import org.ethereum.qml.QEther 1.0
import "js/QEtherHelper.js" as QEtherHelper
import "js/TransactionHelper.js" as TransactionHelper
import "."

Rectangle {
	objectName: "mainContent"
	signal keyPressed(variant event)
	signal webPreviewOrientationChanged()
	focus: true
	Keys.enabled: true
	Keys.onPressed:
	{
		root.keyPressed(event.key);
	}
	anchors.fill: parent
	id: root

	property alias rightViewVisible: scenarioExe.visible
	property alias webViewVisible: webPreview.visible
	property alias webView: webPreview
	property alias projectViewVisible: projectList.visible
	property alias projectNavigator: projectList
	property alias runOnProjectLoad: mainSettings.runOnProjectLoad
	property alias rightPane: scenarioExe
	property alias debuggerPanel: debugPanel
	property alias codeEditor: codeEditor
	property bool webViewHorizontal: codeWebSplitter.orientation === Qt.Vertical //vertical splitter positions elements vertically, splits screen horizontally
	property bool displayCalls
	property int scenarioMinWidth: 485
	property int scenarioMaxWidth: parent.width * 0.6

	Component.onCompleted:
	{
		var qtversion = appService.qtVersion.split(".")
		if (!(parseInt(qtversion[0]) >= 5 && parseInt(qtversion[1]) >= 3))
			qtVersionDialog.open()

	}

	MessageDialog
	{
		id: qtVersionDialog
		text: qsTr("The current installed Qt version is not compatible with Mix. Qt 5.3 minimum is needed. Usability might be degraded.")
		standardButtons: StandardIcon.Ok
		icon: StandardIcon.Critical
	}

	Connections {
		target: debugPanel
		onDebugExecuteLocation: {
			codeEditor.highlightExecution(documentId, location, gasUsed);
		}
	}

	Connections {
		target: codeEditor
		onBreakpointsChanged: {
			debugPanel.setBreakpoints(codeEditor.getBreakpoints());
		}
	}

	function startQuickDebugging()
	{
		ensureRightView();
		projectModel.stateListModel.debugDefaultState();
	}

	function toggleRightView() {
		scenarioExe.visible = !scenarioExe.visible;
	}

	function ensureRightView() {
		scenarioExe.visible = true;
	}

	function rightViewIsVisible()
	{
		return scenarioExe.visible;
	}

	function hideRightView() {
		scenarioExe.visible = lfalse;
	}

	function toggleWebPreview() {
		webPreview.visible = !webPreview.visible;
	}

	function toggleProjectView() {
		projectList.visible = !projectList.visible;
	}

	function toggleWebPreviewOrientation() {
		codeWebSplitter.orientation = (codeWebSplitter.orientation === Qt.Vertical ? Qt.Horizontal : Qt.Vertical);
		webPreviewOrientationChanged()
	}

	//TODO: move this to debugger.js after refactoring, introduce events
	function toggleBreakpoint() {
		codeEditor.toggleBreakpoint();
	}

	function displayCompilationErrorIfAny()
	{
		scenarioExe.visible = true;
		scenarioExe.displayCompilationErrorIfAny();
	}

	Settings {
		id: mainSettings
		property alias codeWebOrientation: codeWebSplitter.orientation
		property alias webWidth: webPreview.width
		property alias webHeight: webPreview.height
		property bool runOnProjectLoad: true
		property int scenarioMinWidth: scenarioMinWidth
	}


	ColumnLayout
	{
		id: mainColumn
		anchors.fill: parent
		spacing: 0
		Rectangle {
			width: parent.width
			height: 40
			Layout.row: 0
			Layout.fillWidth: true
			Layout.minimumHeight: 40

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
					if (appSettings.systemPointSize < mainApplication.systemPointSize)
						headerView.Layout.minimumHeight = 40
					else
						headerView.Layout.minimumHeight = 40 + appSettings.systemPointSize
				}
			}

			id: headerView
			Rectangle
			{
				gradient: Gradient {
					GradientStop { position: 0.0; color: "#f1f1f1" }
					GradientStop { position: 1.0; color: "#d9d7da" }
				}
				id: headerPaneContainer
				anchors.fill: parent
				StatusPane
				{
					anchors.fill: parent
					webPreview: webPreview
				}
			}
		}

		Rectangle {
			Layout.fillWidth: true
			height: 1
			color: "#8c8c8c"
		}

		Rectangle {
			Layout.fillWidth: true
			Layout.minimumHeight: root.height - headerView.height;

			Settings {
				id: splitSettings
				property alias projectWidth: projectList.width
				property alias contentViewWidth: codeWebSplitter.width
				property alias rightViewWidth: scenarioExe.width
			}

			WelcomeView
			{
				id: welcomeView
				anchors.fill: parent
				Layout.fillHeight: true
				Layout.fillWidth: true
				visible: projectModel.isEmpty
			}

			Splitter
			{
				anchors.fill: parent
				orientation: Qt.Horizontal
				id: mainPanels

				ProjectList
				{
					id: projectList
					Layout.minimumWidth: 200
					Layout.fillHeight: true
				}

				Splitter {
					id: codeWebSplitter
					Layout.fillHeight: true
					Layout.fillWidth: true
					orientation: Qt.Horizontal

					Connections
					{
						target: projectList
						onDocDoubleClicked:
						{
							codeEditor.openDocument(fileData)
							path.text = fileData.path
							projectModel.currentDocument = fileData
						}
					}

					Connections
					{
						target: codeEditor
						onCurrentDocumentIdChanged:
						{
							path.text = mainContent.codeEditor.currentDocumentId
						}
						onDocumentClosed:
						{
							path.text = ""
						}
					}

					Column
					{
						Layout.fillHeight: true
						Layout.fillWidth: true
						onHeightChanged:
						{
						}
						anchors.top: parent.top
						spacing: 0
						Rectangle
						{
							id: pathHeader
							WebPreviewStyle {
								id: webPreviewStyle
							}

							height: 38
							width: parent.width
							color: webPreviewStyle.general.headerBackgroundColor
							DefaultLabel
							{
								id: path
								anchors.centerIn: parent
							}
						}

						CodeEditorView
						{
							id: codeEditor
							height: parent.height - pathHeader.height
							width: parent.width
						}
					}

					WebPreview {
						id: webPreview
						Layout.fillWidth: codeWebSplitter.orientation === Qt.Vertical
						Layout.fillHeight: codeWebSplitter.orientation === Qt.Horizontal
						Layout.minimumHeight: 50
						Layout.minimumWidth: 50
					}
				}

				Connections
				{
					target: projectModel
					onProjectClosed:
					{
						if (debugPanel.visible)
							debugPanel.close()
						scenarioExe.clear()
					}
					Component.onCompleted: resetPanels()
					onIsEmptyChanged:
					{
						resetPanels();
					}
					function resetPanels()
					{
						if (projectModel.isEmpty)
						{
							scenarioExe.visible = false;
							webPreview.visible = false;
							projectList.visible = false;
							codeEditor.visible = false;
							mainPanels.visible = false;
							welcomeView.visible = true;
						}
						else
						{
							scenarioExe.visible = true;
							webPreview.visible = true;
							projectList.visible = true;
							codeEditor.visible = true;
							mainPanels.visible = true;
							welcomeView.visible = false;
						}
					}
				}

				ScenarioExecution
				{
					id: scenarioExe;
					visible: true;
					Layout.fillHeight: true
					Keys.onEscapePressed: visible = false
					width: scenarioMinWidth
					Layout.minimumWidth: scenarioMinWidth
					Layout.maximumWidth: scenarioMaxWidth
					anchors.right: parent.right
				}

				Debugger
				{
					id: debugPanel
					visible: false
					Layout.fillHeight: true
					Keys.onEscapePressed: visible = false
					width: scenarioMinWidth + 500
					Layout.minimumWidth: scenarioMinWidth
					Layout.maximumWidth: scenarioMaxWidth
					anchors.right: parent.right
					function close()
					{
						debugPanel.visible = false
						scenarioExe.visible = true
						scenarioExe.width = debugPanel.width
						scenarioExe.forceActiveFocus()
					}
				}

				Connections {
					target: clientModel
					onDebugDataReady:  {
						scenarioExe.visible = false
						debugPanel.visible = true
						debugPanel.width = scenarioExe.width
					}
				}

				Connections {
					target: debugPanel
					onPanelClosed:  {
						debugPanel.close()
					}
				}
			}
		}
	}
}
