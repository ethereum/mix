/*
	This file is part of cpp-ethereum.
	cpp-ethereum is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	cpp-ethereum is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	You should have received a copy of the GNU General Public License
	along with cpp-ethereum.  If not, see <http://www.gnu.org/licenses/>.
*/
/** @file QBoolTypeView.qml
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

import QtQuick 2.0
import QtQuick.Controls 1.3
import "js/InputValidator.js" as InputValidator

Item
{
	id: editRoot
	property string value
	property string defaultValue
	property bool readOnly: !boolCombo.enabled
	property string subType
	height: 20
	width: 150

	onReadOnlyChanged: {
		boolCombo.enabled = !readOnly;
	}

	function isArray()
	{
		InputValidator.init()
		return InputValidator.isArray(subType)
	}

	function init()
	{
		if (!isArray())
		{
			boolArray.visible = false
			boolCombo.visible = true

			value = format(value)

			var setValue = "1"
			if (value === "")
				setValue = parseInt(defaultValue);
			else
				setValue = parseInt(value);
			boolCombo.checked = setValue === 1 ? true: false
			boolCombo.enabled = !readOnly;
		}
		else
		{
			boolArray.visible = true
			boolCombo.visible = false
			if (value === "")
				boolArray.text = "[]"
			else
				boolArray.text = value

			var formattedparam = []
			var param = JSON.parse(boolArray.text)
			for (var k in JSON.parse(boolArray.text))
				formattedparam.push(parseInt(format(param[k])))
			boolArray.text = JSON.stringify(formattedparam)
		}
	}

	function finalize()
	{
		if (isArray())
			value = boolArray.text
	}

	function format(value)
	{
		value = value === true ? "1" : value
		value = value === false ? "0" : value;
		value = value === "true" ? "1" : value
		value = value === "false" ? "0" : value;
		return value
	}

	Rectangle {
		color: "transparent"
		anchors.fill: parent
		CheckBox
		{
			property bool inited;
			Component.onCompleted:
			{
				init();
				inited = true;
			}

			id: boolCombo
			anchors.fill: parent
			onCheckedChanged:
			{
				if (inited)
					value = checked ? "1" : "0"

			}
			text: qsTr("True")
		}

		DefaultTextField
		{
			id: boolArray
			onTextChanged:
			{
				value = text
			}
		}
	}
}



