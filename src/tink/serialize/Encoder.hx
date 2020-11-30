package tink.serialize;

import haxe.io.*;

@:genericBuild(tink.serialize.Encoder.build())
class Encoder<T> {
}

class EncoderBase {
  var out:BytesBuffer;
  public function new() {}

  inline function string(s:String) {
    writeBytes(Bytes.ofString(s));//TODO: when possible, this should be avoided
  }

  inline function writeBytes(b:Bytes) {
    len(b.length);
    out.addBytes(b, 0, b.length);
  }

  inline function esc()
    out.addByte(0xFF);

  inline function writeBool(f)
    out.addByte(if (f) 1 else 0);

  inline function writeFloat(f)
    out.addFloat(f);

  inline function len(i:UInt)
    dynInt(i);

  function dynInt(i:UInt)
    if (i < 0x80) out.addByte(i);
    else if (i < 0x3FFF) {
      out.addByte((i >> 8) | 0x80);
      out.addByte(i & 0xFF);
    }
    else if (i < 0x1FFFFF) {
      out.addByte((i >> 16) | 0xC0);
      out.addByte((i >> 8) & 0xFF);
      out.addByte(i & 0xFF);
    }
    else {
      out.addByte(0xFE);
      out.addInt32(i);
    }
}