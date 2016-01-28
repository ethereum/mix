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
/** @file errorannotation.js
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

function ErrorAnnotation(editor, location, content)
{
	this.location = location;
	this.opened = false;
	this.rawContent = content;
	this.content = content.replace("Contract Error:", "");
	this.editor = editor;
	this.errorMark = null;
	this.lineWidget = null;
	this.init();
	if (this.content)
		this.open();
}

ErrorAnnotation.prototype.init = function()
{
	this.errorMark = editor.markText({ line: this.location.start.line, ch: this.location.start.column }, { line: this.location.end.line, ch: this.location.end.column }, { className: "CodeMirror-errorannotation", inclusiveRight: true });
}

ErrorAnnotation.prototype.open = function()
{
	if (this.location.start.line)
	{
		var node = document.createElement("div");
		node.id = "annotation"
		node.innerHTML = this.content;
		node.className = "CodeMirror-errorannotation-context";
		this.lineWidget = this.editor.addLineWidget(this.location.start.line, node, { coverGutter: false });
		this.opened = true;
	}
}

ErrorAnnotation.prototype.close = function()
{
	if (this.lineWidget)
		this.lineWidget.clear();
	this.opened = false;
}

ErrorAnnotation.prototype.destroy = function()
{
	if (this.opened)
		this.close();
	if (this.errorMark)
		this.errorMark.clear();
}
