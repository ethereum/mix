import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.InverseMouseArea 1.0
import "js/ErrorLocationFormater.js" as ErrorLocationFormater
import "."

Rectangle {
	id: statusHeader
	objectName: "statusPane"
	property variant webPreview
	property alias currentStatus: logPane.currentStatus
	property bool projectLoaded: false

	function updateStatus(message)
	{
		if (!projectLoaded)
			return
		if (!message)
		{
			updateText(qsTr("Compiled successfully."), "")
			debugImg.state = "active";
			currentStatus = { "type": "Comp", "date": Qt.formatDateTime(new Date(), "hh:mm:ss"), "content": status.text, "level": "info" }
		}
		else
		{
			updateText(errorInfo.errorLocation + " " + errorInfo.errorDetail, "error")
			debugImg.state = "";
			currentStatus = { "type": "Comp", "date": Qt.formatDateTime(new Date(), "hh:mm:ss"), "content": status.text, "level": "error" }
		}
	}

	function infoMessage(text, type)
	{
		updateText(text, "")
		logPane.push("info", type, text);
		currentStatus = { "type": type, "date": Qt.formatDateTime(new Date(), "hh:mm:ss"), "content": text, "level": "info" }
	}

	function warningMessage(text, type)
	{
		if (!projectLoaded)
			return
		errorOccurred.visible = true
		updateText(text, "warning")
		logPane.push("warning", type, text);
		currentStatus = { "type": type, "date": Qt.formatDateTime(new Date(), "hh:mm:ss"), "content": text, "level": "warning" }
	}

	function errorMessage(text, type)
	{
		if (!projectLoaded)
			return
		errorOccurred.visible = true
		updateText(text, "error")
		logPane.push("error", type, text);
		currentStatus = { "type": type, "date": Qt.formatDateTime(new Date(), "hh:mm:ss"), "content": text, "level": "error" }
	}

	function updateText(text, state)
	{
		status.state = state
		status.text = text
		status.font.italic = false
	}

	function clear()
	{
		status.state = "";
		status.text = "<no log>";
		status.font.italic = true
		errorOccurred.visible = false
	}

	Component.onCompleted:
	{
		clear()
	}

	StatusPaneStyle {
		id: statusPaneStyle
	}

	Connections {
		target: webPreview
		onJavaScriptMessage:
		{
			if (_level === 0)
				infoMessage(_content, "JavaScript")
			else
			{
				var message = _sourceId.substring(_sourceId.lastIndexOf("/") + 1) + " - " + qsTr("line") + " " + _lineNb + " - " + _content;
				if (_level === 1)
					warningMessage(message, "JavaScript")
				else
					errorMessage(message, "JavaScript")
			}
		}
	}

	Connections {
		target: fileIo
		onFileIOInternalError: errorMessage(_error, "Run");
	}

	Connections {
		target: clientModel
		onRunStarted:
		{
			logPane.clear()
			infoMessage(qsTr("Running transactions"), "Run");
		}
		onRunFailed: errorMessage(format(_message), "Run");
		onRunComplete: infoMessage(qsTr("Run complete"), "Run");
		onNewBlock: infoMessage(qsTr("New block created"), "State");
		onInternalError: errorMessage(format(_message), "Run");

		function format(_message)
		{
			var formatted = _message.match(/(?:<dev::eth::)(.+)(?:>)/);
			if (!formatted)
				formatted = _message.match(/(?:<dev::)(.+)(?:>)/);
			if (formatted && formatted.length > 1)
				formatted = formatted[1];
			else
				return _message;

			var exceptionInfos = _message.match(/(?:tag_)(.+)/g);
			if (exceptionInfos !== null && exceptionInfos.length > 0)
				formatted += ": "
			for (var k in exceptionInfos)
				formatted += " " + exceptionInfos[k].replace("*]", "").replace("tag_", "").replace("=", "");
			return formatted;
		}
	}

	Connections {
		target: codeModel
		onCompilationComplete:
		{
			goToLine.visible = false;
			updateStatus();
		}

		onCompilationError:
		{
			goToLine.visible = true
			updateStatus(_error);
		}

		onCompilationInternalError:
		{
			updateStatus(_error);
		}
	}

	Connections
	{
		target: projectModel
		onProjectClosed:
		{
			projectLoaded = false
			statusHeader.clear()
			logPane.clear()
		}
		onProjectLoaded: projectLoaded = true
	}


	color: "transparent"
	anchors.fill: parent

	Rectangle {
		Image {
			anchors.left: parent.left
			anchors.leftMargin: 5
			source: "qrc:/qml/img/down.png"
			fillMode: Image.PreserveAspectFit
			width: 20
			anchors.verticalCenter: parent.verticalCenter
		}

		DefaultLabel
		{
			id: errorOccurred
			visible: false
			text: "!"
			color: "red"
			anchors.left: parent.right
			anchors.leftMargin: 5
			anchors.verticalCenter: parent.verticalCenter
		}

		id: statusContainer
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.verticalCenter: parent.verticalCenter
		radius: 3
		width: 600
		height: 25
		color: "#fcfbfc"

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
				if (appSettings.systemPointSize < mainApplication.systemPointSize)
					statusContainer.height = 25
				else
					statusContainer.height = 25 + appSettings.systemPointSize / 2
				status.updateWidth()
			}
		}

		DefaultText {
			anchors.verticalCenter: parent.verticalCenter
			anchors.horizontalCenter: parent.horizontalCenter
			font.family: "sans serif"
			objectName: "status"
			wrapMode: Text.WrapAnywhere
			elide: Text.ElideRight
			maximumLineCount: 1
			clip: true
			id: status
			states: [
				State {
					name: "error"
					PropertyChanges {
						target: status
						color: "red"
					}
					PropertyChanges {
						target: statusContainer
						color: "#fffcd5"
					}
				},
				State {
					name: "warning"
					PropertyChanges {
						target: status
						color: "orange"
					}
					PropertyChanges {
						target: statusContainer
						color: "#fffcd5"
					}
				}
			]
			onTextChanged:
			{
				updateWidth()
				toolTipInfo.tooltip = text;
			}

			function updateWidth()
			{
				if (text.length > 100 - (30 * appSettings.systemPointSize / mainApplication.systemPointSize))
				{
					width = parent.width - 10
					status.anchors.left = statusContainer.left
					status.anchors.leftMargin = 25
				}
				else
				{
					width = undefined
					status.anchors.left = undefined
					status.anchors.leftMargin = undefined
				}
			}
		}

		DefaultButton
		{
			anchors.fill: parent
			id: toolTip
			action: toolTipInfo
			text: ""
			z: 3
			style:
				ButtonStyle {
				background:Rectangle {
					color: "transparent"
				}
			}
			MouseArea {
				anchors.fill: parent
				onClicked: {
					var globalCoord = goToLineBtn.mapToItem(statusContainer, 0, 0);
					if (mouseX > globalCoord.x
							&& mouseX < globalCoord.x + goToLineBtn.width
							&& mouseY > globalCoord.y
							&& mouseY < globalCoord.y + goToLineBtn.height)
						goToCompilationError.trigger(goToLineBtn);
					else
						logsContainer.toggle();
				}
				cursorShape: Qt.PointingHandCursor
			}
		}

		Rectangle
		{
			visible: false
			color: "transparent"
			width: 40
			height: parent.height
			anchors.top: parent.top
			anchors.left: status.right
			anchors.leftMargin: 30
			id: goToLine
			RowLayout
			{
				anchors.fill: parent
				Rectangle
				{
					color: "transparent"
					anchors.fill: parent
					DefaultImgButton
					{
						z: 4
						anchors.centerIn: parent
						id: goToLineBtn
						text: ""
						width: 25
						height: 25
						action: goToCompilationError
						iconSource: "qrc:/qml/img/warningicon.png"
					}
				}
			}
		}

		Action {
			id: toolTipInfo
			tooltip: ""
		}

		Rectangle
		{
			id: logsShadow
			width: logsContainer.width + 5
			height: 0
			opacity: 0.3
			clip: true
			anchors.top: logsContainer.top
			anchors.margins: 4
			Rectangle {
				color: "gray"
				anchors.top: parent.top
				radius: 10
				id: roundRect
				height: parent.height
				width: parent.width
			}
		}

		Rectangle
		{
			InverseMouseArea
			{
				id: outsideClick
				anchors.fill: parent
				active: false
				onClickedOutside: {
					logsContainer.toggle();
				}
			}

			function toggle()
			{
				if (logsContainer.state === "opened")
				{
					statusContainer.visible = true
					logsContainer.state = "closed"
				}
				else if (logPane.length > 0)
				{
					statusContainer.visible = false
					logsContainer.state = "opened";
					logsContainer.focus = true;
					forceActiveFocus();
					calCoord()
					move()
				}
			}

			id: logsContainer
			width: 750
			anchors.top: statusContainer.bottom
			anchors.topMargin: 4
			visible: false
			radius: 10

			function calCoord()
			{
				if (!logsContainer.parent.parent)
					return
				var top = logsContainer;
				while (top.parent)
					top = top.parent
				var coordinates = logsContainer.mapToItem(top, 0, 0);
				logsContainer.parent = top;
				logsShadow.parent = top;
				top.onWidthChanged.connect(move)
				top.onHeightChanged.connect(move)
			}

			function move()
			{
				var statusGlobalCoord = status.mapToItem(null, 0, 0);
				logsContainer.x = statusGlobalCoord.x - logPane.contentXPos
				logsShadow.x = statusGlobalCoord.x - logPane.contentXPos
				logsShadow.z = 1
				logsContainer.z = 2
				if (Qt.platform.os === "osx")
				{
					logsContainer.y = statusGlobalCoord.y;
					logsShadow.y = statusGlobalCoord.y;
				}
			}

			LogsPaneStyle {
				id: logStyle
			}

			LogsPane
			{
				id: logPane
				statusPane: statusHeader
				onContentXPosChanged:
				{
					parent.move();
				}
			}

			states: [
				State {
					name: "opened";
					PropertyChanges { target: logsContainer; height: 500; visible: true }
					PropertyChanges { target: logsShadow; height: 500; visible: true }
					PropertyChanges { target: outsideClick; active: true }

				},
				State {
					name: "closed";
					PropertyChanges { target: logsContainer; height: 0; visible: false }
					PropertyChanges { target: statusContainer; width: 600; height: 30 }
					PropertyChanges { target: outsideClick; active: false }
					PropertyChanges { target: logsShadow; height: 0; visible: false }
				}
			]
		}
	}

	Rectangle
	{
		color: "transparent"
		width: 100
		height: parent.height
		anchors.top: parent.top
		anchors.right: parent.right
		RowLayout
		{
			anchors.fill: parent
			Rectangle
			{
				color: "transparent"
				anchors.fill: parent
				DefaultImgButton
				{
					anchors.right: parent.right
					anchors.rightMargin: 9
					anchors.verticalCenter: parent.verticalCenter
					id: debugImg
					text: ""
					iconSource: "qrc:/qml/img/bugiconactive.png"
					action: showHideRightPanelAction
				}
			}
		}
	}
}
