import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0

DefaultButton
{
	property var getContent;
	Image
	{
		width: 20
		height: 20
		anchors.centerIn: parent
		source: "qrc:/qml/img/copyiconactive.png"
	}
	tooltip: qsTr("Copy to clipboard")
	width: 35
	height: 28
	onClicked:
	{
		clipboard.text = getContent()
	}
}

