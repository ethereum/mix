import QtQuick 2.0

QtObject {

	function absoluteSize(rel)
	{
		return systemPointSize + rel;
	}

	property QtObject general: QtObject {
		property int leftMargin: 25
	}

	property QtObject title: QtObject {
		property string color: "#808080"
		property string background: "#f0f0f0"
		property int height: 40
		property int fontSize: absoluteSize(7);// 18
	}

	property QtObject documentsList: QtObject {
		property string background: "#f7f7f7"
		property string color: "#4d4d4d"
		property string sectionColor: "#808080"
		property string selectedColor: "white"
		property string highlightColor: "#accbf2"
		property int height: 30
		property int fileNameHeight: 25
		property int fontSize: absoluteSize(2)// 13
		property int sectionFontSize: absoluteSize(2)// 13
	}
}
