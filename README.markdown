*With the release of Flash 11 (Oct 2011), Adobe has added native JSON support to Flash, which is significantly faster than anything that can be written in AS3. For projects that want to take advantage of this, while still staying compatible with Flash 9 and 10, there is a new argument in decodeJson and encodeJson that will use the native parser if it is available, giving developers the best of both words.*

actionjson includes four projects

decodeJson - A very fast JSON decoder
Around 5-8x faster than as3corelib's JSON decoder

encodeJson - A very fast json encoder
Around 3x faster than as3corelib's JSON encoder

JsonDecoderAsync - An asynchronous JSON parser
Can parse JSON in chunks, making it great for parsing large objects over time
Still around 2x faster than as3corelib's JSON decoder

JsonEncoderAsync - An asynchronous JSON encoder
Encodes JSON in chunks, for large objects that need to be encoded over time
Sadly, about the same speed as as3corelib's JSON encoder

Download the library as a swc here:
http://github.com/mherkender/actionjson/raw/master/actionjson.swc
