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
	import flash.errors.EOFError;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;

	public class JsonDecoderAsync {
		private static const _charConvert:ByteArray = new ByteArray();

		private var _input:IDataInput;
		private var _result:* = undefined;
		private var _buffer:ByteArray = new ByteArray();

		public var parseTopLevelNumbers:Boolean = true;
		public var trailingByte:int = -1;

		/**
		 * The _stack is pretty simple, the last number represents what is currently
		 * being processed.
		 * <pre>
		 * </pre>
		 * @private
		 */
		private var _stack:Array = [-1];

		public function JsonDecoderAsync(input:*, autoSubscribe:Boolean = true):void {
			// prepare the input
			if (input is IDataInput) {
				_input = input as IDataInput;
			} else if (input is String) {
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(input as String);
				bytes.position = 0;
				_input = bytes;
			} else {
				throw new Error("Unexpected input <" + input + ">");
			}

			_input.endian = "bigEndian";

			if (autoSubscribe) {
				var dispatch:IEventDispatcher = input as IEventDispatcher;
				if (dispatch) {
					// dispatched by Sockets
					dispatch.addEventListener(ProgressEvent.SOCKET_DATA, progressHandler, false, 0, true);

					// dispatched by URLStreams
					dispatch.addEventListener(ProgressEvent.PROGRESS, progressHandler, false, 0, true);
				}
				process();
			}

			if (!_charConvert.length) {
				_charConvert.length = 0x100;// fill w/ 0's
				_charConvert[0x22] = 0x22;// \" -> "
				_charConvert[0x5c] = 0x5c;// \\ -> \
				_charConvert[0x2f] = 0x2f;// \/ -> /
				_charConvert[0x62] = 0x8;// \b -> backspace
				_charConvert[0x66] = 0xc;// \f -> formfeed
				_charConvert[0x6e] = 0xa;// \n -> newline
				_charConvert[0x72] = 0xd;// \r -> carriage return
				_charConvert[0x74] = 0x9;// \t -> horizontal tab
			}
		}

		private function progressHandler(e:ProgressEvent):void {
			process();
		}

		public function get result():* {
			return _result;
		}

		public function process(limit:uint = 0):Boolean {
			if (_stack.length <= 0) {
				return true;
			}

			var startAvailable:uint = _input.bytesAvailable;
			var result:Object, char:int;
			try {
				mainloop:while (_stack.length > 0) {
					switch (_stack[_stack.length - 1]) {
						case -1:// start parsing an unknown value
							_stack[_stack.length - 1] = _input.readUnsignedByte();
							continue mainloop;

						case 0x22: // " (parse a string)
							if (limit > 0) {
								// limited version
								while ((char = _input.readUnsignedByte()) !== 0x22) {// != "
									if (char === 0x5c) {// == \
										_stack[_stack.length - 1] = 0x200;
										continue mainloop;
									} else {
										_buffer.writeByte(char);
									}
									if (startAvailable - _input.bytesAvailable >= limit) {
										return false;
									}
								}
							} else {
								// unlimited version
								while ((char = _input.readUnsignedByte()) !== 0x22) {// != "
									if (char === 0x5c) {// == \
										_stack[_stack.length - 1] = 0x200;
										continue mainloop;
									} else {
										_buffer.writeByte(char);
									}
								}
							}
							// string over
							_buffer.position = 0;
							result = _buffer.readUTFBytes(_buffer.length);
							_buffer.length = 0;
							_stack.pop();
							continue mainloop;
						case 0x200:// parse the rest of a escape (\x)
							if ((char = _input.readUnsignedByte()) !== 0x75) {// \uxxxx
								char = _charConvert[char];
								if (char !== 0) {
									_stack[_stack.length - 1] = 0x22;
									_buffer.writeByte(char);
								} else {
									throw new Error("Unexpected escape character");
								}
								continue mainloop;
							}
							_stack[_stack.length - 1] = 0x201;
						case 0x201:// parse the rest of a unicode escape (\uxxxx)
							if (_input.bytesAvailable >= 4) {
								char = parseInt(_input.readUTFBytes(4), 16);
								// write the new character out as utf8
								if (char <= 0x7f) {
									_buffer.writeByte(char);
								} else if (char < 0x7ff) {
									_buffer.writeShort(0xC080 |
										((char << 2) & 0x1f00) | (char & 0x3f));
								} else {
									_buffer.writeByte(0xE0 | ((char >> 12) & 0xf));
									_buffer.writeShort(0x8080 |
										((char << 2) & 0x3f00) | (char & 0x3f));
								}
								_stack[_stack.length - 1] = 0x22;
								continue mainloop;
							}
							return false;

						case 0x7b: // { (start parsing an object)
							if ((char = _input.readUnsignedByte()) === 0x7d) {// == }
								result = {};
								_stack.pop();
							} else if (char === 0x22) {// == "
								_stack[_stack.length - 1] = {};// the object being created
								_stack[_stack.length] = null;// the current property being parsed
								_stack[_stack.length] = 0x300;// object parser, next stage
								_stack[_stack.length] = 0x22;// string parser (for the property)
							} else {
								throw new Error("Unexpected character 0x" + char.toString(16) + " at the start of object");
							}
							continue mainloop;
						case 0x300:// key (string) has been parsed
							_stack[_stack.length - 2] = result;
							_stack[_stack.length - 1] = 0x301;
						case 0x301:// parse : and value
							if ((char = _input.readUnsignedByte()) !== 0x3a) {// == :
								throw new Error("Expected : during object parsing, not 0x" + char.toString(16));
							}
							_stack[_stack.length - 1] = 0x302;
							_stack[_stack.length] = -1;
							continue mainloop;
						case 0x302:// value has been parsed
							_stack[_stack.length - 3][_stack[_stack.length - 2]] = result;
							_stack[_stack.length - 1] = 0x303;
						case 0x303: // continue or end object
							if ((char = _input.readUnsignedByte()) === 0x2c) {// == ,
								_stack[_stack.length - 1] = 0x304;
								if (limit > 0 && startAvailable - _input.bytesAvailable >= limit) {
									return false;
								}
							} else if (char === 0x7d) {// == }
								result = _stack[_stack.length - 3];
								_stack.length -= 3;
								continue mainloop;
							} else {
								throw new Error("Expected , or } during object parsing, not 0x" + char.toString(16));
							}
						case 0x304: // ensure next key is a string
							if (_input.readUnsignedByte() === 0x22) {// != "
								_stack[_stack.length - 1] = 0x300;
								_stack[_stack.length] = 0x22;
							} else {
								throw new Error("Expected \" during object parsing, not 0x" + char.toString(16));
							}
							continue mainloop;

						case 0x5b: // [ (start parsing an array)
							if ((char = _input.readUnsignedByte()) === 0x5d) {// == ]
								result = [];
								_stack.pop();
								continue mainloop;
							}
							_stack[_stack.length - 1] = [];// the array being created
							_stack[_stack.length] = 0x400;// object parser, next stage
							_stack[_stack.length] = char;// value parser
							continue mainloop;
						case 0x400:// value has been parsed
							(_stack[_stack.length - 2] as Array).push(result);
							_stack[_stack.length - 1] = 0x401;
						case 0x401:// continue or end array
							if ((char = _input.readUnsignedByte()) === 0x2c) {// == ,
								_stack[_stack.length - 1] = 0x400;
								_stack[_stack.length] = -1;
								if (limit > 0 && startAvailable - _input.bytesAvailable >= limit) {
									return false;
								}
							} else if (char === 0x5d) {// == ]
								result = _stack[_stack.length - 2];
								_stack.length -= 2;
							} else {
								throw new Error("Expected , or ] during array parsing, not 0x" + char.toString(16));
							}
							continue mainloop;

						case 0x74: // t (start parsing true)
							if (_input.bytesAvailable >= 3) {
								if (_input.readShort() === 0x7275 && _input.readUnsignedByte() === 0x65) {// == rue
									result = true;
									_stack.pop();
									continue mainloop;
								} else {
									throw new Error("Expected \"true\"");
								}
							}
							return false;
						case 0x66: // f (start parsing false)
							if (_input.bytesAvailable >= 4) {
								if (_input.readInt() === 0x616c7365) {// == alse
									result = false;
									_stack.pop();
									continue mainloop;
								} else {
									throw new Error("Expected \"false\"");
								}
							}
							return false;
						case 0x6e: // n (start parsing null)
							if (_input.bytesAvailable >= 3) {
								if (_input.readShort() === 0x756c && _input.readUnsignedByte() == 0x6c) {// == ull
									result = null;
									_stack.pop();
									continue mainloop;
								} else {
									throw new Error("Expected \"null\"");
								}
							}
							return false;

						case 0x100:// number parser when the number isn't the only value
							while ((char = _input.readUnsignedByte()) !== 0x5d &&
								char !== 0x7d && char !== 0x2c) {// is it ",", "]", or "}"?
								_buffer.writeByte(char);
							}

							_buffer.position = 0;
							result = Number(_buffer.readUTFBytes(_buffer.length));
							_buffer.length = 0;

							// have to do this here, since we've read too far into the input
							if (_stack[_stack.length - 2] == 0x302) {// an object is being parsed
								if (char === 0x2c) {// == ,
									_stack.pop();
									_stack[_stack.length - 1] = 0x304;
								} else if (char === 0x7d) {// == }
									_stack[_stack.length - 4][_stack[_stack.length - 3]] = result;
									result = _stack[_stack.length - 4];
									_stack.length -= 4;
								} else {
									throw new Error("Unexpected ] while parsing object");
								}
							} else if (_stack[_stack.length - 2] == 0x400) {// an array is being parsed
								if (char === 0x2c) {// == ,
									(_stack[_stack.length - 3] as Array).push(result);
									_stack[_stack.length - 1] = -1;
								} else if (char === 0x5d) {// == ]
									(_stack[_stack.length - 3] as Array).push(result);
									result = _stack[_stack.length - 3];
									_stack.length -= 3;
								} else {
									throw new Error("Unexpected } while parsing array");
								}
							}
							continue mainloop;

						case 0x101:// number parser when the number is the only value
							while (_input.bytesAvailable) {
								if (((char = _input.readUnsignedByte()) >= 0x30 && char <= 0x39) ||
									char == 0x65 || char == 0x45 || char == 0x2e ||
									char == 0x2b || char == 0x2d) {// 0-9, e, E, ., +, -
									_buffer.writeByte(char);
								} else {
									trailingByte = char;
									_buffer.position = 0;
									result = Number(_buffer.readUTFBytes(_buffer.length));
									_buffer.length = 0;
									_stack.pop();
									continue mainloop;
								}
							}
							// parse the current number anyway, in case this is the end
							_buffer.position = 0;
							_result = Number(_buffer.readUTFBytes(_buffer.length));
							return false;

						default:
							// test for the other number cases, otherwise it's invalid
							char = _stack[_stack.length - 1];
							if (char === 0x2d || (char >= 0x30 && char <= 0x39)) {// - or 0-9
								if (_stack.length <= 1) {
									if (parseTopLevelNumbers) {
										_stack[_stack.length - 1] = 0x101;
									} else {
										throw new Error("Top level number encountered");
									}
								} else {
									_stack[_stack.length - 1] = 0x100;
								}
								_buffer.writeByte(char);
								continue mainloop;
							} else {
								throw new Error("Unexpected character 0x" + char.toString(16) + ", expecting a value");
							}
							break;
					}
				}
			} catch (e:EOFError) {
				return false;
			} catch (e:Error) {
				// Parsing failed, nothing left to do
				_stack.length = 0;
				throw e;
			}
			if (_stack.length <= 0) {
				_result = result;
				return true;
			} else {
				return false;
			}
		}
	}
}
