package tink.serialize;

import haxe.io.*;
using haxe.io.Bytes;

@:genericBuild(tink.serialize.Encoder.build())
class Encoder<T> {
}

#if js
private class BytesBuffer {
  static inline var CHUNK_SIZE:Int = 0x10000;
  var index = 0;
  var prev = new Array<js.lib.Uint8Array>();
  var cur:js.lib.Uint8Array;

  public function new() {
    cur = alloc();
  }

  function next() {
    prev.push(cur);
    cur = alloc();
  }

  public function getBytes() {
    var total = index + CHUNK_SIZE * prev.length;
    var out = new js.lib.Uint8Array(total);
    var pos = 0;
    for (buf in prev)
      for (byte in buf)
        out[pos++] = byte;
    for (i in 0...index)
      out[pos++] = cur[i];
    free();
    return Bytes.ofData(cast out);
  }

  function free() {
    POOL.push(cur);
    for (b in prev)
      POOL.push(b);
  }

  public function addInt32(i:Int) {
    MINI.setInt32(0, i, true);
    for (i in 0...4)
      addByte(MINI.getUint8(i));
  }

  public function addDouble(f:Float) {
    MINI.setFloat64(0, f, true);
    for (i in 0...8)
      addByte(MINI.getUint8(i));

  }

  public inline function addByte(b:Int) {
    cur[index++] = b;
    if (index == CHUNK_SIZE)
      next();
  }

  static final MINI = new js.lib.DataView(new js.lib.ArrayBuffer(8));

  public function addBytes(bytes:Bytes, pos:Int, length:Int) {
    var data = bytes.getData();
    for (i in 0...length)
      addByte(data.fastGet(pos + i));
  }

  static final POOL = [];
  static function alloc()
    return switch POOL.pop() {
      case null: new js.lib.Uint8Array(CHUNK_SIZE);
      case v: v;
    }
}
#end
class EncoderBase {
  var out:BytesBuffer;
  // var strings = new Map();
  // var stringCounter = 0;
  public function new() {}
  function reset()
    out = new BytesBuffer();
  function string(s:String) {
    // if (s.length < 100)
    //   switch strings[s] {
    //     case null:
    //       strings[s] = stringCounter++;
    //     case v:
    //       out.addByte(0xFD);
    //       len(v);
    //       return;
    //   }
    writeString(s);
  }

  function writeString(s:String) {
    var i = 0,
        max = s.length;
    while (i < max) {
      var c:Int = StringTools.fastCodeAt(s, i++);
      // surrogate pair
      if (0xD800 <= c && c <= 0xDBFF)
        c = (c - 0xD7C0 << 10) | (StringTools.fastCodeAt(s, i++) & 0x3FF);
      if (c <= 0x7F)
        out.addByte(c);
      else if (c <= 0x7FF) {
        out.addByte(0xC0 | (c >> 6));
        out.addByte(0x80 | (c & 63));
      } else if (c <= 0xFFFF) {
        out.addByte(0xE0 | (c >> 12));
        out.addByte(0x80 | ((c >> 6) & 63));
        out.addByte(0x80 | (c & 63));
      } else {
        out.addByte(0xF0 | (c >> 18));
        out.addByte(0x80 | ((c >> 12) & 63));
        out.addByte(0x80 | ((c >> 6) & 63));
        out.addByte(0x80 | (c & 63));
      }
    }
    esc();
  }

  inline function bytes(b:Bytes) {
    len(b.length);
    out.addBytes(b, 0, b.length);
  }

  inline function esc()
    out.addByte(0xFF);

  inline function writeBool(f)
    out.addByte(if (f) 1 else 0);

  inline function writeFloat(f)
    out.addDouble(f);

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