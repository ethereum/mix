import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtWebEngine 1.0
import QtWebEngine.experimental 1.0
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

	function setPreviewUrl(url) {
		if (buildingScenario)
			return
		if (!initialized)
			pendingPageUrl = url;
		else {
			pendingPageUrl = "";
			updateContract();
			webView.runJavaScript("loadPage(\"" + url + "\")");
		}
	}

	function reload() {
		if (initialized) {
			updateContract();
			//webView.runJavaScript("reloadPage()");
			setPreviewUrl(urlInput.text);
		}
	}

	function updateContract() {
		var contracts = {};

		for (var c in clientModel.contractAddresses)
		{
			var address = clientModel.contractAddresses[c];
			var name = TransactionHelper.contractFromToken(c)
			var contract = codeModel.contracts[name];
			contracts[c] = {
				name: contract.contract.name,
				address: address,
				interface: JSON.parse(contract.contractInterface),
			};
		}
		webView.runJavaScript("updateContracts(" + JSON.stringify(contracts) + ")");
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

		onDocumentAdded: {
			var document = projectModel.getDocument(documentId)
			if (document.isHtml)
				pageListModel.append(document);
		}
		onDocumentRemoved: {
			updateDocument(documentId, function(i) { pageListModel.remove(i) } )
		}

		onDocumentUpdated: {
			var document = projectModel.getDocument(documentId);
			for (var i = 0; i < pageListModel.count; i++)
				if (pageListModel.get(i).documentId === documentId)
				{
					pageListModel.set(i, document);
					break;
				}
		}

		onProjectLoading: {
			for (var i = 0; i < target.listModel.count; i++) {
				var document = target.listModel.get(i);
				if (document.isHtml) {
					pageListModel.append(document);
					if (pageListModel.count === 1) //first page added
					{
						urlInput.text = httpServer.url + "/" + document.documentId;
						setPreviewUrl(httpServer.url + "/" + document.documentId);
					}
				}
			}
		}

		onDocumentSaved:
		{
			if (!projectModel.getDocument(documentId).isContract)
				reloadOnSave();
		}

		onProjectClosed: {
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
				var documentName = urlPath.substr(urlPath.lastIndexOf("/") + 1);
				var documentId = projectModel.getDocumentIdByName(documentName);
				var content = "";
				if (projectModel.codeEditor.isDocumentOpen(documentId))
					content = projectModel.codeEditor.getDocumentText(documentId);
				else
				{
					var doc = projectModel.getDocument(documentId);
					if (doc)
						content = fileIo.readFile(doc.path);
				}

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
			Layout.preferredHeight: 32
			Row {
				anchors.top: parent.top
				anchors.fill: parent
				anchors.leftMargin: 3
				spacing: 10

				DefaultTextField
				{
					id: urlInput
					anchors.verticalCenter: parent.verticalCenter
					width: 300
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

				Rectangle {
					width: 23
					height: 23
					anchors.verticalCenter: parent.verticalCenter
					ScenarioButton {
						id: reloadFrontend
						text: qsTr("Reload frontend")
						width: 23
						height: 23
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
							reloadFrontend.startBlinking()
						firstLoad = false
					}
					onSetupStarted:
					{
						buildingScenario = true
					}
				}

				CheckBox {
					id: autoReloadOnSave
					checked: true
					height: 21
					anchors.verticalCenter: parent.verticalCenter
					style: CheckBoxStyle {
						label: DefaultLabel {
							text: qsTr("Auto reload on save")
						}
					}
					focus: true
				}

				DefaultImgButton
				{
					height: 25
					width: 25
					anchors.verticalCenter: parent.verticalCenter
					action: expressionAction
					iconSource: "qrc:/qml/img/console.png"
					tooltip: qsTr("JS console")
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
			Layout.preferredHeight: 1
			Layout.preferredWidth: parent.width
			color: webPreviewStyle.general.separatorColor
		}

		Splitter
		{
			Layout.preferredWidth: parent.width
			Layout.fillHeight: true
			orientation: codeWebSplitter.orientation === Qt.Horizontal ? Qt.Vertical : Qt.Horizontal
			WebEngineView {
				Layout.fillHeight: true
				width: parent.width
				Layout.preferredWidth: parent.width
				id: webView
				onJavaScriptConsoleMessage: {
					console.log(sourceID + ":" + lineNumber + ": " + message);
					webPreview.javaScriptMessage(level, sourceID, lineNumber - 1, message);
				}
				onLoadingChanged: {
					if (!loading) {
						initialized = true;
						webView.runJavaScript("init(\"" + httpServer.url + "/rpc/\")");
						if (pendingPageUrl)
							setPreviewUrl(pendingPageUrl);
						ready();
						if (LoadStatus === LoadSucceededStatus)
							webView.runJavaScript("setDefaultAccount()")
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
					updateView()
				}

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
					if (expressionPanel.visible)
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
						height: 23
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
						anchors.rightMargin: 1
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


