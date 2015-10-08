import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0
import org.ethereum.qml.InverseMouseArea 1.0
import "js/Debugger.js" as Debugger
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "."

ColumnLayout
{
	id: blockChainSelector
	signal restored(variant scenario)
	signal saved(variant scenario)
	signal duplicated(variant scenario)
	signal loaded(variant scenario)
	signal renamed(variant scenario)
	signal deleted()
	signal closed()
	property alias selectedScenarioIndex: scenarioList.currentIndex
	property bool panelLoaded: false
	property int btnWidth: 77
	spacing: 0
	function init()
	{
		scenarioList.model = projectModel.stateListModel
		scenarioList.load()
		panelLoaded = true
	}

	function clear()
	{
		scenarioList.model = []
		closed()
		panelLoaded = false
	}

	function needSaveOrReload()
	{
	}

	function updateWidth(_width)
	{
		var w;
		if (_width < btnRowContainer.minimalWidth)
			w = (_width - btnRowContainer.comboboxWidth) / 6
		else
			w = 100

		if (_width < 570)
			btnRowContainer.anchors.horizontalCenter = undefined
		else
			btnRowContainer.anchors.horizontalCenter = btnRowContainer.parent.horizontalCenter

		updatebtnWidth(w)
		updatebtnWidth((rowBtn.width - 20) / 6 < btnWidth ? (rowBtn.width - 20) / 6 : btnWidth)
		scenarioLabel.visible = rowBtn.width / 6 > btnWidth
	}

	function updatebtnWidth(w)
	{
		editScenario.width = w
		deleteScenario.width = w
		duplicateScenario.width = w
		addScenario.width = w
		restoreScenario.width = w
		saveScenario.width = w
		rowBtn.width = 6 * w
	}

	function createScenario(defaultScenario)
	{
		addScenario.createScenario(defaultScenario)
	}

	RowLayout
	{
		anchors.horizontalCenter: parent.horizontalCenter
		spacing: 0
		anchors.top: parent.top
		anchors.topMargin: 7
		id: btnRowContainer
		property int comboboxWidth: 100
		property int minimalWidth: 100 * 6 + btnRowContainer.comboboxWidth
		Layout.preferredHeight: 40
		Item
		{
			Layout.preferredWidth: parent.comboboxWidth
			height: 20
			id: scenarioCont
			anchors.top: parent.top
			Rectangle
			{
				anchors.top: parent.bottom
				anchors.topMargin: 10
				width: parent.width
				DefaultLabel
				{
					text: qsTr("Scenario")
					id: scenarioLabel
					anchors.centerIn: parent
				}
			}

			Connections
			{
				target: projectModel.stateListModel
				onStateDeleted: {
					scenarioList.init()
				}
			}

			Rectangle
			{
				id: left
				width: 10
				height: parent.height
				anchors.left: scenarioList.left
				anchors.leftMargin: -4
				radius: 15
			}

			ComboBox
			{
				id: scenarioList
				anchors.left: parent.left
				model: projectModel.stateListModel
				anchors.top: parent.top
				textRole: "title"
				height: parent.height
				width: btnRowContainer.comboboxWidth
				signal updateView()

				onCurrentIndexChanged:
				{
					restoreScenario.restore()
				}

				function init()
				{
					scenarioList.currentIndex = 0
					deleted()
				}

				function load()
				{
					var state = projectModel.stateListModel.getState(currentIndex)
					if (state)
						loaded(state)
				}

				style: ComboBoxStyle {
					id: style
					background: Rectangle {
						color: "white"
						anchors.fill: parent
					}
					label: Rectangle {
						property alias label: comboLabel
						anchors.fill: parent
						color: "white"
						DefaultLabel {
							Image {
								id: up
								anchors.top: parent.top
								anchors.right: parent.right
								anchors.topMargin: -2
								source: "qrc:/qml/img/up.png"
								width: 10
								height: 10
							}

							Image {
								id: down
								anchors.bottom: parent.bottom
								anchors.bottomMargin: -3
								anchors.right: parent.right
								source: "qrc:/qml/img/down.png"
								width: 10
								height: 10
							}
							id: comboLabel
							maximumLineCount: 1
							elide: Text.ElideRight
							width: parent.width
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
							anchors.leftMargin: -4
							anchors.top: parent.top
							Component.onCompleted:
							{
								comboLabel.updateLabel()
							}

							function updateLabel()
							{
								comboLabel.text = ""
								if (scenarioList.currentIndex > - 1 && scenarioList.currentIndex < projectModel.stateListModel.count)
									comboLabel.text = projectModel.stateListModel.getState(scenarioList.currentIndex).title
							}

							Connections {
								target: blockChainSelector
								onLoaded: {
									if (projectModel.stateListModel.count > 0)
										comboLabel.text = projectModel.stateListModel.getState(scenarioList.currentIndex).title
									else
										return ""
								}
								onRenamed: {
									comboLabel.text = scenario.title
									scenarioNameEdit.text = scenario.title
								}
								onDeleted: {
									comboLabel.updateLabel()
								}
								onClosed: {
									comboLabel.text = ""
								}
							}
						}
					}
				}
			}

			DefaultTextField
			{
				id: scenarioNameEdit
				anchors.left: scenarioCont.left
				anchors.top: parent.top
				anchors.leftMargin: -4
				height: parent.height
				z: 5
				visible: false
				width: btnRowContainer.comboboxWidth
				Keys.onEnterPressed:
				{
					toggleEdit()
				}

				Keys.onReturnPressed:
				{
					toggleEdit()
				}

				function toggleEdit()
				{
					scenarioList.visible = !scenarioList.visible
					scenarioNameEdit.visible = !scenarioNameEdit.visible
					if (!scenarioNameEdit.visible)
						scenarioNameEdit.save()
					else
					{
						scenarioNameEdit.text = projectModel.stateListModel.getState(scenarioList.currentIndex).title
						scenarioNameEdit.forceActiveFocus()
						outsideClick.active = true
					}
				}

				function save()
				{
					outsideClick.active = false

					for (var k = 0; k < projectModel.stateListModel.count; ++k)
					{
							if (projectModel.stateListModel.get(k).title === scenarioNameEdit.text)
								return //title already exists
					}

					projectModel.stateListModel.getState(scenarioList.currentIndex).title = scenarioNameEdit.text
					projectModel.saveProjectFile()
					saved(state)
					scenarioList.model.get(scenarioList.currentIndex).title = scenarioNameEdit.text
					scenarioList.currentIndex = scenarioList.currentIndex
					renamed(projectModel.stateListModel.getState(scenarioList.currentIndex))
				}

				InverseMouseArea {
					id: outsideClick
					anchors.fill: parent
					active: false
					onClickedOutside: {
						scenarioNameEdit.toggleEdit()
					}
				}
			}

			Rectangle
			{
				width: 10
				height: parent.height
				anchors.right: parent.right
				anchors.rightMargin: -6
				color: "white"
				radius: 15
			}
		}

		Row
		{
			anchors.top: parent.top
			width: btnWidth * 6
			Layout.preferredWidth: btnWidth * 6
			height: 20
			id: rowBtn
			ScenarioButton {
				id: editScenario
				width: btnWidth
				height: parent.height
				sourceImg: "qrc:/qml/img/edittransaction.png"
				onClicked: {
					scenarioNameEdit.toggleEdit()
				}
				text: qsTr("Edit Title")
				roundRight: false
				roundLeft: true
				enabled: panelLoaded
			}

			Rectangle
			{
				width: 1
				height: parent.height
				color: "#ededed"
			}

			ScenarioButton {
				id: deleteScenario
				enabled: panelLoaded
				width: btnWidth
				height: parent.height
				sourceImg: "qrc:/qml/img/delete-block-icon@2x.png"
				onClicked: {
					if (projectModel.stateListModel.count > 1)
						deleteWarning.open()
				}
				text: qsTr("Delete")
				roundRight: true
				roundLeft: false
			}

			MessageDialog
			{
				id: deleteWarning
				text: qsTr("Are you sure to delete this scenario ?")
				onYes:
				{
					projectModel.stateListModel.deleteState(scenarioList.currentIndex)
					scenarioList.init()
				}
				standardButtons: StandardButton.Yes | StandardButton.No
			}

			Rectangle
			{
				width: 1
				height: parent.height
				color: "#ededed"
			}

			ScenarioButton {
				id: addScenario
				enabled: panelLoaded
				width: btnWidth
				height: parent.height
				sourceImg: "qrc:/qml/img/newIcon@2x.png"
				onClicked: {
					addScenario.createScenario(false)
				}
				text: qsTr("New")
				roundRight: false
				roundLeft: false

				function createScenario(defaultScenario)
				{
					var item = projectModel.stateListModel.createDefaultState();
					if (defaultScenario)
					{
						//we add get and set transaction function call (of Rating contract)
						var tx = projectModel.stateListModel.defaultTransactionItem()
						tx.functionId = "setRating";
						tx.contractId = "<Rating - 0>";
						tx.parameters = { _key: "imthekey",_value: "12" }
						tx.label = tx.contractId + "." + tx.functionId + "()"
						tx.sender = item.accounts[0].secret;
						tx.isContractCreation = false
						item.transactions.push(tx);
						item.blocks[0].transactions.push(tx)
						var tx2 = projectModel.stateListModel.defaultTransactionItem()
						tx2.functionId = "ratings";
						tx2.contractId = "<Rating - 0>";
						tx2.label = tx2.contractId + "." + tx2.functionId + "()"
						tx2.sender = item.accounts[0].secret;
						tx2.parameters = { "": "imthekey" }
						tx2.isContractCreation = false
						item.transactions.push(tx2);
						item.blocks[0].transactions.push(tx2)
					}

					item.title = defaultScenario ? qsTr("Default") : qsTr("New Scenario")
					projectModel.stateListModel.appendState(item)
					projectModel.stateListModel.save()
					scenarioList.currentIndex = defaultScenario ? 0 : projectModel.stateListModel.count - 1
					if (defaultScenario)
						scenarioList.load()
					else
						scenarioNameEdit.toggleEdit()
				}
			}

			Rectangle
			{
				width: 1
				height: parent.height
				color: "#ededed"
			}

			ScenarioButton {
				id: restoreScenario
				enabled: panelLoaded
				width: btnWidth
				height: parent.height
				buttonShortcut: ""
				sourceImg: "qrc:/qml/img/restoreicon@2x.png"
				onClicked: {
					restore()
				}
				text: qsTr("Reset")
				function restore()
				{
					var state = projectModel.stateListModel.reloadStateFromProject(scenarioList.currentIndex)
					if (state)
					{
						restored(state)
						loaded(state)
					}
				}
				roundRight: false
				roundLeft: false
			}

			Rectangle
			{
				width: 1
				height: parent.height
				color: "#ededed"
			}

			ScenarioButton {
				id: saveScenario
				enabled: panelLoaded
				text: qsTr("Save")
				onClicked: save()
				width: btnWidth
				height: parent.height
				buttonShortcut: ""
				sourceImg: "qrc:/qml/img/saveicon@2x.png"
				roundRight: false
				roundLeft: false

				function save()
				{
					projectModel.saveProjectFile()
					saved(state)
				}
			}

			Connections
			{
				target: clientModel
				onSetupFinished: {
					saveScenario.save()
				}
			}

			Rectangle
			{
				width: 1
				height: parent.height
				color: "#ededed"
			}

			ScenarioButton
			{
				id: duplicateScenario
				enabled: panelLoaded
				text: qsTr("Duplicate")
				onClicked: {
					projectModel.stateListModel.duplicateState(scenarioList.currentIndex)
					duplicated(state)
					scenarioList.currentIndex = projectModel.stateListModel.count - 1
					scenarioNameEdit.toggleEdit()
				}
				width: btnWidth
				height: parent.height
				buttonShortcut: ""
				sourceImg: "qrc:/qml/img/duplicateicon@2x.png"
				roundRight: true
				roundLeft: false
			}
		}
	}
}
