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
/** @file ProjectModel.js
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

var basicContractTemplate = "contract FirstContract {}"
var htmlTemplate = "<!doctype>\n" +
		"<html>\n" +
		"<head>\n" +
		"<script type='text/javascript'>\n" +
		"\n" +
		"function get() {\n" +
		"\tvar param = document.getElementById('query').value;\n" +
		"\tvar res = contracts['Sample'].contract.get();\n" +
		"\tdocument.getElementById('queryres').innerText = res;\n" +
		"}\n" +
		"\n" +
		"function set() {\n" +
		"\tvar key = document.getElementById('key').value;\n" +
		"\tvar res = contracts['Sample'].contract.set(key);\n" +
		"}\n" +
		"\n" +
		"</script>\n" +
		"</head>\n" +
		"<body bgcolor='#E6E6FA'>\n" +
		"\t<h3>Sample Ratings</h3>\n" +
		"<div>\n" +
		"Store:\n" +
		"\t<input type='number' id='key'>\n" +
		"\t<button onclick='set()'>Save</button>\n" +
		"</div>\n" +
		"<div>\n" +
		"Query:\n" +
		"\t<input value='get' type='button' id='query' onclick='get()' />\n" +
		"\t<div id='queryres'></div>\n" +
		"</div>\n" +
		"</body>\n" +
		"</html>\n";

var contractTemplate = "//Sample contract\n" +
		"contract Sample\n" +
		"{\n" +
		"\tuint value;\n" +
		"\tfunction Sample(uint v) {\n" +
		"\t\tvalue = v;\n" +
		"\t}\n" +
		"\tfunction set(uint v) {\n" +
		"\t\tvalue = v;\n" +
		"\t}\n" +
		"\tfunction get() constant returns (uint) {\n" +
		"\t\treturn value;\n" +
		"\t}\n" +
		"}\n";


function saveDocument(doc)
{
	documentSaving(doc);
	if (doc.isContract)
		contractSaved(doc);
	else
		documentSaved(doc);
}

function saveCurrentDocument()
{	
	saveDocument(currentDocument)
}

function saveDocuments(onlyContracts)
{
	for (var i = 0; i < unsavedFiles.length; i++)
	{
		var d = unsavedFiles[i]
		if (!onlyContracts)
			saveDocument(d)
		else if (d.isContract)
			saveDocument(d)
	}
}

function saveAll()
{
	saveDocuments(false)
	saveProject();
}

function createProject() {
	newProjectDialog.open();
}

function closeProject(callBack) {
	if (!isEmpty && unsavedFiles.length > 0)
	{
		saveMessageDialog.callBack = callBack;
		saveMessageDialog.open();
	}
	else
	{
		projectIsClosing = true;
		doCloseProject();
		if (callBack)
			callBack();
	}
}

function saveProject() {
	if (!isEmpty) {
		projectSaving();
		var projectData = saveProjectFile();
		if (projectData !== null)
			projectSaved();
	}
}

function saveProjectProperty(key, value)
{
	var projectFile = projectPath + projectFileName;
	var json = fileIo.readFile(projectFile);
	if (!json)
		return;
	var projectData = JSON.parse(json);
	projectData[key] = value
	json = JSON.stringify(projectData, null, "\t");
	fileIo.writeFile(projectFile, json);
}

function saveProjectFile()
{
	if (!isEmpty) {
		var projectData = {
			files: [],
			title: projectTitle,
			deploymentAddresses: deploymentAddresses,
			applicationUrlEth: projectModel.applicationUrlEth,
			applicationUrlHttp: projectModel.applicationUrlHttp,
			deploymentDir: deploymentDialog.packageStep.packageDir,
			lastPackageDate:  deploymentDialog.packageStep.lastPackageDate,
			deployBlockNumber: projectModel.deployBlockNumber,
			localPackageUrl: deploymentDialog.packageStep.localPackageUrl,
			deploymentTrHashes: JSON.stringify(projectModel.deploymentTrHashes),
			registerContentHashTrHash: projectModel.registerContentHashTrHash,
			registerUrlTrHash: projectModel.registerUrlTrHash,
			registerContentHashBlockNumber: projectModel.registerContentHashBlockNumber,
			registerUrlBlockNumber: projectModel.registerUrlBlockNumber,
			startUrl: mainContent.webView.relativePath()
		};
		for (var i = 0; i < projectListModel.count; i++)
			projectData.files.push({
									   title: projectListModel.get(i).name,
									   fileName: projectListModel.get(i).fileName,
								   });

		projectFileSaving(projectData);
		var json = JSON.stringify(projectData, null, "\t");
		var projectFile = projectPath + "/" + projectFileName;
		fileIo.writeFile(projectFile, json);
		projectFileSaved(projectData);
		return projectData;
	}
	return null;
}

function loadProject(path) {
	closeProject(function() {
		console.log("Loading project at " + path);
		var projectFile = path + "/" + projectFileName;
		var json = fileIo.readFile(projectFile);
		if (!json)
			return;
		var projectData = JSON.parse(json);
		if (projectData.deploymentDir)
			projectModel.deploymentDir = projectData.deploymentDir
		if (projectData.applicationUrlEth)
			projectModel.applicationUrlEth = projectData.applicationUrlEth
		if (projectData.applicationUrlHttp)
			projectModel.applicationUrlHttp = projectData.applicationUrlHttp
		if (projectData.lastPackageDate)
			deploymentDialog.packageStep.lastPackageDate = projectData.lastPackageDate
		if (projectData.deployBlockNumber)
			projectModel.deployBlockNumber = projectData.deployBlockNumber
		if (projectData.localPackageUrl)
			deploymentDialog.packageStep.localPackageUrl =  projectData.localPackageUrl
		if (projectData.deploymentTrHashes)
			projectModel.deploymentTrHashes = JSON.parse(projectData.deploymentTrHashes)
		if (projectData.registerUrlTrHash)
			projectModel.registerUrlTrHash = projectData.registerUrlTrHash
		if (projectData.registerContentHashTrHash)
			projectModel.registerContentHashTrHash = projectData.registerContentHashTrHash
		if (projectData.registerContentHashBlockNumber)
			projectModel.registerContentHashBlockNumber = projectData.registerContentHashBlockNumber
		if (projectData.registerUrlBlockNumber)
			projectModel.registerUrlBlockNumber = projectData.registerUrlBlockNumber
		if (projectData.startUrl)
			projectModel.startUrl = projectData.startUrl
		if (!projectData.title) {
			var parts = path.split("/");
			projectData.title = parts[parts.length - 2];
		}
		deploymentAddresses = projectData.deploymentAddresses ? projectData.deploymentAddresses : {};
		projectTitle = projectData.title;
		if (path.lastIndexOf("/") === path.length - 1)
			path = path.substring(0, path.length - 1)
		projectPath = path;

		// all files/folders from the root path are included in Mix.
		if (!projectData.files)
			projectData.files = [];

		if (mainApplication.trackLastProject)
			projectSettings.lastProjectPath = path;

		projectLoading(projectData);
		//TODO: move this to codemodel
		var contractSources = {};
		for (var d = 0; d < listModel.count; d++) {
			var doc = listModel.get(d);
			if (doc.isContract)
				projectModel.openDocument(doc.documentId)
		}
		projectLoaded()
	});
}

function file(docData)
{
	var fileName = docData.fileName
	var extension = fileName.substring(fileName.lastIndexOf("."), fileName.length);
	var path = docData.path
	var isContract = extension === ".sol";
	var isHtml = extension === ".html";
	var isCss = extension === ".css";
	var isJs = extension === ".js";
	var isImg = extension === ".png"  || extension === ".gif" || extension === ".jpg" || extension === ".svg";
	var syntaxMode = isContract ? "solidity" : isJs ? "javascript" : isHtml ? "htmlmixed" : isCss ? "css" : "";
	var groupName = isContract ? qsTr("Contracts") : isJs ? qsTr("Javascript") : isHtml ? qsTr("Web Pages") : isCss ? qsTr("Styles") : isImg ? qsTr("Images") : qsTr("Misc");
	var docData = {
		contract: false,
		path: path,
		fileName: fileName,
		name: fileName,
		documentId: path,
		syntaxMode: syntaxMode,
		isText: isContract || isHtml || isCss || isJs,
		isContract: isContract,
		isHtml: isHtml,
		groupName: groupName
	};
	return docData
}

function doCloseProject() {
	console.log("Closing project");
	projectListModel.clear();
	projectPath = "";
	currentDocument = null
	projectClosed();
}

function doCreateProject(title, path) {
	closeProject(function() {
		console.log("Creating project " + title + " at " + path);
		var dirPath = path + "/" + title
		fileIo.makeDir(dirPath);
		var projectFile = dirPath + "/" + projectFileName;
		var indexFile = "index.html";
		var contractsFile = "contract.sol";
		var projectData = {
			title: title,
			files: [ contractsFile, indexFile ]
		};
		//TODO: copy from template
		if (!fileIo.fileExists(dirPath + "/" + indexFile))
			fileIo.writeFile(dirPath + "/" + indexFile, htmlTemplate);
		if (!fileIo.fileExists(dirPath + "/" + contractsFile))
			fileIo.writeFile(dirPath + "/" + contractsFile, contractTemplate);

		newProject(projectData);
		var json = JSON.stringify(projectData, null, "\t");
		fileIo.writeFile(projectFile, json);
		loadProject(dirPath);
	});
}

function newHtmlFile() {
	createAndAddFile("page", "html", htmlTemplate);
}

function newCssFile() {
	createAndAddFile("style", "css", "body {\n}\n");
}

function newJsFile() {
	createAndAddFile("script", "js", "function foo() {\n}\n");
}

function newContract() {
	var ctrName = "contract" + Object.keys(codeModel.contracts).length
	var ctr = basicContractTemplate.replace("FirstContract", ctrName)
	createAndAddFile("contract", "sol", ctr, ctrName + ".sol");
}

function createAndAddFile(name, extension, content, fileName) {
	fileName = generateFileName(name, extension);
	var filePath = currentFolder + "/" + fileName;
	if (!fileIo.fileExists(filePath))
		fileIo.writeFile(filePath, content);
	saveProjectFile();
	documentAdded(filePath);
}

function generateFileName(name, extension) {
	var i = 1;
	do {
		var fileName = name + i + "." + extension;
		var filePath = currentFolder + "/" + fileName;
		i++;
	} while (fileIo.fileExists(filePath));
	return fileName
}

function regenerateCompilationResult()
{
	fileIo.deleteDir(compilationFolder)
	fileIo.makeDir(compilationFolder)
	var ctrJson = {}
	for (var c in codeModel.contracts)
	{
		var contract = codeModel.contracts[c]
		ctrJson[contract.documentId] = ""
	}

	for (var doc in ctrJson)
		saveContractCompilationResult(doc)
}

function saveContractCompilationResult(documentId)
{
	if (!fileIo.dirExists(compilationFolder))
		fileIo.makeDir(compilationFolder)
	var date = new Date()
	var ret = "/*\nGenerated by Mix\n" + date.toString() + "\n*/\n\n"
	var newCompilationResult = false
	for (var c in codeModel.contracts)
	{
		var contract = codeModel.contracts[c]
		if (contract.documentId === documentId)
		{
			newCompilationResult = true
			var ctr = {
				name: c,
				codeHex: contract.codeHex,
				abi: contract.contractInterface
			}
			ret += "var " + c + " = " + JSON.stringify(ctr, null, "\t") + "\n\n"
		}
	}
	if (newCompilationResult)
		fileIo.writeFile(compilationFolder + "/" + documentId.substring(documentId.lastIndexOf("/")) + ".js", ret)
}

