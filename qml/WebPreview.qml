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
/** @file webPreview.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtWebEngine 1.0
import QtWebEngine.experimental 1.0
import Qt.labs.settings 1.0
import HttpServer 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/QEtherHelper.js" as QEtherHelper
import "."

Item {
	id: webPreview
	property string pendingPageUrl: ""
	property bool initialized: false
	property alias urlInput: urlInput
	property alias webView: webView
	property string webContent; //for testing
	signal javaScriptMessage(var _level, string _sourceId, var _lineNb, string _content)
	signal webContentReady
	signal ready
	property bool buildingScenario

	function relativePath()
	{
		return urlInput.text.replace(httpServer.url, "")
	}

	function setPreviewUrl(url) {
		if (buildingScenario)
			return
		if (!initialized)
			pendingPageUrl = url;
		else {
			pendingPageUrl = "";
			webView.runJavaScript("loadPage(\"" + url + "\")");
			updateContract();
		}
		projectModel.saveProjectProperty("startUrl", relativePath())
	}

	function reload() {
		if (initialized) {
			//webView.runJavaScript("reloadPage()");
			setPreviewUrl(urlInput.text);
			updateContract();
		}
	}

	function updateContract() {
		if (!initialized)
			return
		var contracts = {};
		for (var c in clientModel.contractAddresses)
		{
			var address = clientModel.contractAddresses[c];
			var name = TransactionHelper.contractFromToken(c)
			var contract = codeModel.contracts[name];
			if (contract)
			{
				contracts[c] = {
					name: contract.contract.name,
					address: address,
					interface: JSON.parse(contract.contractInterface),
				};
			}
		}
		webView.runJavaScript("updateContracts(" + JSON.stringify(contracts) + ")")
	}

	function reloadOnSave() {
		if (autoReloadOnSave.checked)
			reload();
	}

	function updateDocument(documentId, action) {
		for (var i = 0; i < pageListModel.count; i++)
			if (pageListModel.get(i).documentId === documentId)
				action(i);
	}

	function getContent() {
		webView.runJavaScript("getContent()", function(result) {
			webContent = result;
			webContentReady();
		});
	}

	function changePage() {
		setPreviewUrl(urlInput.text);
	}

	WebPreviewStyle {
		id: webPreviewStyle
	}

	Connections {
		target: mainApplication
		onLoaded: {
			//We need to load the container using file scheme so that web security would allow loading local files in iframe
			var containerPage = fileIo.readFile("qrc:///qml/html/WebContainer.html")
			webView.loadHtml(containerPage, httpServer.url + "/WebContainer.html")
		}
	}

	Connections {
		target: projectModel

		onProjectLoading:
		{
			var url = httpServer.url + "/index.html"
			if (projectData.startUrl)
				url = httpServer.url + projectData.startUrl
			urlInput.text = url
			pendingPageUrl = url;
		}

		onDocumentSaved:
		{
			if (!document.isContract)
				reloadOnSave();
		}

		onProjectClosed:
		{
			pageListModel.clear();
			webPreview.setPreviewUrl("")
			urlInput.text = ""
		}
	}

	ListModel {
		id: pageListModel
	}

	HttpServer {
		id: httpServer
		listen: true
		accept: true
		onClientConnected: {
			var urlPath = _request.url.toString();
			if (urlPath.indexOf("/rpc/") === 0)
			{
				//jsonrpc request
				//filter polling requests //TODO: do it properly
				var log = _request.content.indexOf("eth_changed") < 0;
				if (log)
					console.log(_request.content);
				var response = clientModel.apiCall(_request.content);
				if (log)
					console.log(response);
				_request.setResponse(response);
			}
			else
			{
				//document request
				if (urlPath === "/")
					urlPath = "/index.html";
				var filePath = projectModel.projectPath + "/" + urlPath.replace(httpServer.url, "")
				var content = fileIo.readFile(filePath)
				var accept = _request.headers["accept"];
				if (accept && accept.indexOf("text/html") >= 0 && !_request.headers["http_x_requested_with"])
				{
					//navigate to page request, inject deployment script
					content = "<script>web3=parent.web3;BigNumber=parent.BigNumber;contracts=parent.contracts;ctrAddresses=parent.ctrAddresses;</script>\n" + content;
					_request.setResponseContentType("text/html");
				}
				_request.setResponse(content);
			}
		}
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 0
		Rectangle
		{
			anchors.leftMargin: 4
			color: webPreviewStyle.general.headerBackgroundColor
			Layout.preferredWidth: parent.width
			Layout.minimumHeight: 38
			id: rowBtn

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
						rowBtn.Layout.minimumHeight = 38
						rowBtn.height = 38
					}
					else
					{
						rowBtn.Layout.minimumHeight = 38 + appSettings.systemPointSize
						rowBtn.height = 38 + appSettings.systemPointSize
					}
				}
			}

			Row {
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: 8
				anchors.left: parent.left
				spacing: 10

				ScenarioButton {
					id: reloadFrontend
					text: qsTr("Reload frontend")
					height: 24
					width: 24
					anchors.verticalCenter: parent.verticalCenter
					roundLeft: true
					roundRight: true
					onClicked:
					{
						reload()
					}
					buttonShortcut: ""
					sourceImg: "qrc:/qml/img/recycleicon@2x.png"
					function reload()
					{
						mainContent.webView.reload()
						reloadFrontend.stopBlinking()
					}
				}

				DefaultTextField
				{
					id: urlInput
					anchors.verticalCenter: parent.verticalCenter
					width: codeWebSplitter.orientation === Qt.Horizontal ? 250 : 300
					Keys.onEnterPressed:
					{
						setPreviewUrl(text);
					}
					Keys.onReturnPressed:
					{
						setPreviewUrl(text);
					}
					focus: true
				}

				Action {
					tooltip: qsTr("Reload")
					id: buttonReloadAction
					onTriggered: {
						reload();
					}
				}



				Connections
				{
					target: projectModel
					onProjectClosed:
					{
						clientConnection.firstLoad = true
					}
				}

				Connections
				{
					id: clientConnection
					target: clientModel
					property bool firstLoad: true
					onSetupFinished:
					{
						buildingScenario = false
						if (firstLoad)
							reloadFrontend.reload()
						else
							updateContract()
						firstLoad = false
					}
					onSetupStarted:
					{
						if (initialized)
							webView.runJavaScript("resetWeb3()")
						buildingScenario = true
					}
					onNewRecord:
					{
						updateContract()
					}
				}

				CheckBox {
					id: autoReloadOnSave
					checked: true
					anchors.verticalCenter: parent.verticalCenter
					style: CheckBoxStyle {
						indicator: Rectangle {
							implicitWidth: 22
							implicitHeight: 22
							radius: 3
							border.color: control.activeFocus ? "darkblue" : "gray"
							border.width: 1
							Rectangle {
								visible: control.checked
								color: "#5391d8"
								radius: 1
								anchors.margins: 4
								anchors.fill: parent
							}
						}
						label: DefaultLabel {
							text: qsTr("Auto reload on save")
						}
					}
					focus: true
				}

				DefaultImgButton
				{
					height: 28
					width: 28
					anchors.verticalCenter: parent.verticalCenter
					action: expressionAction
					iconSource: "qrc:/qml/img/console.png"
					tooltip: qsTr("JS console")
					Settings {
						id: jsButtonSettings
						property bool jsConsoleVisibility: expressionPanel.visible
					}
					Connections {
						target: mainContent
						onWebPreviewOrientationChanged: { expressionPanel.updateView() }
					}
				}

				Action {
					id: expressionAction
					tooltip: qsTr("Expressions")
					onTriggered:
					{
						expressionPanel.visible = !expressionPanel.visible;
						expressionPanel.updateView()
						if (expressionPanel.visible)
							expressionInput.forceActiveFocus();

					}
				}
			}
		}

		Rectangle
		{
			Layout.minimumHeight: 1
			Layout.preferredWidth: parent.width
			color: webPreviewStyle.general.separatorColor
		}

		Splitter
		{
			onWidthChanged:
			{
				expressionPanel.updateView()
			}
			Layout.preferredWidth: parent.width
			Layout.fillHeight: true
			orientation: codeWebSplitter.orientation === Qt.Horizontal ? Qt.Vertical : Qt.Horizontal
			WebEngineView {
				Layout.fillHeight: true
				width: parent.width
				Layout.preferredWidth: parent.width
				id: webView
				onJavaScriptConsoleMessage: {
					if (message === "Synchronous XMLHttpRequest on the main thread is deprecated because of its detrimental effects to the end user's experience. For more help, check http://xhr.spec.whatwg.org/.") // avoid this warning to be displayed
						return
					webPreview.javaScriptMessage(level, sourceID, lineNumber - 1, message);
				}
				onLoadingChanged: {
					if (!loading) {
						initialized = true;
						webView.runJavaScript("init(\"" + httpServer.url + "/rpc/\")", function() {
							if (pendingPageUrl)
								setPreviewUrl(pendingPageUrl);
							ready();
						});
					}
				}
			}

			Column {
				id: expressionPanel
				width: 350
				Layout.minimumWidth: 350
				Layout.minimumHeight: 350
				spacing: 0
				Component.onCompleted: {
					visible = jsButtonSettings.jsConsoleVisibility
					updateView()
				}
				onVisibleChanged: { if (visible) updateView() }

				function addExpression()
				{
					if (expressionInput.text === "")
						return;
					expressionInput.history.unshift(expressionInput.text);
					expressionInput.index = -1;
					webView.runJavaScript("executeJavaScript(\"" + expressionInput.text.replace(/"/g, '\\"') + "\")", function(result) {
						resultTextArea.text = "> " + expressionInput.text + "\n\t" + result + "\n" + resultTextArea.text;
						expressionInput.text = "";
					});
				}

				function updateView()
				{
					if (expressionPanel.visible && mainContent.webViewHorizontal)
						webView.width = webView.parent.width - 350
					else
						webView.width = webView.parent.width
				}

				Row
				{
					id: rowConsole
					width: parent.width
					DefaultImgButton
					{
						anchors.verticalCenter: parent.verticalCenter
						height: 22
						width: 22
						action: clearAction
						iconSource: "qrc:/qml/img/cleariconactive.png"
					}

					Action {
						id: clearAction
						enabled: resultTextArea.text !== ""
						tooltip: qsTr("Clear")
						onTriggered: {
							resultTextArea.text = "";
						}
					}

					DefaultTextField {
						id: expressionInput
						width: parent.width - 15
						font.family: webPreviewStyle.general.fontName
						font.italic: true
						anchors.verticalCenter: parent.verticalCenter
						property bool active: false
						property var history: []
						property int index: -1
						property string textLabel: qsTr("Enter JavaScript Expression")
						text: textLabel

						function displayCache(incr)
						{
							index = index + incr;
							if (history.length - 1 < index || index < 0)
							{
								if (incr === 1)
									index = 0;
								else
									index = history.length - 1;
							}
							expressionInput.text = history[index];
						}

						onTextChanged: {
							active = text !== "";
							if (!active)
								index = -1;
						}

						Keys.onDownPressed: {
							if (active)
								displayCache(-1);
						}

						Keys.onUpPressed: {
							displayCache(1);
							active = true;
						}

						Keys.onEnterPressed:
						{
							expressionPanel.addExpression();
						}

						Keys.onReturnPressed:
						{
							expressionPanel.addExpression();
						}

						onFocusChanged:
						{
							if (!focus && text == "")
								text = textLabel
							if (focus && text === textLabel)
								text = "";
						}

						style: TextFieldStyle {
							background: Rectangle {
								color: "transparent"
							}
						}
					}
				}

				DefaultTextArea {

					Image {
						anchors.top: parent.top
						anchors.topMargin: 1
						anchors.rightMargin: 10
						anchors.right: parent.right
						source: "qrc:/qml/img/javascript_logo.png"
						height: 25
						width: 25
						fillMode: Image.PreserveAspectFit
					}

					Layout.fillHeight: true
					height: parent.height - rowConsole.height
					readOnly: true
					id: resultTextArea
					width: expressionPanel.width
					wrapMode: Text.Wrap
					textFormat: Text.RichText
					font.family: webPreviewStyle.general.fontName
					backgroundVisible: true
					style: TextAreaStyle {
						backgroundColor: "#f0f0f0"
					}
				}
			}
		}
	}
}


