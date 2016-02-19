var editor = CodeMirror(document.body, {
							lineNumbers: true,
							//styleActiveLine: true,
							matchBrackets: true,
							autofocus: true,
							gutters: ["CodeMirror-linenumbers", "breakpoints"],
							autoCloseBrackets: true,
							styleSelectedText: true
						});
var ternServer;

editor.setOption("theme", "inkpot");
editor.setOption("indentUnit", 4);
editor.setOption("indentWithTabs", true);
editor.setOption("fullScreen", true);

editor.changeRegistered = false;
editor.breakpointsChangeRegistered = false;

editor.on("change", function(eMirror, object) {
	editor.changeRegistered = true;
});

var mac = /Mac/.test(navigator.platform);
var extraKeys = {};
if (mac === true) {
	extraKeys["Cmd-V"] = function(cm) { cm.replaceSelection(clipboard); };
	extraKeys["Cmd-X"] = function(cm) { window.document.execCommand("cut"); };
	extraKeys["Cmd-C"] = function(cm) { window.document.execCommand("copy"); };
}

makeMarker = function() {
	var marker = document.createElement("div");
	marker.style.color = "#822";
	marker.innerHTML = "●";
	return marker;
};

toggleBreakpointLine = function(n) {
	var info = editor.lineInfo(n);
	editor.setGutterMarker(n, "breakpoints", info.gutterMarkers ? null : makeMarker());
	editor.breakpointsChangeRegistered = true;
}

editor.on("gutterClick", function(cm, n) {
	toggleBreakpointLine(n);
});

toggleBreakpoint = function() {
	var line = editor.getCursor().line;
	toggleBreakpointLine(line);
}

getTextChanged = function() {
	return editor.changeRegistered;
};

getText = function() {
	editor.changeRegistered = false;
	return editor.getValue();
};

getBreakpointsChanged = function() {
	return editor.changeRegistered || editor.breakpointsChangeRegistered;   //TODO: track new lines
};

getBreakpoints = function() {
	var locations = [];
	editor.breakpointsChangeRegistered = false;
	var doc = editor.doc;
	doc.iter(function(line) {
		if (line.gutterMarkers && line.gutterMarkers["breakpoints"]) {
			var l = doc.getLineNumber(line);
			locations.push({
							   start: editor.indexFromPos({ line: l, ch: 0}),
							   end: editor.indexFromPos({ line: l + 1, ch: 0})
						   });;
		}
	});
	return locations;
};

setTextBase64 = function(text) {
	editor.setValue(window.atob(text));
	editor.getDoc().clearHistory();
	editor.focus();
};

setText = function(text) {
	editor.setValue(text);
};

setMode = function(mode) {
	this.editor.setOption("mode", mode);

	if (mode === "javascript")
	{
		ternServer = new CodeMirror.TernServer({defs: [ ecma5Spec() ]});
		extraKeys["Ctrl-Space"] = function(cm) { ternServer.complete(cm); };
		extraKeys["Ctrl-I"] = function(cm) { ternServer.showType(cm); };
		extraKeys["Ctrl-O"] = function(cm) { ternServer.showDocs(cm); };
		extraKeys["Alt-."] = function(cm) { ternServer.jumpToDef(cm); };
		extraKeys["Alt-,"] = function(cm) { ternServer.jumpBack(cm); };
		extraKeys["Ctrl-Q"] = function(cm) { ternServer.rename(cm); };
		extraKeys["Ctrl-."] = function(cm) { ternServer.selectName(cm); };
		extraKeys["'.'"] = function(cm) { setTimeout(function() { ternServer.complete(cm); }, 100); throw CodeMirror.Pass; };
		editor.on("cursorActivity", function(cm) { ternServer.updateArgHints(cm); });
	}
	else if (mode === "solidity")
	{
		CodeMirror.commands.autocomplete = function(cm) {
			CodeMirror.showHint(cm, CodeMirror.hint.anyword);
		}
		extraKeys["Ctrl-Space"] = "autocomplete";
	}
	editor.setOption("extraKeys", extraKeys);
};

setClipboardBase64 = function(text) {
	clipboard = window.atob(text);
};

var executionMark
var executionGasUsed
highlightExecution = function(start, end, gasUsed) {
	if (executionMark)
		executionMark.clear();
	if (debugWarning)
		debugWarning.clear();
	if (executionGasUsed)
		executionGasUsed.remove()

	if (start > 0 && end > start) {
		executionMark = editor.markText(editor.posFromIndex(start), editor.posFromIndex(end), { className: "CodeMirror-exechighlight" });
		var line = editor.posFromIndex(start)
		var l = editor.getLine(line.line);
		editor.scrollIntoView(line);
		var endChar = { line: line.line, ch: line.ch + l.length };
		executionGasUsed = document.createElement("div");
		executionGasUsed.innerHTML = gasUsed + " gas";
		executionGasUsed.className = "CodeMirror-gasCost";
		editor.addWidget(endChar, executionGasUsed, false, "over");
	}
}

var basicHighlightMark = -1
basicHighlight = function (start, end)
{
	if (basicHighlightMark != -1)
	{
		editor.removeLineClass(basicHighlightMark, "background","CodeMirror-basicHighlight")
		basicHighlightMark = -1
	}
	var line = editor.posFromIndex(start)
	basicHighlightMark = line.line
	editor.addLineClass(line.line, "background","CodeMirror-basicHighlight")
	setTimeout(function(){
		if (basicHighlightMark != -1)
			editor.removeLineClass(basicHighlightMark, "background","CodeMirror-basicHighlight")
		basicHighlightMark = -1
	}, 500)
}

var changeId;
changeGeneration = function()
{
	changeId = editor.changeGeneration(true);
}

isClean = function()
{
	return editor.isClean(changeId);
}

var debugWarning = null;
showWarning = function(content)
{
	if (executionMark)
		executionMark.clear();
	if (debugWarning)
		debugWarning.clear();
	var node = document.createElement("div");
	node.id = "annotation"
	node.innerHTML = content;
	node.className = "CodeMirror-errorannotation-context";
	debugWarning = editor.addLineWidget(0, node, { coverGutter: false, above: true });
}

var annotations = [];
var compilationCompleteBool = true;
compilationError = function(currentSourceName, location, error, secondaryErrors)
{
	displayGasEstimation(false)
	compilationCompleteBool = false;
	if (compilationCompleteBool)
		return;
	clearAnnotations();
	location = JSON.parse(location);
	if (location.source === currentSourceName)
		ensureAnnotation(location, error, "first");
	var lineError = location.start.line + 1;
	var errorOrigin = "Source " + location.contractName + " line " + lineError;
	secondaryErrors = JSON.parse(secondaryErrors);
	for(var i in secondaryErrors)
	{
		if (secondaryErrors[i].source === currentSourceName)
			ensureAnnotation(secondaryErrors[i], errorOrigin, "second");
	}
}

ensureAnnotation = function(location, error, type)
{
	annotations.push({ "type": type, "annotation": new ErrorAnnotation(editor, location, error)});
}

clearAnnotations = function()
{
	for (var k in annotations)
		annotations[k].annotation.destroy();
	annotations.length = 0;
}

compilationComplete = function()
{
	clearAnnotations();
	compilationCompleteBool = true;
}

goToCompilationError = function()
{
	if (annotations.length > 0)
		editor.setCursor(annotations[0].annotation.location.start.line, annotations[0].annotation.location.start.column)
}

setCursor = function(c)
{
	var line = editor.posFromIndex(c)
	editor.setCursor(line);
}

setFontSize = function(size)
{
	editor.getWrapperElement().style["font-size"] = size + "px";
	editor.refresh();
	if (showingGasEstimation)
	{
		displayGasEstimation(false)
		displayGasEstimation(true)
	}
}

makeGasCostMarker = function(value) {
	var marker = document.createElement("div");
	marker.innerHTML = value;
	marker.className = "CodeMirror-gasCost";
	return marker;
};

var gasCosts = null;
setGasCosts = function(_gasCosts)
{
	gasCosts = JSON.parse(_gasCosts);
	if (showingGasEstimation)
	{
		displayGasEstimation(false);
		displayGasEstimation(true);
	}
}

var showingGasEstimation = false;
var gasMarkText = [];
var gasMarkRef = {};
displayGasEstimation = function(show)
{
	show = JSON.parse(show);
	showingGasEstimation = show;
	if (show)
	{
		var maxGas = 20000;
		var step = colorGradient.length / maxGas; // 20000 max gas
		clearGasMark();
		gasMarkText = [];
		gasMarkRef = {};
		for (var i in gasCosts)
		{
			if (gasCosts[i].gas !== "0")
			{
				var color;
				var colorIndex = Math.round(step * gasCosts[i].gas);
				if (gasCosts[i].isInfinite || colorIndex >= colorGradient.length)
					color = colorGradient[colorGradient.length - 1];
				else
					color = colorGradient[colorIndex];
				var className = "CodeMirror-gasCosts" + i;
				var line = editor.posFromIndex(gasCosts[i].start);
				var endChar;
				if (gasCosts[i].codeBlockType === "statement" || gasCosts[i].codeBlockType === "")
				{
					endChar = editor.posFromIndex(gasCosts[i].end);
					gasMarkText.push({ line: line, markText: editor.markText(line, endChar, { inclusiveLeft: true, inclusiveRight: true, handleMouseEvents: true, className: className, css: "background-color:" + color })});
				}
				else if (gasCosts[i].codeBlockType === "function" || gasCosts[i].codeBlockType === "constructor")
				{
					var l = editor.getLine(line.line);
					endChar = { line: line.line, ch: line.ch + l.length };
					var marker = document.createElement("div");
					marker.innerHTML = " max execution cost: " + gasCosts[i].gas + " gas";
					marker.className = "CodeMirror-gasCost";
					editor.addWidget(endChar, marker, false, "over");
					gasMarkText.push({ line: line.line, widget: marker });
				}
				gasMarkRef[className] = { ch: line.ch, line: line.line, value: gasCosts[i] };
			}
		}
		CodeMirror.on(editor.getWrapperElement(), "mouseover", listenMouseOver);
	}
	else
	{
		CodeMirror.off(editor.getWrapperElement(), "mouseover", listenMouseOver);
		clearGasMark();
		if (gasAnnotation)
		{
			gasAnnotation.clear();
			gasAnnotation = null;
		}
	}
}

function clearGasMark()
{
	if (gasMarkText)
		for (var k in gasMarkText)
		{
			if (gasMarkText[k] && gasMarkText[k].markText)
				gasMarkText[k].markText.clear();
			if (gasMarkText[k] && gasMarkText[k].widget)
				gasMarkText[k].widget.remove();
		}
}

var gasAnnotation;
function listenMouseOver(e)
{
	var node = e.target || e.srcElement;
	if (node)
	{
		if (node.className && node.className.indexOf("CodeMirror-gasCosts") !== -1)
		{
			if (gasAnnotation)
				gasAnnotation.clear();
			var cl = getGasCostClass(node);
			var gasTitle = gasMarkRef[cl].value.isInfinite ? "infinite" : gasMarkRef[cl].value.gas;
			var l = editor.getLine(gasMarkRef[cl].line);
			var endChar = { line: gasMarkRef[cl].line, ch: gasMarkRef[cl].ch + l.length + 10 };
			var marker = document.createElement("div");
			marker.innerHTML = gasTitle + " gas";
			marker.className = "CodeMirror-gasCost";
			editor.addWidget(endChar, marker, false, "over");
			gasAnnotation = marker
		}
		else if (gasAnnotation)
		{
			gasAnnotation.remove();
			gasAnnotation = null;
		}
	}
}

function getGasCostClass(node)
{
	var classes = node.className.split(" ");
	for (var k in classes)
	{
		if (classes[k].indexOf("CodeMirror-gasCosts") !== -1)
			return classes[k];
	}
	return "";
}

function setReadOnly(status)
{
	editor.setOption("readOnly", JSON.parse(status) ? "nocursor": false);
}

// blue => red ["#1515ED", "#1714EA", "#1914E8", "#1B14E6", "#1D14E4", "#1F14E2", "#2214E0", "#2414DE", "#2614DC", "#2813DA", "#2A13D8", "#2D13D6", "#2F13D4", "#3113D2", "#3313D0", "#3513CE", "#3713CC", "#3A12CA", "#3C12C8", "#3E12C6", "#4012C4", "#4212C2", "#4512C0", "#4712BE", "#4912BC", "#4B11BA", "#4D11B8", "#4F11B6", "#5211B4", "#5411B2", "#5611B0", "#5811AE", "#5A11AC", "#5D11AA", "#5F10A7", "#6110A5", "#6310A3", "#6510A1", "#67109F", "#6A109D", "#6C109B", "#6E1099", "#700F97", "#720F95", "#750F93", "#770F91", "#790F8F", "#7B0F8D", "#7D0F8B", "#7F0F89", "#820E87", "#840E85", "#860E83", "#880E81", "#8A0E7F", "#8D0E7D", "#8F0E7B", "#910E79", "#930D77", "#950D75", "#970D73", "#9A0D71", "#9C0D6F", "#9E0D6D", "#A00D6B", "#A20D69", "#A50D67", "#A70C64", "#A90C62", "#AB0C60", "#AD0C5E", "#AF0C5C", "#B20C5A", "#B40C58", "#B60C56", "#B80B54", "#BA0B52", "#BD0B50", "#BF0B4E", "#C10B4C", "#C30B4A", "#C50B48", "#C70B46", "#CA0A44", "#CC0A42", "#CE0A40", "#D00A3E", "#D20A3C", "#D50A3A", "#D70A38", "#D90A36", "#DB0934", "#DD0932", "#DF0930", "#E2092E", "#E4092C", "#E6092A", "#E80928", "#EA0926", "#ED0924"]
/* green => red */
var colorGradient = ["#39572C", "#39562B", "#3A552B", "#3A552B", "#3B542B", "#3B542B", "#3C532B", "#3C532B", "#3D522B", "#3E522B", "#3E512A", "#3F512A", "#3F502A", "#404F2A", "#404F2A", "#414E2A", "#414E2A", "#424D2A", "#434D2A", "#434C29", "#444C29", "#444B29", "#454B29", "#454A29", "#464929", "#464929", "#474829", "#484829", "#484728", "#494728", "#494628", "#4A4628", "#4A4528", "#4B4528", "#4B4428", "#4C4328", "#4D4328", "#4D4227", "#4E4227", "#4E4127", "#4F4127", "#4F4027", "#504027", "#503F27", "#513F27", "#523E27", "#523D26", "#533D26", "#533C26", "#543C26", "#543B26", "#553B26", "#553A26", "#563A26", "#573926", "#573925", "#583825", "#583725", "#593725", "#593625", "#5A3625", "#5A3525", "#5B3525", "#5C3425", "#5C3424", "#5D3324", "#5D3324", "#5E3224", "#5E3124", "#5F3124", "#5F3024", "#603024", "#612F24", "#612F23", "#622E23", "#622E23", "#632D23", "#632D23", "#642C23", "#642B23", "#652B23", "#662A23", "#662A22", "#672922", "#672922", "#682822", "#682822", "#692722", "#692722", "#6A2622", "#6B2522", "#6B2521", "#6C2421", "#6C2421", "#6D2321", "#6D2321", "#6E2221", "#6E2221", "#6F2121", "#702121"]
editor.setOption("extraKeys", extraKeys);

