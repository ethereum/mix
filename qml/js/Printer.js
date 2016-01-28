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
/** @file Printer.js
 * @author Yann yann@ethdev.com
 * @author Arkadiy Paronyan arkadiy@ethdev.com
 * @date 2015
 * Ethereum IDE client.
 */

var prettyPrint = (function () {
    function pp(object, indent) {
        try {
            JSON.stringify(object, null, 2); 
        } catch (e) {
            return pp(e, indent);
        }

        var str = "";
        if(object instanceof Array) {
            str += "[";
            for(var i = 0, l = object.length; i < l; i++) {
                str += pp(object[i], indent);
                if(i < l-1) {
                    str += ", ";
                }
            }
            str += " ]";
        } else if (object instanceof Error) {
            str += "\e[31m" + "Error:\e[0m " + object.message; 
        } else if (isBigNumber(object)) {
            str += "\e[32m'" + object.toString(10) + "'";
        } else if(typeof(object) === "object") {
            str += "{\n";
            indent += "  ";
            var last = getFields(object).pop()
            getFields(object).forEach(function (k) {
                str += indent + k + ": ";
                try {
                    str += pp(object[k], indent);
                } catch (e) {
                    str += pp(e, indent);
                }
                if(k !== last) {
                    str += ",";
                }
                str += "\n";
            });
            str += indent.substr(2, indent.length) + "}";
        } else if(typeof(object) === "string") {
            str += "\e[32m'" + object + "'"; 
        } else if(typeof(object) === "undefined") {
            str += "\e[1m\e[30m" + object;
        } else if(typeof(object) === "number") {
            str += "\e[31m" + object;
        } else if(typeof(object) === "function") {
            str += "\e[35m[Function]";
        } else {
            str += object;
        }
        str += "\e[0m";
        return str;
    }
    var redundantFields = [
        'valueOf',
        'toString',
        'toLocaleString',
        'hasOwnProperty',
        'isPrototypeOf',
        'propertyIsEnumerable',
        'constructor',
        '__defineGetter__',
        '__defineSetter__',
        '__lookupGetter__',
        '__lookupSetter__',
        '__proto__'
    ];
    var getFields = function (object) {
        var result = Object.getOwnPropertyNames(object);
        if (object.constructor && object.constructor.prototype) {
            result = result.concat(Object.getOwnPropertyNames(object.constructor.prototype));
        }
        return result.filter(function (field) {
            return redundantFields.indexOf(field) === -1;
        });
    };
    var isBigNumber = function (object) {
        return typeof BigNumber !== 'undefined' && object instanceof BigNumber;
    };
    function prettyPrintI(/* */) {
        var args = arguments;
        var ret = "";
        for (var i = 0, l = args.length; i < l; i++) {
    	    ret += pp(args[i], "") + "\n";
        }
        return ret;
    }
    return prettyPrintI;
})();

