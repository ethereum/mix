function isScientificNumber(_value)
{
	var nbRegEx = new RegExp('^[0-9]+$');
	var n = _value.toLowerCase().split("e")
	if (n.length === 2)
		return nbRegEx.test(n[0].replace(".", "")) && nbRegEx.test(n[1].replace("-", ""));
	return false
}

function isNumber(_value)
{
	if (!isNaN(_value))
		_value = _value.toString();
	var nbRegEx = new RegExp('^[0-9]+$');
	return nbRegEx.test(_value.replace(/"/g, "").replace(/'/g, "").replace(".", ""))
}

function toFlatNumber(_value)
{
	var s = _value.split("e")
	var e = parseInt(s[1])
	var number = s[0]
	var floatValue;
	if (number.indexOf(".") !== -1)
		floatValue = number.split(".")
	else
		floatValue = [ number , "" ]

	var k = 0
	var floatPos = floatValue[0].length
	var d = e > 0 ? 1 : -1
	var n = floatValue[0] + floatValue[1]
	while (k < Math.abs(e))
	{
		floatPos = floatPos + d
		if (floatPos <= 0)
			n = "0" + n
		else if (floatPos > n.length)
			n = n + "0"
		k++
	}

	var ret = n.slice(0, floatPos < 0 ? 1 : Math.abs(floatPos)) + "." + n.slice(floatPos < 0 ? 1 : Math.abs(floatPos));

	if (ret.indexOf(".") === ret.length - 1)
		ret = ret.replace(".", "")
	return normalize(ret)
}

function removeTrailingZero(_value)
{
	var j = _value.length - 1
	while (j >= 0)
	{
		if (_value[j] !== "0")
			break
		j--
	}
	return _value.substring(0, j)
}

function removeLeadingZero(_value)
{
	var j = 0
	while (j < _value.length)
	{
		if (_value[j] !== "0")
			break
		j++
	}
	return _value.substring(j)
}

function normalize(_value)
{
	if (!isNaN(_value))
		_value = _value.toString()
	var val = _value
	var splitted = _value.split(".")
	if (splitted.length > 1)
	{
		if (splitted[0].replace(/0/g, "") === "")
			val =  "0." + removeTrailingZero(splitted[1])
		else
			val = removeLeadingZero(splitted[0]) + "." + removeTrailingZero(splitted[1])
	}
	else
		return removeLeadingZero(_value)
}

function toScientificNumber(_value)
{
	var val = normalize(_value)
	if (val.indexOf(".") !== -1)
		val = _value.replace(".", "")
	var k = 0
	var zeroPos = {}
	zeroPos[0] = 0
	var current = 0
	while (k < val.length)
	{
		if (val[k] !== "0")
		{
			zeroPos[k] = 0
			current = k
		}
		else
			zeroPos[current]++
		k++
	}
	var ret;
	if (val.indexOf("0") === 0)
		ret = val.substring(zeroPos[0]) + "e-" + zeroPos[0]
	else
		ret = val.substring(0, current + 1) + "e" + zeroPos[current]
	return ret
}

function shouldConvertToScientific(_value)
{
	return normalize(_value).length > 7
}
