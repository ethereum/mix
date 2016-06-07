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
/** @file ProjectModel.qml
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
import "js/ProjectModel.js" as ProjectModelCode
import "js/NetworkDeployment.js" as NetworkDeploymentCode

Item {
	id: projectModel

	signal projectClosed
	signal projectLoading(var projectData)
	signal projectLoaded()
	signal documentSaving(var document)
	signal documentChanged(var path)
	signal documentOpened(var document)
	signal documentRemoved(var documentId)
	signal documentAdded(var documentId)
	signal projectSaving()
	signal projectFileSaving(var projectData)
	signal projectSaved()
	signal projectFileSaved()
	signal newProject(var projectData)
	signal documentSaved(var document)
	signal contractSaved(var document)
	signal deploymentStarted()
	signal deploymentStepChanged(string message)
	signal deploymentComplete()
	signal deploymentError(string error)
	signal isCleanChanged(var isClean, var document)
	signal contractSelected(var _contractIndex)
	signal folderAdded(string path)

	property bool isEmpty: (projectPath === "")
	readonly property string projectFileName: ".mix"

	property bool appIsClosing: false
	property bool projectIsClosing: false
	property string projectPath: ""
	property string projectTitle: ""
	property var deploymentAddresses: ({})
	property string deploymentDir
	property var listModel: projectListModel
	property var stateListModel: projectStateListModel.model
	property alias stateDialog: projectStateListModel.stateDialog
	property CodeEditorView codeEditor: null
	property var unsavedFiles: []
	property alias newProjectDialog: newProjectDialog
	property int deployedScenarioIndex
	property string applicationUrlEth
	property string applicationUrlHttp
	property string deployBlockNumber
	property var deploymentTrHashes
	property string registerContentHashTrHash
	property string registerUrlTrHash
	property int registerContentHashBlockNumber: -1
	property int registerUrlBlockNumber: -1
	property alias deploymentDialog: deploymentDialog
	property variant filesMap: ({})
	property variant filesPath: ({})
	property variant currentDocument
	property string currentFolder
	property string startUrl
	property string compilationFolder: projectPath + "/package/compilation"

	//interface
	function saveAll() { ProjectModelCode.saveAll(); }
	function saveCurrentDocument() { ProjectModelCode.saveCurrentDocument(); }
	function saveDocument(doc) { ProjectModelCode.saveDocument(doc); }
	function createProject() { ProjectModelCode.createProject(); }
	function closeProject(callBack) { ProjectModelCode.closeProject(callBack); }
	function saveProject() { ProjectModelCode.saveProject(); }
	function saveProjectFile() { ProjectModelCode.saveProjectFile(); }
	function loadProject(path) { ProjectModelCode.loadProject(path); }
	function newHtmlFile() { ProjectModelCode.newHtmlFile(); }
	function newJsFile() { ProjectModelCode.newJsFile(); }
	function newCssFile() { ProjectModelCode.newCssFile(); }
	function newContract() { ProjectModelCode.newContract(); }
	function newFolder() { newFolderDialog.open() }
	function deployProject() { NetworkDeploymentCode.deployProject(false); }
	function registerToUrlHint(url, gasPrice, callback) { NetworkDeploymentCode.registerToUrlHint(url, gasPrice, callback) }
	function formatAppUrl() { NetworkDeploymentCode.formatAppUrl(url); }
	function saveDocuments(onlyContracts) { ProjectModelCode.saveDocuments(onlyContracts) }
	function file(docData) { return ProjectModelCode.file(docData) }
	function saveProjectProperty(key, value) { return ProjectModelCode.saveProjectProperty(key, value) }
	function saveContractCompilationResult(documentId) { ProjectModelCode.saveContractCompilationResult(documentId) }
	function regenerateCompilationResult() { ProjectModelCode.regenerateCompilationResult() }

	function cleanDeploymentStatus()
	{
		deployedScenarioIndex = 0
		deployBlockNumber = ""
		deploymentTrHashes = {}
		deploymentAddresses = {}
		deploymentDir = ""
		deploymentDialog.packageStep.packageDir = ""
		deploymentDialog.packageStep.lastPackageDate = ""
		deploymentDialog.packageStep.localPackageUrl = ""
		saveProject()
		cleanRegisteringStatus()
	}

	function cleanRegisteringStatus()
	{
		applicationUrlEth = ""
		applicationUrlHttp = ""
		registerContentHashTrHash = ""
		registerUrlTrHash = ""
		registerContentHashBlockNumber = -1
		registerUrlBlockNumber = -1
		saveProject()
	}

	Connections {
		target: mainApplication
		onLoaded: {
			if (mainApplication.trackLastProject && projectSettings.lastProjectPath && projectSettings.lastProjectPath !== "")
				projectModel.loadProject(projectSettings.lastProjectPath)
		}
	}

	Connections {
		target: codeEditor
		onIsCleanChanged: {
			for (var i in unsavedFiles)
			{
				if (unsavedFiles[i].path === document.path && isClean)
					unsavedFiles.splice(i, 1);
			}
			if (!isClean)
				unsavedFiles.push(document);
			isCleanChanged(isClean, document);
		}
	}

	NewFolderDialog
	{
		id: newFolderDialog
		visible: false
		onAccepted: {
			if (!fileIo.dirExists(newFolderDialog.path))
			{
				if (fileIo.makeDir(newFolderDialog.path))
					folderAdded(newFolderDialog.path)
				else
					alertMessageDialog.pop(qsTr("Error while creating folder"))
			}
			else
				alertMessageDialog.pop(qsTr("Directory already exists"))
		}
	}

	NewProjectDialog {
		id: newProjectDialog
		visible: false
		onAccepted: {
			var title = newProjectDialog.projectTitle;
			var path = newProjectDialog.projectPath;
			ProjectModelCode.doCreateProject(title, path);
		}
	}

	Connections
	{
		target: fileIo
		property bool saving: false
		onFileChanged:
		{
			documentChanged(_filePath);
		}
	}

	MessageDialog {
		id: saveMessageDialog
		title: qsTr("Project")
		text: qsTr("Some files require to be saved. Do you want to save changes?");
		standardButtons: StandardButton.Yes | StandardButton.No | StandardButton.Cancel
		icon: StandardIcon.Question
		property var callBack;
		onYes: {
			projectIsClosing = true;
			projectModel.saveAll();
			unsavedFiles = [];
			ProjectModelCode.doCloseProject();
			if (callBack)
				callBack();
		}
		onRejected: {}
		onNo: {
			projectIsClosing = true;
			unsavedFiles = [];
			ProjectModelCode.doCloseProject();
			if (callBack)
				callBack();
		}
	}

	MessageDialog {
		id: deployWarningDialog
		title: qsTr("Project")
		text:
		{
			if (Object.keys(projectModel.deploymentAddresses).length > 0)
				return qsTr("This project has been already deployed to the network. Do you want to redeploy it? (Contract state will be reset)")
			else
				return qsTr("This action will deploy to the network. Do you want to deploy it?")
		}
		icon: StandardIcon.Question
		standardButtons: StandardButton.Ok | StandardButton.Abort
		onAccepted: {
			NetworkDeploymentCode.startDeployProject(true);
		}
	}

	MessageDialog {
		id: deployResourcesDialog
		title: qsTr("Project")
		standardButtons: StandardButton.Ok
	}

	DeploymentDialog
	{
		id: deploymentDialog
	}

	ListModel {
		id: projectListModel
	}

	StateListModel {
		id: projectStateListModel
	}

	Connections
	{
		target: projectModel
		onProjectClosed: {
			projectPath = "";
		}
	}

	Settings {
		id: projectSettings
		property string lastProjectPath;
	}
}
