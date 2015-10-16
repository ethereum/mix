import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.3
import Qt.labs.settings 1.0
import "."

Item {
	property bool renameMode: false;
	property alias sections: sectionRepeater

	ProjectFilesStyle
	{
		id: projectFilesStyle
	}

	ColumnLayout {
		anchors.fill: parent
		id: filesCol
		spacing: 0

		SourceSansProLight
		{
			id: srcSansProLight
		}

		Rectangle
		{
			color: projectFilesStyle.title.background
			height: projectFilesStyle.title.height
			Layout.fillWidth: true
			Image {
				id: projectIcon
				source: "qrc:/qml/img/dappProjectIcon.png"
				anchors.right: projectTitle.left
				anchors.verticalCenter: parent.verticalCenter
				anchors.rightMargin: 6
				fillMode: Image.PreserveAspectFit
				width: 32
				height: 32
				visible: false
			}

			DefaultText
			{
				id: projectTitle
				color: projectFilesStyle.title.color
				text: projectModel.projectTitle
				anchors.verticalCenter: parent.verticalCenter
				visible: !projectModel.isEmpty;
				anchors.left: parent.left
				anchors.leftMargin: projectFilesStyle.general.leftMargin
				font.family: srcSansProLight.name
				font.bold: true
				font.wordSpacing: 2
			}

			DefaultText
			{
				text: "-"
				anchors.right: parent.right
				anchors.rightMargin: 15
				font.family: srcSansProLight.name
				anchors.verticalCenter: parent.verticalCenter
				font.weight: Font.Light
			}
		}

		Rectangle
		{
			Layout.fillWidth: true
			height: 3
			color: projectFilesStyle.documentsList.background
		}

		Rectangle
		{
			Layout.fillWidth: true
			Layout.fillHeight: true
			color: projectFilesStyle.documentsList.background

			ColumnLayout
			{
				anchors.top: parent.top
				width: parent.width
				spacing: 0
				Repeater {
					model: [qsTr("Contracts"), qsTr("Javascript"), qsTr("Web Pages"), qsTr("Styles"), qsTr("Images"), qsTr("Misc")];
					signal selected(string doc, string groupName)
					signal isCleanChanged(string doc, string groupName, var isClean)
					property int incr: -1;
					id: sectionRepeater
					FilesSection
					{
						id: section;
						sectionName: modelData
						index:
						{
							for (var k in sectionRepeater.model)
							{
								if (sectionRepeater.model[k] === modelData)
									return k;
							}
						}

						model: sectionModel
						selManager: sectionRepeater

						onDocumentSelected: {
							selManager.selected(doc, groupName);
						}

						ListModel
						{
							id: sectionModel
						}

						Connections {
							id: projectConnection
							target: codeModel
							property var contractsLocation: ({})
							onCompilationComplete:
							{
								if (modelData !== "Contracts")
									return

								for (var name in codeModel.contracts)
								{
									var newLocation = codeModel.locationOf(name)
									var found = false
									for (var k = 0; k < sectionModel.count; k++)
									{
										var ctr = sectionModel.get(k)
										if (ctr.startlocation["source"] === newLocation["source"]
												&& ctr.startlocation["startlocation"] === newLocation["startlocation"]
												&& name !== ctr.name)
										{
											found = true
											ctr.name = name
											sectionModel.set(k, ctr)
											// we have a contract at a known location. contract name has changed
											break
										}
										else if ((ctr.startlocation["source"] !== newLocation["source"]
													|| ctr.startlocation["startlocation"] !== newLocation["startlocation"])
													&& name === ctr.name)
										{
											found = true
											ctr.startLocation = newLocation
											sectionModel.set(k, ctr)
											// we have a known contract at a different location
											break;
										}
										else if (ctr.startlocation["source"] === newLocation["source"]
												  && ctr.startlocation["startlocation"] === newLocation["startlocation"]
												  && name === ctr.name)
										{
											found = true
											break;
										}
									}

									//before, we delete duplicate (empty file) which lead to the same sol file.


									if (!found)
									{
										var ctr = codeModel.contracts[name]
										var doc = projectModel.getDocument(ctr.documentId)
										var item = {};
										item.startlocation = newLocation
										item.name = name // change the filename by the contract name
										item.fileName = doc.fileName
										item.contract = true
										item.documentId = doc.documentId
										item.groupName = doc.groupName
										item.isContract = doc.isContract
										item.isHtml = doc.isHtml
										item.isText = doc.isText
										item.path = doc.path
										item.syntaxMode = doc.syntaxMode

										//we have a new contract, check if this contract has been created in an empty doc which already exist.
										var emptyFileNotFound = true
										for (var k = 0; k < sectionModel.count; k++)
										{
											var doc = sectionModel.get(k)
											if (doc.name === qsTr("(empty)") && doc.documentId === codeModel.contracts[name].documentId)
											{
												if (emptyFileNotFound)
												{
													sectionModel.set(k, item);
													emptyFileNotFound = false
													break;
												}
											}
										}
										if (emptyFileNotFound)
											sectionModel.append(item);
									}
								}

								var alreadyEmpty = {}
								for (var k = 0; k < sectionModel.count; k++)
								{
									var c = sectionModel.get(k)
									if (!codeModel.contracts[c.name])
									{
										if (projectModel.codeEditor.getDocumentText(c.documentId).trim() !== "")
											sectionModel.remove(k)
										else
										{
											if (alreadyEmpty[c.documentId])
												sectionModel.remove(k)
											else
											{
												alreadyEmpty[c.documentId] = 1
												c.name = qsTr("(empty)")
												sectionModel.set(k, c)
											}
										}
									}
								}
							}

							onContractRenamed: {
							}							
						}

						Connections {
							id: projectModelConnection
							target: projectModel

							function addDocToSubModel()
							{
								for (var k = 0; k < projectModel.listModel.count; k++)
								{
									var item = projectModel.listModel.get(k);
									if (item.groupName === modelData)
										sectionModel.append(item);
								}
							}

							onIsCleanChanged: {
								for (var si = 0; si < sectionModel.count; si++) {
									var document = sectionModel.get(si);
									if (documentId === document.documentId && document.groupName === modelData)
									{
										selManager.isCleanChanged(documentId, modelData, isClean);
										break;
									}
								}
							}

							onDocumentOpened: {
								if (document.groupName === modelData)
									sectionRepeater.selected(document.documentId, modelData);
							}

							onNewProject: {
								sectionModel.clear();
							}

							onProjectClosed: {
								projectConnection.contractsLocation = {}
								sectionModel.clear();
							}

							onProjectLoaded: {
								sectionModel.clear();
								if (modelData != "Contracts")
									addDocToSubModel();
								if (modelData === "Contracts")
								{
									var selItem = projectModel.listModel.get(0);
									projectModel.openDocument(selItem.documentId);
								}
							}

							onDocumentAdded:
							{
								var newDoc = projectModel.getDocument(documentId);
								if (newDoc.groupName === modelData)
								{
									if (modelData !== "Contracts")
										sectionModel.append(newDoc);

									projectModel.openDocument(newDoc.documentId);
									sectionRepeater.selected(newDoc.documentId, modelData);
								}
							}
						}
					}
				}
			}
		}
	}
}

