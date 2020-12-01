package tink;

import haxe.macro.*;
import haxe.io.*;

#if macro
using tink.MacroApi;
#end

class Serialize {
  static macro public function decode(e:ExprOf<Bytes>):Expr {
    return
      switch e {
        case macro ($e : $ct):
          macro new tink.serialize.Decoder<$ct>().tryDecode($e);
        case _:
          switch Context.getExpectedType() {
            case null:
              e.reject('Cannot determine expected type');
            case t:
              var ct = t.toComplex();
              macro @:pos(e.pos) new tink.serialize.Decoder<$ct>().decode($e);
          }
      }
  }

  static macro public function encode(e:Expr):ExprOf<Bytes> {
    var t = e.typeof().sure();
    var ct = t.toComplex();
    return macro @:pos(e.pos) new tink.serialize.Encoder<$ct>().encode($e);
  }
}