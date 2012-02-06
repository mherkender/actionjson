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
	 * Convert a String or ByteArray from an object to an a JSON-encoded string.
	 *
	 * This will either return the result as a string, or write it directly to
	 * an IDataOutput output stream if the "writeTo" argument is supplied.
	 *
	 * To take advantage of the native Flash JSON encoder, set allowNative to true. Since
	 * the behavior of the native encoder is slightly different when it comes to encoding
	 * specialized objects, this should only be used on input with simple objects, arrays,
	 * numbers, booleans and strings. Other features, like the toJson method, are not
	 * used. See the AS3 JSON reference (link below) for more information.
	 *
	 * Currently strictNumberSupport must be true and writeTo must be null to use
	 * native parsing. This may change, so only set allowNative to true if the differences
	 * are not important.
	 *
	 * Warning: Vectors are not supported, they will be encoded as empty objects.
	 *
	 * @parameter input An object to convert to JSON.
	 * @parameter writeTo An optional IDataOutput output stream to write data to.
	 * @parameter allowNativeJson Allow using native json encoding in certain situations. This
	 * changes the behavior of the encoder based on Flash version, so use it carefully.
	 * @return A valid JSON-encoded string if writeTo is not specified, otherwise
	 * null is returned.
	 * @see http://json.org/
	 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/JSON.html
	 */
	public const encodeJson:Function = initDecodeJson();
}

import flash.system.ApplicationDomain;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

function initDecodeJson():Function {
	var result:IDataOutput;
	var i:int, j:int, strLen:int, str:String, char:int;
	var tempBytes:ByteArray = new ByteArray();
	var blockNonFiniteNumbers:Boolean;

	var nativeJson:Object;
	try {
		nativeJson = ApplicationDomain.currentDomain.getDefinition("JSON");
	} catch (e:ReferenceError) {
		// ignore
	}


	const charConvert:Array = new Array(0x100);
	for (j = 0; j < 0xa; j++) {
		charConvert[j] = (j + 0x30) | 0x30303000;// 000[0-9]
	}
	for (; j < 0x10; j++) {
		charConvert[j] = (j + 0x37) | 0x30303000;// 000[A-F]
	}
	for (;j < 0x1a; j++) {
		charConvert[j] = (j + 0x20) | 0x30303100;// 00[1][0-9]
	}
	for (;j < 0x20; j++) {
		charConvert[j] = (j + 0x27) | 0x30303100;// 00[1][A-F]
	}
	for (;j < 0x100; j++) {
		charConvert[j] = j;
	}
	charConvert[0xa] = 0x5c6e; // \n
	charConvert[0xd] = 0x5c72; // \r
	charConvert[0x9] = 0x5c74; // \t
	charConvert[0x8] = 0x5c62; // \b
	charConvert[0xc] = 0x5c66; // \f
	charConvert[0x8] = 0x5c62; // \b
	charConvert[0x22] = 0x5c22; // \"
	charConvert[0x5c] = 0x5c5c; // \\
	// not necessary for valid json
	//charConvert[0x2f] = 0x5c2f; // \/
	charConvert[0x7f] = 0x30303746; // 007F

	const parseArray:Function = function (data:Array):void {
		result.writeByte(0x5b);// [
		var k:int = 0;
		var len:int = data.length - 1;
		if (len >= 0) {
			while (k < len) {
				parse[typeof data[k]](data[k]);
				result.writeByte(0x2c);// ,
				k++;
			}
			parse[typeof data[k]](data[k]);
		}
		result.writeByte(0x5d);// ]
	}
	const parseString:Function = function (data:String):void {
		result.writeByte(0x22);// "
		tempBytes.position = 0;
		tempBytes.length = 0;
		tempBytes.writeUTFBytes(data);
		i = 0;
		j = 0;
		strLen = tempBytes.length;
		while (j < strLen) {
			char = charConvert[tempBytes[j++]];
			if (char > 0x100) {
				if (j - 1 > i) {
					// flush buffered string
					result.writeBytes(tempBytes, i, (j - 1) - i);
				}
				if (char > 0x10000) {// \uxxxx (control character)
					result.writeShort(0x5c75);// \u
					result.writeUnsignedInt(char);
				} else {
					result.writeShort(char);
				}
				i = j;
			}
		}
		// flush the rest of the string
		if (strLen > i) {
			result.writeBytes(tempBytes, i, strLen - i);
		}
		result.writeByte(0x22);// "
	}

	const parse:Object = {
		"object": function (data:Object):void {
			if (data) {
				if (data is Array) {
					parseArray(data);
				} else {
					result.writeByte(0x7b);// {
					var first:Boolean = true;
					for (str in data) {
						if (first) {
							first = false;
						} else {
							result.writeByte(0x2c);// ,
						}
						parseString(str);
						result.writeByte(0x3a);// :
						parse[typeof data[str]](data[str]);
					}
					result.writeByte(0x7d);// }
				}
			} else {
				result.writeUnsignedInt(0x6e756c6c);// null
			}
		},
		"string": parseString,
		"number": function (data:Number):void {
			if (blockNonFiniteNumbers && !isFinite(data)) {
				throw new Error("Number " + data + " is not encodable");
			}
			result.writeUTFBytes(String(data));
		},
		"boolean": function (data:Boolean):void {
			if (data) {
				result.writeUnsignedInt(0x74727565);// true
			} else {
				result.writeByte(0x66);// f
				result.writeUnsignedInt(0x616c7365);// alse
			}
		},
		"xml": function (data:Object):void {
			if ((!data.toXMLString is Function) || (data = data.toXMLString() as String) == null) {
				throw new Error("unserializable XML object encountered");
			}
			parseString(data);
		},
		"undefined": function (data:Boolean):void {
			result.writeUnsignedInt(0x6e756c6c);// null
		}
	};

	return function (input:Object, writeTo:IDataOutput = null, strictNumberSupport:Boolean = false, allowNativeJson:Boolean = false):String {
		// prepare the input
		var byteOutput:ByteArray;
		blockNonFiniteNumbers = strictNumberSupport;
		try {
			if (writeTo) {
				result = writeTo;
				result.endian = "bigEndian";
				parse[typeof input](input);
				byteOutput.position = 0;
				return byteOutput.readUTFBytes(byteOutput.length);
			} else if (allowNativeJson && strictNumberSupport && nativeJson) {
				return nativeJson.stringify(input);
			} else {
				switch (typeof input) {
					case "xml":
						if ((!input.toXMLString is Function) || (input = input.toXMLString() as String) == null) {
							throw new Error("unserializable XML object encountered");
						}
					case "object":
					case "string":
						result = byteOutput = new ByteArray();
						result.endian = "bigEndian";
						parse[typeof input](input);
						byteOutput.position = 0;
						return byteOutput.readUTFBytes(byteOutput.length);
					case "number":
						if (blockNonFiniteNumbers && !isFinite(input as Number)) {
							throw new Error("Number " + input + " is not encodable");
						}
						return String(input);
					case "boolean":
						return input ? "true" : "false";
					case "undefined":
						return "null";
					default:
						throw new Error("Unexpected type \"" + (typeof input) + "\" encountered");
				}
			}
		} catch (e:TypeError) {
			throw new Error("Unexpected type encountered");
		}
		return null;
	}
}
