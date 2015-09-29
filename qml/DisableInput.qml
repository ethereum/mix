import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper

DefaultTextField
{
	id: localPackageUrl
	readOnly: true
	property var originalText

	function init()
	{
		if (originalText)
		{
			text = originalText
			cursorPosition = 0
		}
	}

	onOriginalTextChanged:
	{
		init()
	}

	Component.onCompleted:
	{
		init()
	}

	style: TextFieldStyle {
		background: Rectangle
		{
		width: localPackageUrl.width
		color: "#cccccc"
		radius: 2
	}
}

	CopyButton
	{
		id: buttonCopy
		anchors.left: parent.right
		anchors.leftMargin: 7
		anchors.verticalCenter: parent.verticalCenter
		getContent: function()
		{
			return localPackageUrl.originalText;
		}
	}
}

