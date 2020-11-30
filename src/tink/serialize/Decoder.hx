package tink.serialize;

import haxe.io.*;
using haxe.io.Bytes;

@:genericBuild(tink.serialize.Decoder.build())
class Decoder<T> {
}

class DecoderBase {
  var wrapped:Bytes;
  var src:BytesData;
  var input:BytesInput;
  var pos:Int;
  var max:Int;

  public function new() {}

  function reset(data:Bytes) {
    wrapped = data;
    input = new BytesInput(data);
    src = data.getData();
    pos = 0;
    max = data.length;
  }

  function bytes() {
    var l = len();
    var ret = wrapped.sub(pos, l);
    pos += l;
    return ret;
  }

  function string()
    return bytes().toString();

  function float()
    return fromInput(i -> input.readFloat());

  inline function fromInput<X>(f:BytesInput->X) {
    input.position = pos;
    var ret = f(input);
    pos = input.position;
    return ret;
  }

  inline function esc()
    return src.fastGet(pos) == 0xFF && (++pos > 0);

  inline function len()
    return dynInt();

  inline function byte()
    return src.fastGet(pos++);

  function int32()
    return fromInput(i -> i.readInt32());

  function dynInt() {
    var ret = byte();
    return
      if (ret < 0x80) ret;
      else if (ret <= 0xC0)
        ((ret ^ 0x80)) << 8 | byte();
      else if (ret <= 0xE0)
        ((ret ^ 0xC0)) << 16 | (byte() << 8) | byte();
      else {
        int32();
      }
  }

  function readBool()
    return src.fastGet(pos++) == 1;
}