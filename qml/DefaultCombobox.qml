import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3

ComboBox {
	id: combo
	property variant rootItem
	signal updateView()

	function updateCombobox()
	{
		updateView()
	}

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
				target: rootItem
				onVisibleChanged:
				{
					if (rootItem && rootItem.visible)
						labelCombo.updateHeight()
				}
			}

			Connections
			{
				target: combo
				onVisibleChanged:
				{
					labelCombo.updateHeight()
				}
				onModelChanged:
				{
					labelCombo.updateHeight()
				}
				onUpdateView:
				{
					labelCombo.updateHeight()
				}
				onCurrentTextChanged:
				{
					labelCombo.updateHeight()
				}
				onCurrentIndexChanged:
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
				combo.height = appSettings.systemPointSize + 10
			}
		}
	}
}
}

