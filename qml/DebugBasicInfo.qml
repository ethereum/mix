import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1

RowLayout {
	property string titleStr

	function update(_value)
	{
		currentStepValue.text = _value;
	}

	Rectangle {
		Layout.minimumWidth: 120
		height: parent.height
		color: "#e5e5e5"
		id: row
		Component.onCompleted:
		{
			updateLayout()
		}

		function updateLayout()
		{
			if (mainApplication.systemPointSize >= appSettings.systemPointSize)
			{
				row.Layout.minimumWidth = 120
			}
			else
			{
				row.Layout.minimumWidth = 120 + (appSettings.systemPointSize * 6)
			}
		}

		Connections
		{
			target: appSettings
			onSystemPointSizeChanged:
			{
				row.updateLayout()
			}
		}

		DefaultLabel
		{
			id: title
			anchors.centerIn: parent
			color: "#a2a2a2"
			font.family: "Sans Serif"
			text: titleStr
		}
	}
	DefaultLabel
	{
		id: currentStepValue
	}
}
