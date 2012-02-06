package com.brokenfunction.json {
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	import mx.utils.ObjectUtil;

	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.serialization.json.JSONEncoder;

	// conflicts with native JSON parser now
	//import com.rational.serialization.json.JSON;

	public class TestJson extends Sprite {
		public function TestJson() {
			checkDecode("true");
			checkDecode("false");
			checkDecode("null");
			checkDecode("\"string\"");
			checkDecode("\"\"");
			checkDecode("\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"", "\"\\\"\\\\/\\b\\f\\n\\r\\t\"");
			checkDecode("\"\\\"x\\\\x\\/x\\bx\\fx\\nx\\rx\\t\"", "\"\\\"x\\\\x/x\\bx\\fx\\nx\\rx\\t\"");
			checkDecode("\"test\\u0021unicode\"", "\"test!unicode\"");
			checkDecode("\"test\\u222Bunicode\\u222b\"", "\"test\u222Bunicode\u222b\"");
			checkDecode("\"test\\u00f7unicode\"", "\"test\u00f7unicode\"");
			checkDecode("\"\\u0021unicode\"", "\"\u0021unicode\"");
			checkDecode("\"unicode\\u0021\"", "\"unicode\u0021\"");
			checkDecode("123", "123", true);
			checkDecode("123e1", "1230", true);
			checkDecode("0.1", "0.1", true);
			checkDecode("123.1", "123.1", true);
			checkDecode("-123.1", "-123.1", true);
			checkDecode("123e1", "1230", true);
			checkDecode("123e+1", "1230", true);
			checkDecode("123e-1", "12.3", true);
			checkDecode("123E-1", "12.3", true);
			checkDecode("123e-001", "12.3", true);
			checkDecode("[]");
			checkDecode("[\r\n\t ]","[]");
			checkDecode("[\"string\",null,true,false,1]");
			checkDecode(
				"[ \"string\" ,\rnull\r,\ntrue\n,\tfalse\t,\r1\r]",
				"[\"string\",null,true,false,1]");
			checkDecode("[\"test\\u0021\"]", "[\"test\u0021\"]");
			checkDecode("{}");
			checkDecode("{\r\n\t }","{}");
			checkDecode("{\"test\":{\"test\":{\"test\":\"sdfsdf\"}}}");
			checkDecode(
				"{\r\"test\"\r:\n{\n\"test\"\t:\t{ \"test\" :\r\"sdfsdf\"\n}\t} }",
				"{\"test\":{\"test\":{\"test\":\"sdfsdf\"}}}");
			checkDecode("{\"test\":\"sdfsdf\",\"test\":\"sdfsdf\"}", "{\"test\":\"sdfsdf\"}");
			checkDecode("[\"test\",43243,{\"test\":\"sdfsdf\"},4343]");
			checkDecode("[\"string\",null,true,false,1,{\"string\":\"string\"}]");
			checkDecodeMulti("{\"test\":\"sdfsdf\",\"test2\":\"sdfsdf\"}", [
				"{\"test\":\"sdfsdf\",\"test2\":\"sdfsdf\"}",
				"{\"test2\":\"sdfsdf\",\"test\":\"sdfsdf\"}"]);
			checkDecodeMulti("{\"a\":143,\"b\":232}", [
				"{\"a\":143,\"b\":232}","{\"b\":232,\"a\":143}"]);
			checkDecodeMulti("{\"a\":\"test\",\"b\":2}", [
				"{\"a\":\"test\",\"b\":2}","{\"b\":1,\"a\":\"test\"}"]);
			checkDecodeMulti("{\"a\":1,\"b\":\"test\"}", [
				"{\"a\":1,\"b\":\"test\"}","{\"b\":\"test\",\"a\":1}"]);
			checkDecodeMulti("{\"a\":234,\"c\":[1,2,3,242342298e10,-1235],\"d\":[{\"a\":\"test\",\"b\":\"test\"}]}",[
				"{\"d\":[{\"b\":\"test\",\"a\":\"test\"}],\"c\":[1,2,3,242342298e10,-1235],\"a\":234}"]);
			checkEncode(true);
			checkEncode(false);
			checkEncode(null);
			checkEncode("string");
			checkEncode("\"\\/\b\f\n\r\t");
			checkEncode("\u0021");
			checkEncode("\u222B");
			checkEncode("\u00f7");
			checkEncode("x\u222Bx");
			checkEncode(123);
			checkEncode(uint.MAX_VALUE);
			checkEncode(int.MIN_VALUE);
			checkEncode(Number.MAX_VALUE);
			checkEncode(Number.MIN_VALUE);
			checkEncode([]);
			checkEncode(["test"]);
			checkEncode([true, false]);
			checkEncode([0, 1, 2]);
			checkEncode(["string",null,true,false,1,{"string":"string"}]);
			checkEncode({});
			checkEncode({"test": "test"});
			checkEncode({"a": 1, "b": 2});
			checkEncode({"a": 1, "b": 2, "c": 3});
			checkEncode({
				a: 234,
				c: [1, 2, 3, 242342298e10, -1235],
				d: [{a: "test", b: "test"}]
			});
			checkEncode(
				"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f" +
				"\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f" +
				"\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f" +
				"\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f" +
				"\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f" +
				"\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f" +
				"\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f" +
				"\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f",
				"\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\\b\\t\\n\\u000B\\f\\r" +
				"\\u000E\\u000F\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\\u0018" +
				"\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F !\\\"#$%&'()*+,-./0123456789" +
				":;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\\u007F\"");
			checkEncode(<xml/>, "\"<xml/>\"");
			checkEncode(<test alt="hello"><ol><li alt="world&gt;&lt;">world&gt;&lt;</li></ol></test>, "\"<test alt=\\\"hello\\\">\\n  <ol>\\n    <li alt=\\\"world>&lt;\\\">world&gt;&lt;</li>\\n  </ol>\\n</test>\"");
			checkEncode(<li alt="world&gt;&lt;"/>.attribute("alt"), "\"world>&lt;\"");

			trace("All tests passed");

			testDecode(
				"true",
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) (new JSONDecoder(data)).getValue();},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) (new JsonDecoderAsync(data)).result;},
				function (data:ByteArray):void {
					for (var i:int = 0; i < 30000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) JSON.parse(data);}
			);
			testDecode(
				"\"test string\"",
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) (new JSONDecoder(data)).getValue();},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) (new JsonDecoderAsync(data)).result;},
				function (data:ByteArray):void {
					for (var i:int = 0; i < 30000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) JSON.parse(data);}
			);
			testDecode(
				"-123e5",
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) (new JSONDecoder(data)).getValue();},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) (new JsonDecoderAsync(data)).result;},
				function (data:ByteArray):void {
					for (var i:int = 0; i < 30000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 30000; i++) JSON.parse(data);}
			);
			testDecode(
				"[1,2,3]",
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) (new JSONDecoder(data)).getValue();},
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) (new JsonDecoderAsync(data)).result;},
				function (data:ByteArray):void {
					for (var i:int = 0; i < 10000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) JSON.parse(data);}
			);
			testDecode(
				"{\"test\":\"sdfsdf\",\"test2\":\"sdfsdf\"}",
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) (new JSONDecoder(data)).getValue();},
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) (new JsonDecoderAsync(data)).result;},
				function (data:ByteArray):void {
					for (var i:int = 0; i < 10000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 10000; i++) JSON.parse(data);}
			);
			testDecode(
				encodeJson({
					a: 234,
					b: [{a: "x", b: "test string\r\ntest string"}],
					c: [1, 2, 3, 242342298e10, -1235],
					d: [
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"}]
				}),
				function (data:String):void {
					for (var i:int = 0; i < 1000; i++) (new JSONDecoder(data)).getValue();},
				function (data:String):void {
					for (var i:int = 0; i < 1000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 1000; i++) (new JsonDecoderAsync(data)).result;},
				function (data:ByteArray):void {
					for (var i:int = 0; i < 1000; i++) decodeJson(data);},
				function (data:String):void {
					for (var i:int = 0; i < 1000; i++) JSON.parse(data);}
			);
			testEncode(
				true,
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) (new JsonEncoderAsync(data)).result;}
			);
			testEncode(
				-123e4,
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) (new JsonEncoderAsync(data)).result;}
			);
			testEncode(
				"this is a string",
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 100000; i++) (new JsonEncoderAsync(data)).result;}
			);
			testEncode(
				"this is a much longer string to understand the effect the size of the string has on the results",
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) (new JsonEncoderAsync(data)).result;}
			);
			testEncode(
				[Number.MIN_VALUE, "test", null],
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 10000; i++) (new JsonEncoderAsync(data)).result;}
			);
			testEncode(
				{a:12345, b:null},
				function (data:Object):void {
					for (var i:int = 0; i < 30000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 30000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 30000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 30000; i++) (new JsonEncoderAsync(data)).result;}
			);
			testEncode(
				{
					a: 234,
					b: [{a: "x", b: "test string\r\ntest string"}],
					c: [1, 2, 3, 242342298e10, -1235],
					d: [
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"},
						{a: "test", b: "test"},{a: "test", b: "test"}]
				},
				function (data:Object):void {
					for (var i:int = 0; i < 1000; i++) (new JSONEncoder(data)).getString();},
				function (data:Object):void {
					for (var i:int = 0; i < 1000; i++) encodeJson(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 1000; i++) JSON.stringify(data);},
				function (data:Object):void {
					for (var i:int = 0; i < 1000; i++) (new JsonEncoderAsync(data)).result;}
			);
		}

		public function checkDecode(input:String, expectedResult:String = "", isNumber:Boolean = false):void {
			if (!expectedResult) {
				expectedResult = input;
			}
			checkDecode2(input, expectedResult, isNumber);

			// trailing characters should be ignored
			checkDecode3(input, "\"", expectedResult, isNumber);
			checkDecode3(input, "]", expectedResult, isNumber);
			checkDecode3(input, "}x8!", expectedResult, isNumber);

			// try combining it with something else
			checkDecode2("{\"test\":" + input + "}", "{\"test\":" + expectedResult + "}", false);
			checkDecode2("\n\r\t " + input + "\n\r\t ", expectedResult, false);
			checkDecode2("[[2],[[[" + input + "]],[5]]]", "[[2],[[[" + expectedResult + "]],[5]]]", false);
			checkDecode2("{\"a\":{\"b\":{\"c\":" + input + "}}}", "{\"a\":{\"b\":{\"c\":" + expectedResult + "}}}", false);
			checkDecode2("[" + input + "]", "[" + expectedResult + "]", false);
			checkDecode2("[\"x\"," + input + ",54564]", "[\"x\"," + expectedResult + ",54564]", false);
			checkDecode2("[" + input + "," + input + "]", "[" + expectedResult + "," + expectedResult + "]", false);
			checkDecode2("[\n\r\t " + input + "\n\r\t ,\n\r\t " + input + "\n\r\t ]", "[" + expectedResult + "," + expectedResult + "]", false);
			checkDecode2("{\"a\":{\"b\":{\"c\":\n\r\t " + input + "\n\r\t }}}", "{\"a\":{\"b\":{\"c\":" + expectedResult + "}}}", false);
			checkDecode2("{ \"a\" : " + input + " , \"b\": [" + input + "] }", "{\"b\":[" + expectedResult + "],\"a\":" + expectedResult + "}", false);
		}

		public function checkDecodeMulti(input:String, possibleResults:Array):void {
			var i:int = possibleResults.length;
			var errors:String;
			while (i-- > 0) {
				try {
					checkDecode(input, possibleResults[i]);
					return;
				} catch (e:Error) {
					errors += e.getStackTrace() + "\n\n";
					continue;
				}
			}
		}

		public function checkDecode2(input:String, expectedResult:String, isNumber:Boolean):void {
			// try the fast decoder
			try {
				trace(input+" -> " + expectedResult);
				var result:Object = decodeJson(input);
				var adobeResult:Object = (new JSONEncoder(expectedResult)).getString();
				if (ObjectUtil.compare(result, adobeResult) == 0) {
					throw new Error("Result: " + adobeResult);
				}
			} catch (e:Error) {
				throw new Error("JSONEncoder(decodeJson()) failed: " + input + " -> " + expectedResult + "\n" + e.getStackTrace() + "\n\n");
			}

			// try the fast decoder, with optional native JSON support
			try {
				trace(input+" -> " + expectedResult + " (w/ optional native JSON)");
				result = decodeJson(input, true);
				adobeResult = (new JSONEncoder(expectedResult)).getString();
				if (ObjectUtil.compare(result, adobeResult) == 0) {
					throw new Error("Result: " + adobeResult);
				}
			} catch (e:Error) {
				throw new Error("JSONEncoder(decodeJson()) (w/ native JSON) failed: " + input + " -> " + expectedResult + "\n" + e.getStackTrace() + "\n\n");
			}


			// try the async decoder
			try {
				trace(input+" -> " + expectedResult + " (async)");
				result = (new JsonDecoderAsync(input)).result;
				adobeResult = (new JSONEncoder(expectedResult)).getString();
				if (ObjectUtil.compare(result, adobeResult) == 0) {
					throw new Error("Result: " + adobeResult);
				}
			} catch (e:Error) {
				throw new Error("JSONEncoder(JsonDecoderAsync()) failed: " + input + " -> " + expectedResult + "\n" + e.getStackTrace() + "\n\n");
			}

			// try the async decoder, but only give one byte at a time
			try {
				trace(input+" -> " + expectedResult + " (async 2)");
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(input);
				bytes.position = 0;
				var bytes2:ByteArray = new ByteArray();

				var asyncDecoder:JsonDecoderAsync = new JsonDecoderAsync(bytes2, false);
				while (bytes.position < bytes.length) {
					bytes.readBytes(bytes2, bytes2.length, 1);
					asyncDecoder.process();
				}

				result = asyncDecoder.result;
				adobeResult = (new JSONEncoder(expectedResult)).getString();
				if (ObjectUtil.compare(result, adobeResult) == 0) {
					throw new Error("Result: " + adobeResult);
				}
			} catch (e:Error) {
				throw new Error("JSONEncoder(JsonDecoderAsync()) (socket version) failed: " + input + " -> " + expectedResult + "\n" + e.getStackTrace() + "\n\n");
			}

			// try the async decoder, but use limit
			if (!isNumber) {
				try {
					trace(input+" -> " + expectedResult + " (async 3)");
					asyncDecoder = new JsonDecoderAsync(input, false);
					while (!asyncDecoder.process(3)) {};
					adobeResult = (new JSONEncoder(expectedResult)).getString();
					if (ObjectUtil.compare(asyncDecoder.result, adobeResult) == 0) {
						throw new Error("Result: " + adobeResult);
					}
				} catch (e:Error) {
					throw new Error("JSONEncoder(JsonDecoderAsync()) (limit version) failed: " + input + " -> " + expectedResult + "\n" + e.getStackTrace() + "\n\n");
				}
			}
		}

		public function checkDecode3(input:String, extraChars:String, expectedResult:String, isNumber:Boolean):void {
			// try the async decoder, but make sure it doesn't read past the end of the string
			try {
				trace(input+" -> " + expectedResult + " (async extra chars)");
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(input + extraChars);
				bytes.position = 0;
				var bytes2:ByteArray = new ByteArray();

				var asyncDecoder:JsonDecoderAsync = new JsonDecoderAsync(bytes2, false);
				while (bytes.position < bytes.length) {
					bytes.readBytes(bytes2, bytes2.length, 1);
					asyncDecoder.process();
				}

				var result:Object = asyncDecoder.result;
				var adobeResult:String = (new JSONEncoder(expectedResult)).getString();
				if (ObjectUtil.compare(asyncDecoder.result, adobeResult) == 0) {
					throw new Error("Result: " + adobeResult);
				}
				if (!isNumber && bytes2.position != input.length) {
					throw new Error("JsonDecoderAsync read past the end of the string, " + input.length + " to " + bytes2.position);
				}
			} catch (e:Error) {
				throw new Error("JSONEncoder(JsonDecoderAsync()) (extra chars) failed: " + input + extraChars + " -> " + expectedResult + "\n" + e.getStackTrace() + "\n\n");
			}
		}

		public function checkEncode(input:Object, expectedResult:String = ""):void {
			if (!expectedResult) {
				expectedResult = (new JSONEncoder(input)).getString();;
			}
			checkEncode2(input, expectedResult);
			checkEncode2({"test":input}, "{\"test\":" + expectedResult + "}");
			checkEncode2([input], "[" + expectedResult + "]");
			checkEncode2([[],[9,9],[[[input]],[]]], "[[],[9,9],[[[" + expectedResult + "]],[]]]");
			checkEncode2(["x",input,54564], "[\"x\"," + expectedResult + ",54564]");
			checkEncode2([input,input],"[" + expectedResult + "," + expectedResult + "]");
		}

		public function checkEncode2(input:Object, expectedResult:String):void {
			// try the fast encoder
			try {
				trace("encodeJson(" + expectedResult + ")");
				var result:String = encodeJson(input);
				if (expectedResult != result) {
					throw new Error("Result: " + result);
				}
			} catch (e:Error) {
				throw new Error("encodeJson(" + expectedResult + ") failed\n" + e.getStackTrace() + "\n\n");
			}
      
			// try the fast encode w/ optional native JSON
			try {
				trace("encodeJson(" + expectedResult + ") (w/ optional native JSON)");
				result = encodeJson(input, null, false, true);
				if (expectedResult != result) {
					throw new Error("Result: " + result);
				}
			} catch (e:Error) {
				throw new Error("encodeJson(" + expectedResult + ") (w/ optional native JSON) failed\n" + e.getStackTrace() + "\n\n");
			}

			// try the async encoder
			try {
				trace("JsonEncoderAsync(" + expectedResult + ")");
				result = (new JsonEncoderAsync(input)).result;
				if (expectedResult != result) {
					throw new Error("Result: " + result);
				}
			} catch (e:Error) {
				throw new Error("JsonEncoderAsync(" + expectedResult + ") failed\n" + e.getStackTrace() + "\n\n");
			}

			// try the async encoder, but limit it
			try {
				trace("JsonEncoderAsync(" + expectedResult + ") (limited)");
				var asyncDecoder:JsonEncoderAsync = new JsonEncoderAsync(input);
				var chunks:int = 0;
				while (!asyncDecoder.process(1)) {
					chunks++;
				};
				trace("Note: " + chunks + " chunks");
				result = asyncDecoder.result;
				if (expectedResult != result) {
					throw new Error("Result: " + result);
				}
			} catch (e:Error) {
				throw new Error("JsonEncoderAsync(" + expectedResult + ") failed\n" + e.getStackTrace() + "\n\n");
			}
		}

		public function testDecode(data:String, adobeTest:Function, fastTest:Function, asyncTest:Function, fastTest2:Function, nativeJsonTest:Function):void {
			var time:uint;
			var resultAdobe:uint = 0;
			var resultFast:uint = 0;
			var resultAsync:uint = 0;
			var resultFast2:uint = 0;
			var resultNativeJson:uint = 0;

			var dataBytes:ByteArray = new ByteArray();
			dataBytes.writeUTFBytes(data);

			time = getTimer();
			adobeTest(data);
			resultAdobe += getTimer() - time;

			time = getTimer();
			fastTest(data);
			resultFast += getTimer() - time;

			time = getTimer();
			asyncTest(data);
			resultAsync += getTimer() - time;

			time = getTimer();
			nativeJsonTest(data);
			resultNativeJson += getTimer() - time;

			time = getTimer();
			fastTest2(dataBytes);
			resultFast2 += getTimer() - time;

			time = getTimer();
			asyncTest(data);
			resultAsync += getTimer() - time;

			time = getTimer();
			fastTest(data);
			resultFast += getTimer() - time;

			time = getTimer();
			fastTest2(dataBytes);
			resultFast2 += getTimer() - time;

			time = getTimer();
			adobeTest(data);
			resultAdobe += getTimer() - time;

			time = getTimer();
			nativeJsonTest(data);
			resultNativeJson += getTimer() - time;

			trace("");
			trace("Decoding results for " + data);
			trace("decodeJson improvement: " + (Math.floor(100 * resultAdobe / resultFast) / 100) + "x");
			trace("decodeJson improvement (w/o String overhead): " + (Math.floor(100 * resultAdobe / resultFast2) / 100) + "x");
			trace("JsonDecoderAsync improvement: " + (Math.floor(100 * resultAdobe / resultAsync) / 100) + "x");
			trace("Native JSON improvement: " + (Math.floor(100 * resultAdobe / resultNativeJson) / 100) + "x");
		}

		public function testEncode(data:Object, adobeTest:Function, fastTest:Function, nativeJsonTest:Function, asyncTest:Function):void {
			var time:uint;
			var resultAdobe:uint = 0;
			var resultFast:uint = 0;
			var resultNativeJson:uint = 0;
			var resultAsync:uint = 0;

			time = getTimer();
			adobeTest(data);
			resultAdobe += getTimer() - time;

			time = getTimer();
			asyncTest(data);
			resultAsync += getTimer() - time;

			time = getTimer();
			nativeJsonTest(data);
			resultNativeJson += getTimer() - time;

			time = getTimer();
			fastTest(data);
			resultFast += getTimer() - time;

			time = getTimer();
			adobeTest(data);
			resultAdobe += getTimer() - time;

			time = getTimer();
			fastTest(data);
			resultFast += getTimer() - time;

			time = getTimer();
			nativeJsonTest(data);
			resultNativeJson += getTimer() - time;

			time = getTimer();
			asyncTest(data);
			resultAsync += getTimer() - time;

			trace("");
			trace("Encoding results for " + encodeJson(data));
			trace("encodeJson improvement: " + (Math.floor(100 * resultAdobe / resultFast) / 100) + "x");
			trace("JsonDecoderAsync improvement: " + (Math.floor(100 * resultAdobe / resultAsync) / 100) + "x");
			trace("Native JSON improvement: " + (Math.floor(100 * resultAdobe / resultNativeJson) / 100) + "x");
		}
	}
}
