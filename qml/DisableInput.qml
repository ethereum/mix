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
	id: rootDisableInput
	readOnly: true
	property var originalText
	property string tooltip

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
		width: rootDisableInput.width
		color: "#cccccc"
		radius: 2
	}
}

	CopyButton
	{
		id: buttonCopy
		anchors.right: parent.right
		anchors.rightMargin: 1
		anchors.verticalCenter: parent.verticalCenter
		height: parent.height - 2
		width: 30
		tooltip: localPackageUrl.tooltip
		getContent: function()
		{
			return rootDisableInput.originalText;
		}
	}
}

