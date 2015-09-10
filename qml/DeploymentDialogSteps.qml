import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3

Rectangle {
	anchors.fill: parent
	color: "#e9eff7"
	property var worker
	property variant sel
	property variant menuSel
	signal selected(string step)
	id: root

	function refreshCurrent()
	{
		topMenu.itemAt(menuSel).select(sel)
	}

	function init()
	{
		topMenu.itemAt(0).select(0)
	}

	function itemClicked(step)
	{
		selected(step)
	}

	function unselect(tMenu, menu)
	{
		topMenu.itemAt(tMenu).unselect(menu)
	}

	function reset()
	{
		for (var k in deployLogs.logs)
			deployLogs.logs[k] = ""
		deployLogs.switchLogs()
		refreshCurrent()
	}

	border.color: "#cccccc"
	border.width: 1
	Connections
	{
		id: deployStatus
		target: deploymentDialog.deployStep
		onDeployed:
		{
			console.log("deployed")
		}
	}

	Connections
	{
		id: packagedStatus
		target: deploymentDialog.packageStep
		onPackaged:
		{
			console.log("packaged")
		}
	}

	Connections
	{
		id: registerStatus
		target: deploymentDialog.registerStep
		onRegistered:
		{
			console.log("registered")
		}
	}

	ColumnLayout
	{
		anchors.fill: parent
		anchors.margins: 1
		spacing: 0
		Repeater
		{
			id: topMenu
			model: [
				{
					step: 1,
					type: "DEPLOY",
					label: qsTr("Deploy contracts"),
					actions:[
						{
							step: 1,
							type:"deploy",
							label: qsTr("Select Scenario")
						},
						{
							step: 2,
							type:"option",
							label: qsTr("Deploy Scenario")
						}]
				},
				{
					step: 2,
					type:"PACKAGE",
					label: qsTr("Package dapp"),
					actions: [{
							step: 3,
							type:"package",
							label: qsTr("Generate local\npackage")
						},
						{
							step: 4,
							type:"upload",
							label: qsTr("Upload and share\npackage")
						}]
				},
				{
					step: 3,
					type:"REGISTER",
					label: qsTr("Register"),
					actions: [{
							step: 5,
							type:"register",
							label: qsTr("Register dapp")
						}]
				}]

			Rectangle
			{
				id: top
				color: "transparent"

				height:
				{
					return 30 + 50 * topMenu.model[index].actions.length
				}

				Layout.preferredHeight:
				{
					return 30 + 50 * topMenu.model[index].actions.length
				}

				function select(index)
				{
					menu.itemAt(index).select()
				}

				function unselect(index)
				{
					menu.itemAt(index).unselect()
				}

				Label
				{
					text: topMenu.model[index].label
					id: topMenuLabel
					font.italic: true
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.topMargin: 2
					anchors.leftMargin: 4
				}

				ColumnLayout
				{
					anchors.top: topMenuLabel.bottom
					anchors.left: parent.left
					id: col
					property int topIndex
					Component.onCompleted:
					{
						topIndex = index
					}

					Repeater
					{
						id: menu
						model: topMenu.model[index].actions
						Rectangle
						{
							Layout.preferredHeight: 50
							Layout.preferredWidth: col.width
							color: "white"
							border.color: "red"
							border.width: 4
							id: itemContainer							

							Component.onCompleted:
							{
								Layout.preferredHeight = 50
								height = 50
								width = col.width
								Layout.preferredWidth = col.width
							}

							function select()
							{
								if (sel !== undefined)
									 root.unselect(menuSel, sel)
								labelContainer.state = "selected"
								sel = index
								menuSel = col.topIndex
								itemClicked(menu.model[index].type)
								deployLogs.switchLogs()
							}

							function unselect()
							{
								labelContainer.state = ""
							}

							MouseArea
							{
								anchors.fill: parent
								onClicked:
								{
									itemContainer.select()
								}
							}

							Rectangle
							{
								Component.onCompleted:
								{
									width =  40
									height = 40
								}
								width: 40
								height: 40
								color: "transparent"
								border.color: "#cccccc"
								border.width: 2
								radius: width * 0.5
								anchors.verticalCenter: parent.verticalCenter
								anchors.left: parent.left
								anchors.leftMargin: 10
								id: labelContainer
								Label
								{
									color: "#cccccc"
									id: label
									anchors.centerIn: parent
									text: menu.model[index].step
								}
								states: [
									State {
										name: "selected"
										PropertyChanges { target: label; color: "white" }
										PropertyChanges { target: labelContainer.border; width: 0 }
										PropertyChanges { target: detail; color: "white" }
										PropertyChanges { target: itemContainer; color: "#accbf2" }
										PropertyChanges { target: labelContainer; color: "#accbf2" }
										PropertyChanges { target: nameContainer; color: "#accbf2" }
									}
								]

								MouseArea
								{
									anchors.fill: parent
									onClicked:
									{
										itemContainer.select()
									}
								}
							}

							Rectangle
							{
								anchors.left: label.parent.right
								width: parent.width - 40
								height: 40
								color: "transparent"
								anchors.verticalCenter: parent.verticalCenter
								id: nameContainer
								Component.onCompleted:
								{
									width = 140
									height = 40
								}
								Label
								{
									id: detail
									color: "black"
									anchors.verticalCenter: parent.verticalCenter
									anchors.left: parent.left
									anchors.leftMargin: 5
									text: menu.model[index].label
									MouseArea
									{
										anchors.fill: parent
										onClicked:
										{
											itemContainer.select()
										}
									}
								}
							}
						}
					}


					Rectangle
					{
						Layout.preferredWidth: col.width
						Layout.preferredHeight: 2
						anchors.bottom: parent.bottom
						color: "#cccccc"
					}
				}


			}
		}

		Connections {
			property var logs: ({})
			id: deployLogs

			function switchLogs()
			{
				if (root.sel)
				{
					if (!logs[root.sel])
						logs[root.sel] = ""
					log.text = logs[root.sel]
				}
			}

			target: projectModel
			onDeploymentStarted:
			{
				if (!logs[root.sel])
					logs[root.sel] = ""
				logs[root.sel] = logs[root.sel] + qsTr("Running deployment...") + "\n"
				log.text = logs[root.sel]
			}

			onDeploymentError:
			{
				if (!logs[root.sel])
					logs[root.sel] = ""
				logs[root.sel] = logs[root.sel] + error + "\n"
				log.text = logs[root.sel]
			}

			onDeploymentComplete:
			{
				if (!logs[root.sel])
					logs[root.sel] = ""
				logs[root.sel] = logs[root.sel] + qsTr("Deployment complete") + "\n"
				log.text = logs[root.sel]
			}

			onDeploymentStepChanged:
			{
				if (!logs[root.sel])
					logs[root.sel] = ""
				logs[root.sel] = logs[root.sel] + message + "\n"
				log.text = logs[root.sel]
			}
		}

		Rectangle
		{
			Layout.fillWidth: true
			Layout.preferredHeight: 2
			color: "#cccccc"
		}

		ScrollView
		{
			Layout.fillHeight: true
			Layout.fillWidth: true
			Text
			{
				anchors.left: parent.left
				anchors.leftMargin: 2
				font.pointSize: 9
				font.italic: true
				id: log
			}
		}

		Rectangle
		{
			Layout.preferredHeight: 20
			Layout.fillWidth: true
			color: "#cccccc"
			LogsPaneStyle
			{
				id: style
			}

			Label
			{
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.verticalCenter: parent.verticalCenter
				text: qsTr("Logs")
				font.italic: true
				font.pointSize: style.absoluteSize(-1)
			}

			Button
			{
				height: 20
				width: 20
				anchors.right: parent.right
				action: clearAction
				iconSource: "qrc:/qml/img/cleariconactive.png"
				tooltip: qsTr("Clear Messages")
			}

			Action {
				id: clearAction
				enabled: log.text !== ""
				tooltip: qsTr("Clear")
				onTriggered: {
					deployLogs.logs[root.sel] = ""
					log.text = deployLogs.logs[root.sel]
				}
			}
		}

	}
}

