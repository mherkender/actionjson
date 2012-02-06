/*
 * Copyright 2010 Maximilian Herkender
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.brokenfunction.json {
	/**
	 * Convert a String or ByteArray from a JSON-encoded object to an actual
	 * object. It's better to supply a ByteArray, if possible, since a String will
	 * be converted to a ByteArray anyway. Keep in mind the endian or position of
	 * a ByteArray will not be preserved. Data in the ByteArray will not be
	 * modified.
	 *
	 * This should be compatible with all valid JSON, and may parse some kinds
	 * invalid JSON, but generally this is very strict.
	 *
	 * If the native JSON decoder is available (Flash 11+) it can be used instead if the allowNativeJson parser is available and the input is a string.
	 *
	 * @parameter input A JSON-encoded ByteArray or String.
	 * @parameter allowNativeJson Use the Native JSON.
	 * @return The object created by the JSON decoding.
	 * @see http://json.org/
	 */
	public const decodeJson:Function = initDecodeJson();
}

import flash.system.ApplicationDomain;
import flash.utils.ByteArray;

function initDecodeJson():Function {
	var position:uint;
	var byteInput:ByteArray;
	var char:uint;

	var nativeJson:Object;
	try {
		nativeJson = ApplicationDomain.currentDomain.getDefinition("JSON");
	} catch (e:ReferenceError) {
		// ignore
	}

	const charConvert:ByteArray = new ByteArray();
	charConvert.length = 0x100;// fill w/ 0's
	charConvert[0x22] = 0x22;// \" -> "
	charConvert[0x5c] = 0x5c;// \\ -> \
	charConvert[0x2f] = 0x2f;// \/ -> /
	charConvert[0x62] = 0x8;// \b -> backspace
	charConvert[0x66] = 0xc;// \f -> formfeed
	charConvert[0x6e] = 0xa;// \n -> newline
	charConvert[0x72] = 0xd;// \r -> carriage return
	charConvert[0x74] = 0x9;// \t -> horizontal tab

	const isNumberChar:ByteArray = new ByteArray();
	isNumberChar.length = 0x100;// fill w/ 0's
	isNumberChar[0x2b] = 1;// +
	isNumberChar[0x2d] = 1;// -
	isNumberChar[0x2e] = 1;// .
	isNumberChar[0x30] = 1;// 0
	isNumberChar[0x31] = 1;// 1
	isNumberChar[0x32] = 1;// 2
	isNumberChar[0x33] = 1;// 3
	isNumberChar[0x34] = 1;// 4
	isNumberChar[0x35] = 1;// 5
	isNumberChar[0x36] = 1;// 6
	isNumberChar[0x37] = 1;// 7
	isNumberChar[0x38] = 1;// 8
	isNumberChar[0x39] = 1;// 9
	isNumberChar[0x45] = 1;// E
	isNumberChar[0x65] = 1;// e

	// this is a trick to speed up the string parsing loop
	// 1 means go, 0 means stop
	const stringHelper:ByteArray = new ByteArray();
	stringHelper.length = 0x100;// fill w/ 0's
	var i:int = 0;
	while (i < 0x100) {
		stringHelper[i++] = 1;
	}
	stringHelper[0x22] = 0;// "
	stringHelper[0x5c] = 0;// \

	const isWhitespace:ByteArray = new ByteArray();
	isWhitespace.length = 0x100;// fill w/ 0's
	isWhitespace[0x9] = 1;// \t
	isWhitespace[0xa] = 1;// \n
	isWhitespace[0xd] = 1;// \r
	isWhitespace[0x20] = 1;// " "

	const parseNumber:Function = function():Number {
		if (position === 1) {
			byteInput.position = 0;
			return parseFloat(byteInput.readUTFBytes(byteInput.length));
		} else {
			byteInput.position = position - 1;
			while (isNumberChar[byteInput[position++]]) {}
			return Number(byteInput.readUTFBytes(position-- - byteInput.position - 1));
		}
	};

	const parseWhitespace:Function = function():Object {
		while (isWhitespace[byteInput[position]]) {
			position++;
		}
		return parse[byteInput[position++]]();
	};

	const parseStringEscaped:Function = function(result:String):String {
		do {
			// which special character is it?
			if ((char = byteInput[position++]) === 0x75) {// \uxxxx -> utf8 char
				byteInput.position = position;
				char = parseInt(byteInput.readUTFBytes(4), 16);
				position += 4;
			} else if (!(char = charConvert[char])) {
				throw new Error(
					"Unknown escaped character encountered at position " +
					(position - 1));
			} else {
				byteInput.position = position;
			}

			// write special character to result
			result += String.fromCharCode(char);

			while (stringHelper[byteInput[position++]]) {}

			// flush the buffered data to the result
			if ((position - 1) > byteInput.position) {
				result += byteInput.readUTFBytes((position - 1) - byteInput.position);
			}
		} while (byteInput[position - 1] === 0x5c);// == /

		return result;
	}

	// parse is a mapping of the first character of what's being parsed, to the
	// function that parses it
	const parse:Object = {
		0x22: function ():String {// "
			if (stringHelper[byteInput[position++]]) {
				byteInput.position = position - 1;

				// this tight loop is intended for simple strings, parseStringEscaped
				// will handle the more advanced cases
				while (stringHelper[byteInput[position++]]) {}

				if (byteInput[position - 1] === 0x5c) {// == \
					return parseStringEscaped(
						byteInput.readUTFBytes((position - 1) - byteInput.position));
				}
				return byteInput.readUTFBytes((position - 1) - byteInput.position);
			} else if (byteInput[position - 1] === 0x5c) {// == \
				return parseStringEscaped("");
			} else {
				return "";
			}
		},
		0x7b: function ():Object {// {
			while (isWhitespace[byteInput[position]]) {
				position++;
			}
			if (byteInput[position] === 0x7d) {// == }
				position++;
				return {};
			}

			var result:Object = {}, key:String;
			do {
				do {
					key = parse[byteInput[position++]]();
					if (byteInput[position] !== 0x3a) {// != :
						while (isWhitespace[byteInput[position]]) {
							position++;
						}
						if (byteInput[position++] !== 0x3a) {// != :
							throw new Error("Expected : at " + (position - 1));
						}
					} else {
						position++;
					}
					result[key] = parse[byteInput[position++]]();
				} while (byteInput[position++] === 0x2c);// == ,
				if (byteInput[position - 1] === 0x7d) {// == }
					return result;
				}
				while (isWhitespace[byteInput[position]]) {
					position++;
				}
			} while (byteInput[position++] === 0x2c);// == ,
			if (byteInput[position - 1] !== 0x7d) {// != }
				throw new Error("Expected , or } at " + (position - 1));
			}
			return result;
		},
		0x5b: function ():Object {// [
			while (isWhitespace[byteInput[position]]) {
				position++;
			}
			if (byteInput[position] === 0x5d) {// == ]
				position++;
				return [];
			}

			var result:Array = [];
			do {
				do {
					result[result.length] = parse[byteInput[position++]]();
				} while (byteInput[position++] === 0x2c);// == ,
				if (byteInput[position - 1] === 0x5d) {// != ]
					return result;
				}
				position--;
				while (isWhitespace[byteInput[position]]) {
					position++;
				}
			} while (byteInput[position++] === 0x2c);// == ,
			if (byteInput[position - 1] !== 0x5d) {// != ]
				throw new Error("Expected , or ] at " + (position - 1));
			}
			return result;
		},
		0x74: function ():Boolean {// t
			if (byteInput[position] === 0x72 &&
				byteInput[position + 1] === 0x75 &&
				byteInput[position + 2] === 0x65) {// == rue
				position += 3;
				return true;
			}
			throw new Error("Expected \"true\" at position " + position);
		},
		0x66: function ():Boolean {// f
			if (byteInput[position] === 0x61 &&
				byteInput[position + 1] === 0x6c &&
				byteInput[position + 2] === 0x73 &&
				byteInput[position + 3] === 0x65) {// == alse
				position += 4;
				return false;
			}
			throw new Error("Expected \"false\" at position " + (position - 1));
		},
		0x6e: function ():Object {// n
			if (byteInput[position] === 0x75 &&
				byteInput[position + 1] === 0x6c &&
				byteInput[position + 2] === 0x6c) {// == ull
				position += 3;
				return null;
			}
			throw new Error("Expected \"null\" at position " + position);
		},
		0x5d: function ():void {// ]
			throw new Error("Unexpected end of array at " + position);
		},
		0x7d: function ():void {// }
			throw new Error("Unexpected end of object at " + position);
		},
		0x2c: function ():void {// ,
			throw new Error("Unexpected comma at " + position);
		},
		0x2d: parseNumber,// -
		0x30: parseNumber,// 0
		0x31: parseNumber,// 1
		0x32: parseNumber,// 2
		0x33: parseNumber,// 3
		0x34: parseNumber,// 4
		0x35: parseNumber,// 5
		0x36: parseNumber,// 6
		0x37: parseNumber,// 7
		0x38: parseNumber,// 8
		0x39: parseNumber,// 9
		0xd: parseWhitespace,// \r
		0xa: parseWhitespace,// \n
		0x9: parseWhitespace,// \t
		0x20: parseWhitespace// " "
	};

	return function (input:*, allowNativeJson:Boolean = false):Object {
		// prepare the input
		if (input is String) {
			if (nativeJson && allowNativeJson) {
				return nativeJson.parse(input);
			} else {
				byteInput = new ByteArray();
				byteInput.writeUTFBytes(input as String);
			}
		} else if (input is ByteArray) {
			byteInput = input as ByteArray;
		} else {
			throw new Error("Unexpected input <" + input + ">");
		}

		position = 0;

		try {
			return parse[byteInput[position++]]();
		} catch (e:TypeError) {
			if (position - 1 < byteInput.length) {
				e.message = "Unexpected character " +
					String.fromCharCode(byteInput[position - 1]) +
					" (0x" + byteInput[position - 1].toString(16) + ")" +
					" at position " + (position - 1) + " (" + e.message + ")";
			}
			throw e;
		}
		return null;
	}
}
