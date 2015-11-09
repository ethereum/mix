import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import org.ethereum.qml.QSolidityType 1.0

Column
{
	id: root
	property alias members: repeater.model  //js array
	property variant accounts
	property var value: ({})
	property int blockIndex
	property int transactionIndex
	property string context
	property bool readOnly
	property variant parentDefinition
	Layout.fillWidth: true
	spacing: 10
	property int colHeight

	function setSpacing(sp)
	{
		root.spacing = sp
	}

	function set(_members, _values)
	{
		typeLoader.members = []
		typeLoader.value = {}
		typeLoader.value = _values
		typeLoader.members = _members
	}

	function clear()
	{
		value = {}
		members = []
		colHeight = 0
	}

	Repeater
	{
		id: repeater
		visible: members ? members.length > 0 : false
		RowLayout
		{
			id: row
			Layout.fillWidth: true

			Component.onCompleted:
			{
				if (members[index])
				{
					var scale = 10 * appSettings.systemPointSize / mainApplication.systemPointSize
					if (QSolidityType.Address === members[index].type.category && members[index].type.array && context === "parameter")
						height = 50 + scale
					else
						height = 10 + scale + (members[index].type.category === QSolidityType.Struct ? (25 * members[index].type.members.length) : 0)
					root.colHeight += height
				}
			}

			Rectangle
			{
				Layout.preferredWidth: 150
				id: labelVar
				anchors.top: parent.top
				Layout.preferredHeight: parent.height
				color: "transparent"
				Row
				{
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					DefaultLabel
					{
						id: nameLabel
						text: modelData ? modelData.name : ""
						anchors.verticalCenter: parent.verticalCenter
					}

					DefaultLabel
					{
						id: typeLabel
						text: modelData ? " (" + modelData.type.name + ")" : ""
						font.italic: true
						font.weight: Font.Light
						anchors.verticalCenter: parent.verticalCenter
					}
				}
			}

			Loader
			{
				id: typeLoader
				sourceComponent:
				{
					if (!modelData)
						return undefined
					var t = modelData.type.category;
					if (t === QSolidityType.SignedInteger || t === QSolidityType.UnsignedInteger)
						return Qt.createComponent("qrc:/qml/QIntTypeView.qml");
					else if (t === QSolidityType.Bool)
						return Qt.createComponent("qrc:/qml/QBoolTypeView.qml");
					else if (t === QSolidityType.Bytes || t === QSolidityType.String)
						return Qt.createComponent("qrc:/qml/QStringTypeView.qml");
					else if (t === QSolidityType.Hash)
						return Qt.createComponent("qrc:/qml/QHashTypeView.qml");
					else if (t === QSolidityType.Struct)
						return Qt.createComponent("qrc:/qml/StructView.qml");
					else if (t === QSolidityType.Enum)
						return Qt.createComponent("qrc:/qml/QIntTypeView.qml");
					else if (t === QSolidityType.Address)
						return Qt.createComponent("qrc:/qml/QAddressView.qml");
					else
						return undefined;
				}
				onLoaded:
				{
					var ptype = members[index].type;
					var pname = members[index].name;
					var vals = value

					item.readOnly = context === "variable";
					if (ptype.category === QSolidityType.Address)
					{
						item.accounts = accounts
						item.value = getValue();
						if (context === "parameter")
						{
							var dec = modelData.type.name.split(" ");
							item.subType = dec[0];
							item.load();
						}
					}
					else if (ptype.category === QSolidityType.Struct && !item.members)
					{
						var val = {}
						for (var k in members[index].type.members)
						{
							var param = members[index].type.members[k]
							val[param.name] = vals[pname][param.name]
						}
						item.value = val
						item.members = members[index].type.members
					}
					else if (ptype.category === QSolidityType.Bool)
						item.subType = modelData.type.name
					else
						item.value = getValue();

					if (item.init)
						item.init()

					item.onValueChanged.connect(function() {
						syncValue(vals, pname)
					});

					var newWidth = nameLabel.width + typeLabel.width + item.width + 108;
					if (root.width < newWidth)
						root.width = newWidth;

					syncValue(vals, pname)
				}

				function syncValue(vals, pname)
				{
					vals[pname] = item.value;
					valueChanged();
				}

				function getValue()
				{
					var r = "";
					if (value && value[modelData.name] !== undefined)
						r = value[modelData.name];
					else if (modelData.type.category === QSolidityType.Struct)
						r = {};
					if (Array.isArray(r))
						r = r.join(", ");
					return r;
				}
			}
		}
	}
}
