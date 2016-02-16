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
/** @file CodeEditorView.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0

Item {
	id: codeEditorView
	property string currentDocumentId: ""
	property string sourceInError
	signal documentEdit(string documentId)
	signal breakpointsChanged(string documentId)
	signal isCleanChanged(var isClean, var document)
	signal loadComplete
	signal documentClosed(string path)

	onDocumentClosed:
	{
		if (path === currentDocumentId)
		{
			currentDocumentId = ""
			if (openedDocuments().length > 0)
				currentDocumentId = openedDocuments()[0].documentId
		}
	}

	function getDocumentText(documentId) {
		for (var i = 0; i < editorListModel.count; i++)	{
			if (editorListModel.get(i).documentId === documentId) {
				return editors.itemAt(i).item.getText();
			}
		}
		return "";
	}

	function getContracts()
	{
		var ctr = []
		for (var i = 0; i < editorListModel.count; i++)
		{
			if (editorListModel.get(i).isContract)
				ctr.push(editors.itemAt(i).item)
		}
		return ctr;
	}

	function isDocumentOpen(documentId) {
		for (var i = 0; i < editorListModel.count; i++)
			if (editorListModel.get(i).documentId === documentId &&
					editors.itemAt(i).item)
				return true;
		return false;
	}

	function openDocument(document)	{
		loadDocument(document);
		currentDocumentId = document.path;
		fileIo.watchFileChanged(currentDocumentId)
		for (var i = 0; i < editorListModel.count; i++)
			if (editorListModel.get(i).documentId === document.documentId)
			{
				editorListModel.get(i).opened = true
				break;
			}
	}

	function openedDocuments()
	{
		var ret = []
		for (var k = 0; k < editorListModel.count; k++)
		{
			if (editorListModel.get(k).opened)
				ret.push(editorListModel.get(k))
		}
		return ret
	}

	function closeDocument(path)
	{
		for (var k = 0; k < editorListModel.count; k++)
		{
			if (editorListModel.get(k).path === path)
			{
				if (editorListModel.count > k)
				{
					editorListModel.get(k).opened = false
					fileIo.stopWatching(path)
					documentClosed(path)
				}
				break;
			}
		}		
	}

	function displayOpenedDocument(index)
	{
		if (editorListModel.count > index)
			currentDocumentId = editorListModel.get(index).documentId
	}

	function loadDocument(document) {
		for (var i = 0; i < editorListModel.count; i++)
			if (editorListModel.get(i).documentId === document.documentId)
				return; //already opened

		editorListModel.append(document);
	}

	function doLoadDocument(editor, document, create) {
		var data = fileIo.readFile(document.path);
		if (create)
		{
			editor.onLoadComplete.connect(function() {
				codeEditorView.loadComplete();
			});
			editor.onEditorTextChanged.connect(function() {
				documentEdit(editor.document.documentId);
				if (editor.document.isContract)
					codeModel.registerCodeChange(editor.document.documentId, editor.getText());
			});
			editor.onBreakpointsChanged.connect(function() {
				if (editor.document.isContract)
					breakpointsChanged(editor.document.documentId);
			});
			editor.onIsCleanChanged.connect(function() {
				isCleanChanged(editor.isClean, editor.document);
			});
		}
		editor.document = document;
		if (document.isContract)
			codeModel.registerCodeChange(document.documentId, data);
		editor.setFontSize(editorSettings.fontSize);
		editor.sourceName = document.documentId;
		editor.setText(data, document.syntaxMode);
		editor.changeGeneration();
	}

	function getEditor(documentId) {
		for (var i = 0; i < editorListModel.count; i++)
		{
			if (editorListModel.get(i).documentId === documentId)
				return editors.itemAt(i).item;
		}
		return null;
	}

	function highlightExecution(documentId, location, gasUsed)
	{
		var editor = getEditor(documentId);
		if (editor)
		{
			if (documentId !== location.sourceName)
				findAndHightlight(location.start, location.end, location.sourceName)
			else
				editor.highlightExecution(location, gasUsed);
		}
	}

	function basicHighlight(documentId, start, end)
	{
		var editor = getEditor(documentId);
		if (editor)
			editor.basicHighlight(start, end);
	}

	// Execution is not in the current document. Try:
	// Open targeted document and hightlight (TODO) or
	// Warn user that file is not available
	function findAndHightlight(start, end, sourceName)
	{
		var editor = getEditor(currentDocumentId);
		if (editor)
			editor.showWarning(qsTr("Currently debugging in " + sourceName + ". Source not available."));
	}

	function setCursor(c, docId)
	{
		var editor = getEditor(docId);
		if (editor)
			editor.setCursor(c)
	}

	function editingContract() {
		for (var i = 0; i < editorListModel.count; i++)
			if (editorListModel.get(i).documentId === currentDocumentId)
				return editorListModel.get(i).isContract;
		return false;
	}

	function getBreakpoints() {
		var bpMap = {};
		for (var i = 0; i < editorListModel.count; i++)  {
			var documentId = editorListModel.get(i).documentId;
			var editor = editors.itemAt(i).item;
			if (editor) {
				bpMap[documentId] = editor.getBreakpoints();
			}
		}
		return bpMap;
	}

	function toggleBreakpoint() {
		var editor = getEditor(currentDocumentId);
		if (editor)
			editor.toggleBreakpoint();
	}

	function resetEditStatus(document) {
		var editor = getEditor(document.documentId);
		if (editor)
			editor.changeGeneration();
	}

	function goToCompilationError() {
		if (sourceInError === "")
			return;
		if (currentDocumentId !== sourceInError)
			projectModel.openDocument(sourceInError);
		for (var i = 0; i < editorListModel.count; i++)
		{
			var doc = editorListModel.get(i);
			if (doc.isContract && doc.documentId === sourceInError)
			{
				var editor = editors.itemAt(i).item;
				if (editor)
					editor.goToCompilationError();
				break;
			}
		}
	}

	function setFontSize(size) {
		if (size <= 10 || size >= 48)
			return;
		editorSettings.fontSize = size;
		for (var i = 0; i < editors.count; i++)
			editors.itemAt(i).item.setFontSize(size);
	}

	function displayGasEstimation(checked)
	{
		var editor = getEditor(currentDocumentId);
		if (editor)
			editor.displayGasEstimation(checked);
	}

	Component.onCompleted: projectModel.codeEditor = codeEditorView;

	Connections {
		target: codeModel
		onCompilationError: {
			sourceInError = _firstErrorLoc.source;
		}
		onCompilationComplete: {
			sourceInError = "";
			var gasCosts = codeModel.gasCostByDocumentId(currentDocumentId);
			var editor = getEditor(currentDocumentId);
			if (editor)
				editor.setGasCosts(gasCosts);
		}
	}

	Connections {
		target: projectModel
		onDocumentOpened: {
			openDocument(document);
		}

		onProjectSaved: {
			if (projectModel.appIsClosing || projectModel.projectIsClosing)
				return;
			for (var i = 0; i < editorListModel.count; i++)
			{
				var doc = editorListModel.get(i);
				resetEditStatus(doc.documentId);
			}
		}

		onProjectClosed: {
			currentDocumentId = "";
			editorListModel.clear()
		}

		onDocumentSaved: {
			resetEditStatus(document);
		}

		onContractSaved: {
			resetEditStatus(document);
		}

		onDocumentSaving: {
			for (var i = 0; i < editorListModel.count; i++)
			{
				var doc = editorListModel.get(i);
				if (doc.path === document.path)
				{
					fileIo.writeFile(document.path, editors.itemAt(i).item.getText());
					break;
				}
			}
		}
	}

	MessageDialog
	{
		id: messageDialog
		title: qsTr("File Changed")
		text: qsTr("This file has been changed outside of the editor. Do you want to reload it?")
		standardButtons: StandardButton.Yes | StandardButton.No
		property variant item
		property variant doc
		onYes: {
			doLoadDocument(item, doc, false);
			resetEditStatus(doc.documentId);
		}
	}

	Rectangle
	{
		anchors.fill: parent
		color: "#ededed"
	}

	Repeater {
		id: editors
		model: editorListModel
		delegate: Loader {
			id: loader
			active: false
			asynchronous: true
			anchors.fill:  parent
			source: appService.haveWebEngine ? "WebCodeEditor.qml" : "CodeEditor.qml"
			visible: (index >= 0 && index < editorListModel.count && currentDocumentId === editorListModel.get(index).documentId)
			property bool changed: false
			onVisibleChanged: {
				loadIfNotLoaded()
				if (visible && item)
				{
					loader.item.setFocus();
					if (changed)
					{
						changed = false;
						messageDialog.item = loader.item;
						messageDialog.doc = editorListModel.get(index);
						messageDialog.open();
					}
					loader.item.displayGasEstimation(gasEstimationAction.checked);
				}
			}
			Component.onCompleted: {
				loadIfNotLoaded()
			}
			onLoaded: {
				doLoadDocument(loader.item, editorListModel.get(index), true)
				loadComplete()
			}

			Connections
			{
				target: projectModel
				onDocumentChanged: {
					if (!item)
						return;
					var current = editorListModel.get(index);
					if (path === current.path)
					{
						if (currentDocumentId === current.documentId)
						{
							messageDialog.item = loader.item;
							messageDialog.doc = editorListModel.get(index);
							messageDialog.open();
						}
						else
							changed = true
					}
				}

				onDocumentRemoved: {
					for (var i = 0; i < editorListModel.count; i++)
						if (editorListModel.get(i).documentId === documentId)
						{
							editorListModel.remove(i);
							break;
						}
				}
			}

			function loadIfNotLoaded () {
				if (visible && !active) {
					active = true;
				}
			}
		}
	}
	ListModel {
		id: editorListModel
	}

	Action {
		id: increaseFontSize
		text: qsTr("Increase Font Size")
		shortcut: "Ctrl+="
		onTriggered: setFontSize(editorSettings.fontSize + 1)
	}

	Action {
		id: decreaseFontSize
		text: qsTr("Decrease Font Size")
		shortcut: "Ctrl+-"
		onTriggered: setFontSize(editorSettings.fontSize - 1)
	}

	Settings {
		id: editorSettings
		property int fontSize: 12;
	}
}
