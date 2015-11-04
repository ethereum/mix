import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3

ComboBox {
	id: combo

	style: ComboBoxStyle
	{
	label:
		Rectangle {
		anchors.fill: parent
		color: "transparent"
		DefaultLabel {
			id: labelCombo
			anchors.verticalCenter: parent.verticalCenter
			text: currentText

			Connections
			{
				target: combo
				onVisibleChanged:
				{
					labelCombo.updateHeight()
				}
			}

			Connections
			{
				target: appSettings
				onSystemPointSizeChanged:
				{
					labelCombo.updateHeight()
				}

				Component.onCompleted:
				{
					labelCombo.updateHeight()
				}
			}

			function updateHeight()
			{
				combo.height = labelCombo.font.pixelSize + 10
			}
		}
	}
}
}

