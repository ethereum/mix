import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.SortFilterProxyModel 1.0

Rectangle
{
	property variant statusPane
	property variant currentStatus
	property int contentXPos: logStyle.generic.layout.dateWidth + logStyle.generic.layout.typeWidth - 70
	property int length: logsModel.count

	function clear()
	{
		logsModel.clear();
		statusPane.clear();
		currentStatus = undefined;
	}

	function push(_level, _type, _content)
	{
		_content = _content.replace(/\n/g, " ")
		logsModel.insert(0, { "type": _type, "date": Qt.formatDateTime(new Date(), "hh:mm:ss"), "content": _content, "level": _level });
	}

	onVisibleChanged:
	{
		if (currentStatus && visible && (logsModel.count === 0 || logsModel.get(0).content !== currentStatus.content || logsModel.get(0).date !== currentStatus.date))
			logsModel.insert(0, { "type": currentStatus.type, "date": currentStatus.date, "content": currentStatus.content, "level": currentStatus.level });
		else if (!visible)
		{
			for (var k = 0; k < logsModel.count; k++)
			{
				if (logsModel.get(k).type === "Comp") //do not keep compilation logs.
					logsModel.remove(k);
			}
		}
		if (visible)
			settingConnect.updateFont()
	}

	anchors.fill: parent
	radius: 10
	color: "transparent"
	id: logsPane
	Column {
		z: 2
		height: parent.height - rowAction.height
		width: parent.width
		spacing: 0
		ListModel {
			id: logsModel
		}

		ScrollView
		{
			id: scrollView
			height: parent.height
			width: parent.width
			horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
			flickableItem.interactive: false
			Column
			{
				id: logsRect
				spacing: 0
				Repeater {
					id: logsRepeater
					clip: true
					property string frontColor: "transparent"
					model: SortFilterProxyModel {
						id: proxyModel
						source: logsModel
						property var roles: ["-", "javascript", "run", "state", "comp"]

						Component.onCompleted: {
							filterType = regEx(proxyModel.roles);
						}

						function search(_value)
						{
							filterContent = _value;
						}

						function toogleFilter(_value)
						{
							var count = roles.length;
							for (var i in roles)
							{
								if (roles[i] === _value)
								{
									roles.splice(i, 1);
									break;
								}
							}
							if (count === roles.length)
								roles.push(_value);

							filterType = regEx(proxyModel.roles);
						}

						function regEx(_value)
						{
							return "(?:" + roles.join('|') + ")";
						}

						filterType: "(?:javascript|run|state|comp)"
						filterContent: ""
						filterSyntax: SortFilterProxyModel.RegExp
						filterCaseSensitivity: Qt.CaseInsensitive
					}

					Rectangle
					{
						width: logStyle.generic.layout.dateWidth + logStyle.generic.layout.contentWidth + logStyle.generic.layout.typeWidth
						height: 30
						color:
						{
							var cl;
							if (level === "warning" || level === "error")
								cl = logStyle.generic.layout.errorColor;
							else
								cl = index % 2 === 0 ? "transparent" : logStyle.generic.layout.logAlternateColor;
							if (index === 0)
								logsRepeater.frontColor = cl;
							return cl;
						}

						Component.onCompleted:
						{
							logsPane.contentXPos = logContent.x
						}

						MouseArea
						{
							anchors.fill: parent
							onClicked:
							{
								if (logContent.elide === Text.ElideNone)
								{
									logContent.elide = Text.ElideRight;
									logContent.wrapMode = Text.NoWrap
									parent.height = 30;
								}
								else
								{
									logContent.elide = Text.ElideNone;
									logContent.wrapMode = Text.Wrap;
									parent.height = logContent.lineCount * 30;
								}
							}
						}


						DefaultLabel {
							id: dateLabel
							text: date;
							font.family: logStyle.generic.layout.logLabelFont
							width: logStyle.generic.layout.dateWidth
							font.pixelSize: 12
							clip: true
							elide: Text.ElideRight
							anchors.left: parent.left
							anchors.leftMargin: 15
							anchors.verticalCenter: parent.verticalCenter
							color: {
								parent.getColor(level);
							}
						}

						DefaultLabel {
							text: type;
							id: typeLabel
							font.family: logStyle.generic.layout.logLabelFont
							width: logStyle.generic.layout.typeWidth
							clip: true
							elide: Text.ElideRight
							font.pixelSize: 12
							anchors.left: dateLabel.right
							anchors.leftMargin: 2
							anchors.verticalCenter: parent.verticalCenter
							color: {
								parent.getColor(level);
							}
						}

						DefaultText {
							id: logContent
							text: content;
							font.family: logStyle.generic.layout.logLabelFont
							width: logStyle.generic.layout.contentWidth - 50
							anchors.verticalCenter: parent.verticalCenter
							elide: Text.ElideRight
							anchors.left: typeLabel.right
							anchors.leftMargin: 2
							color: {
								parent.getColor(level);
							}
						}

						function getColor()
						{
							if (level === "error")
								return "red";
							else if (level === "warning")
								return "orange";
							else
								return "#808080";
						}
					}
				}
			}
		}

		Component {
			id: itemDelegate
			DefaultLabel {
				text: styleData.value;
				font.family: logStyle.generic.layout.logLabelFont
				font.pixelSize: 12
				color: {
					if (proxyModel.get(styleData.row).level === "error")
						return "red";
					else if (proxyModel.get(styleData.row).level === "warning")
						return "orange";
					else
						return "#808080";
				}
			}
		}
	}

	Connections
	{
		id: settingConnect
		target: appSettings
		onSystemPointSizeChanged:
		{
			updateFont()
		}

		function updateFont()
		{
			if (mainApplication.systemPointSize >= appSettings.systemPointSize)
			{
				labelFilter.height = logStyle.generic.layout.headerButtonHeight
				rectToolBtn.height = logStyle.generic.layout.headerHeight
				rowAction.height = logStyle.generic.layout.headerHeight
				javascriptButton.height = logStyle.generic.layout.headerButtonHeight
				runButton.height = logStyle.generic.layout.headerButtonHeight
				stateButton.height = logStyle.generic.layout.headerButtonHeight
				deloyButton.height = logStyle.generic.layout.headerButtonHeight
				labelFilter.width = 50
				javascriptButton.width = 30
				runButton.width = 40
				stateButton.width = 50
				deloyButton.width = 60
				rectSearch.height = 25
				javascriptButton.labelWidth = 15
				runButton.labelWidth = 25
				stateButton.labelWidth = 40
				deloyButton.labelWidth = 40
			}
			else
			{
				labelFilter.height = logStyle.generic.layout.headerButtonHeight + Math.round(appSettings.systemPointSize / 2)
				labelFilter.width = 50 + (2 * appSettings.systemPointSize)
				rectToolBtn.height = logStyle.generic.layout.headerHeight + Math.round(appSettings.systemPointSize / 2)
				rowAction.height = logStyle.generic.layout.headerHeight + Math.round(appSettings.systemPointSize / 2)
				javascriptButton.height = logStyle.generic.layout.headerButtonHeight + Math.round(appSettings.systemPointSize / 2)
				runButton.height = logStyle.generic.layout.headerButtonHeight + Math.round(appSettings.systemPointSize / 2)
				stateButton.height = logStyle.generic.layout.headerButtonHeight + Math.round(appSettings.systemPointSize / 2)
				deloyButton.height = logStyle.generic.layout.headerButtonHeight + Math.round(appSettings.systemPointSize / 2)
				javascriptButton.width = 30 + (2 * appSettings.systemPointSize)
				runButton.width = 40 + (3 * appSettings.systemPointSize)
				stateButton.width = 50 + (3 * appSettings.systemPointSize)
				deloyButton.width = 60 + (3 * appSettings.systemPointSize)
				rectSearch.height = 25 + Math.round(appSettings.systemPointSize / 2)
				javascriptButton.labelWidth = 15 + 2 * appSettings.systemPointSize
				runButton.labelWidth = 25 + 3 * appSettings.systemPointSize
				stateButton.labelWidth = 40 + 3 * appSettings.systemPointSize
				deloyButton.labelWidth = 40 + 3 * appSettings.systemPointSize
			}
		}
	}

	Rectangle
	{
		gradient: Gradient {
			GradientStop { position: 0.0; color: "#f1f1f1" }
			GradientStop { position: 1.0; color: "#d9d7da" }
		}
		Layout.minimumHeight: logStyle.generic.layout.headerHeight
		height: logStyle.generic.layout.headerHeight
		width: logsPane.width
		anchors.bottom: parent.bottom
		id: rectToolBtn
		Row
		{
			id: rowAction
			anchors.leftMargin: logStyle.generic.layout.leftMargin
			anchors.left: parent.left
			spacing: logStyle.generic.layout.headerButtonSpacing
			height: parent.height

			DefaultLabel
			{
				id: labelFilter
				text: qsTr("Filter:")
				verticalAlignment: Text.AlignVCenter
				width: 50
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 1;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor1
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 2;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor2
			}		

			ToolButton {
				id: javascriptButton
				checkable: true
				height: logStyle.generic.layout.headerButtonHeight
				width: 30
				property int labelWidth: 15
				anchors.verticalCenter: parent.verticalCenter
				checked: true
				onCheckedChanged: {
					proxyModel.toogleFilter("javascript")
				}
				tooltip: qsTr("JavaScript")
				style:
					ButtonStyle {
					label:
						Item {
						Rectangle
						{
							width: javascriptButton.width - 5
							height: javascriptButton.height - 7
							color: "transparent"
							DefaultLabel {
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.verticalCenter: parent.verticalCenter
								elide: Text.ElideRight
								font.family: logStyle.generic.layout.logLabelFont
								font.pixelSize: 12
								color: logStyle.generic.layout.logLabelColor
								text: qsTr("JS")
							}
						}
					}
					background:
						Rectangle {
						color: javascriptButton.checked ? logStyle.generic.layout.buttonSelected : "transparent"
					}
				}
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 1;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor1
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 2;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor2
			}

			ToolButton {
				id: runButton
				checkable: true
				height: logStyle.generic.layout.headerButtonHeight
				property int labelWidth: 25
				width: 40
				anchors.verticalCenter: parent.verticalCenter
				checked: true
				onCheckedChanged: {
					proxyModel.toogleFilter("run")
				}
				tooltip: qsTr("Run")
				style:
					ButtonStyle {
					label:
						Item {
						Rectangle
						{
							width: runButton.width - 5
							height: runButton.height - 7
							color: "transparent"
							DefaultLabel {
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.verticalCenter: parent.verticalCenter
								elide: Text.ElideRight
								font.family: logStyle.generic.layout.logLabelFont
								font.pixelSize: 12
								color: logStyle.generic.layout.logLabelColor
								text: qsTr("Run")
							}
						}
					}
					background:
						Rectangle {
						color: runButton.checked ? logStyle.generic.layout.buttonSelected : "transparent"
					}
				}
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 1;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor1
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 2;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor2
			}

			ToolButton {
				id: stateButton
				checkable: true
				property int labelWidth: 30
				height: logStyle.generic.layout.headerButtonHeight
				anchors.verticalCenter: parent.verticalCenter
				width: 50
				checked: true
				onCheckedChanged: {
					proxyModel.toogleFilter("state")
				}
				tooltip: qsTr("State")
				style:
					ButtonStyle {
					label:
						Item {
						Rectangle
						{
							width: stateButton.width - 5
							height: stateButton.height - 7
							color: "transparent"
							DefaultLabel {
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.verticalCenter: parent.verticalCenter
								elide: Text.ElideRight
								font.family: logStyle.generic.layout.logLabelFont
								font.pixelSize: 12
								color: logStyle.generic.layout.logLabelColor
								text: qsTr("State")
							}
						}
					}
					background:
						Rectangle {
						color: stateButton.checked ? logStyle.generic.layout.buttonSelected : "transparent"
					}
				}
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 1;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor1
			}

			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 2;
				height: parent.height
				color: logStyle.generic.layout.buttonSeparatorColor2
			}			
		}

		Row
		{
			height: parent.height
			anchors.right: parent.right
			anchors.rightMargin: 10
			spacing: 10
			anchors.verticalCenter: parent.verticalCenter

			DefaultImgButton
			{
				anchors.verticalCenter: parent.verticalCenter
				height: 22
				width: 22
				action: clearLogAction
				iconSource: "qrc:/qml/img/cleariconactive.png"
			}

			Action {
				id: clearLogAction
				tooltip: qsTr("Clear")
				onTriggered: {
					logsPane.clear()
				}
			}

			CopyButton
			{
				height: 22
				width: 22
				anchors.verticalCenter: parent.verticalCenter
				getContent: function()
				{
					var content = "";
					for (var k = 0; k < logsModel.count; k++)
					{
						var log = logsModel.get(k);
						content += log.type + "\t" + log.level + "\t" + log.date + "\t" + log.content + "\n";
					}
					return content
				}
			}

			Rectangle
			{
				width: 120
				radius: 10
				height: 25
				color: "white"
				anchors.top: parent.top
				anchors.topMargin: 3
				id: rectSearch
				Image
				{
					id: searchImg
					source: "qrc:/qml/img/searchicon.png"
					fillMode: Image.PreserveAspectFit
					width: 20
					height: 25
					z: 3
					anchors.verticalCenter: parent.verticalCenter
				}

				DefaultTextField
				{
					id: searchBox
					height: parent.height
					z: 2
					width: 100
					anchors.left: searchImg.right
					anchors.leftMargin: -7
					font.family: logStyle.generic.layout.logLabelFont
					font.pixelSize: 12
					font.italic: true

					onTextChanged: {
						proxyModel.search(text);
					}

					style:
						TextFieldStyle {
						background: Rectangle {
							radius: 10
						}
					}
				}
			}
		}
	}

}
