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
/** @file WebCodeEditor.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1
import QtWebEngine 1.0
import QtWebEngine.experimental 1.0
import org.ethereum.qml.Clipboard 1.0
import "js/ErrorLocationFormater.js" as ErrorLocationFormater

Item {
	signal breakpointsChanged
	signal editorTextChanged
	signal loadComplete
	property bool isClean: true
	property string currentText: ""
	property string currentMode: ""
	property bool initialized: false
	property bool unloaded: false
	property var currentBreakpoints: []
	property string sourceName
	property var document
	property int fontSize: 0
	property int c_max_open_filesize: 5120000

	function setText(text, mode) {
		currentText = text;
		if (mode !== undefined)
			currentMode = mode;
		if (initialized && editorBrowser) {
			editorBrowser.runJavaScript("setTextBase64(\"" + Qt.btoa(text) + "\")");
			editorBrowser.runJavaScript("setMode(\"" + currentMode + "\")");
		}
		setFocus();
	}

	function setFocus() {
		if (editorBrowser)
			editorBrowser.forceActiveFocus();
	}

	function getText() {
		return currentText;
	}

	function syncClipboard() {
		if (Qt.platform.os == "osx" && editorBrowser) {
			var text = clipboard.text;
			editorBrowser.runJavaScript("setClipboardBase64(\"" + Qt.btoa(text) + "\")");
		}
	}

	function highlightExecution(location, gasUsed) {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("highlightExecution(" + location.start + "," + location.end + ", " + gasUsed +")");
	}

	function basicHighlight(start, end)
	{
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("basicHighlight(" + start + "," + end + ")");
	}

	function setCursor(ch)
	{
		if (initialized && editorBrowser)
		{
			setFocus()
			editorBrowser.runJavaScript("setCursor('" + ch + "')");
		}
	}

	function showWarning(content) {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("showWarning('" + content + "')");
	}

	function getBreakpoints() {
		return currentBreakpoints;
	}

	function toggleBreakpoint() {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("toggleBreakpoint()");
	}

	function changeGeneration() {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("changeGeneration()", function(result) {});
	}

	function goToCompilationError() {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("goToCompilationError()", function(result) {});
	}

	function setFontSize(size) {
		fontSize = size;
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("setFontSize(" + size + ")", function(result) {});
	}

	function setGasCosts(gasCosts) {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("setGasCosts('" + JSON.stringify(gasCosts) + "')", function(result) {});
	}

	function displayGasEstimation(show) {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("displayGasEstimation('" + show + "')", function(result) {});
	}

	function setReadOnly(status) {
		if (initialized && editorBrowser)
			editorBrowser.runJavaScript("setReadOnly('" + status + "')", function(result) {});
	}

	Clipboard
	{
		id: clipboard
	}

	Connections {
		target: clipboard
		onClipboardChanged:	syncClipboard()
	}

	anchors.top: parent.top
	id: codeEditorView
	anchors.fill: parent
	WebEngineView {
		id: editorBrowser
		url: "qrc:///qml/html/codeeditor.html"
		anchors.fill: parent
		Component.onCompleted:
		{
			if (experimental.settings)
				experimental.settings.javascriptCanAccessClipboard = true
			else if (settings)
				settings.javascriptCanAccessClipboard = true
		}
		onJavaScriptConsoleMessage:  {
			console.log("editor: " + sourceID + ":" + lineNumber + ":" + message);
		}

		Component.onDestruction:
		{
			codeModel.onCompilationComplete.disconnect(compilationComplete);
			codeModel.onCompilationError.disconnect(compilationError);
		}

		onLoadingChanged:
		{
			if (!loading && editorBrowser) {
				initialized = true;
				setFontSize(fontSize);

				var size = fileIo.getFileSize(document.path);
				if (size > c_max_open_filesize)
				{
					setText("File size is too large!", currentMode);
					setReadOnly(true);
				}
				else
				if (!fileIo.isFileText(document.path))
				{
					setText("Can't read binary file!", currentMode);
					setReadOnly(true);
				}
				else 
					setText(currentText, currentMode);
					
				runJavaScript("getTextChanged()", function(result) { });
				pollTimer.running = true;
				syncClipboard();
				if (currentMode === "solidity")
				{
					codeModel.onCompilationComplete.connect(compilationComplete);
					codeModel.onCompilationError.connect(compilationError);
				}
				parent.changeGeneration();
				loadComplete();
			}
		}


		function compilationComplete()
		{
			if (editorBrowser && currentText !== "")
			{
				editorBrowser.runJavaScript("compilationComplete()", function(result) { });
				parent.displayGasEstimation(gasEstimationAction.checked);
			}
		}

		function compilationError(error, firstLocation, secondLocations)
		{
			if (!editorBrowser || !error)
				return;
			var detail = error.split('\n')[0];
			var reg = detail.match(/:\d+:\d+:/g);
			if (reg !== null)
				detail = detail.replace(reg[0], "");
			displayErrorAnnotations(detail, firstLocation, secondLocations);
		}

		function displayErrorAnnotations(detail, location, secondaryErrors)
		{
			editorBrowser.runJavaScript("compilationError('" + sourceName + "', '" + JSON.stringify(location).replace(/'/g, ' ') + "', '" + detail.replace(/'/g, ' ') + "', '" + JSON.stringify(secondaryErrors).replace(/'/g, ' ') + "')", function(result){});
		}

		Timer
		{
			id: pollTimer
			interval: 30
			running: false
			repeat: true
			onTriggered: {
				if (!editorBrowser)
					return;
				editorBrowser.runJavaScript("getTextChanged()", function(result) {
					if (result === true && editorBrowser) {
						editorBrowser.runJavaScript("getText()" , function(textValue) {
							currentText = textValue;
							editorTextChanged();
						});
					}
				});
				editorBrowser.runJavaScript("getBreakpointsChanged()", function(result) {
					if (result === true && editorBrowser) {
						editorBrowser.runJavaScript("getBreakpoints()" , function(bp) {
							if (currentBreakpoints !== bp) {
								currentBreakpoints = bp;
								breakpointsChanged();
							}
						});
					}
				});
				editorBrowser.runJavaScript("isClean()", function(result) {
					isClean = result;
				});
			}
		}
	}
}
