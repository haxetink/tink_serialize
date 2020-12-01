import tink.serialize.*;

@:asserts
class Primitives {
  public function new() {

  }

  function byte(b:Int) {
    return [for (i in 0...8) if (b & (0x80 >> i) == 0) '0' else '1'].join('');
  }

  function binary(i:Int)
    return (switch i >> 8 {
      case 0: '';
      case v: binary(v) + ' ';
    }) + byte(i);

  public function ints() {
    var enc = new Encoder<Int>(),
        dec = new Decoder<Int>();

    var ints = [for (i in 0...32) 1 << i];
    ints.unshift(0);

    var max = (1 << 30) - 1; // https://github.com/HaxeFoundation/haxe/issues/9974
    for (i in 0...ints.length)
      ints.push(Std.random(max));

    for (i in ints) {
      var bin = enc.encode(i);

      var res = dec.tryDecode(bin);
      asserts.assert(res.match(Success(_)));
      switch res {
        case Success(v):
          asserts.assert(v == i);
        default:
      }
    }

    return asserts.done();
  }

  public function floats() {
    var enc = new Encoder<Float>(),
        dec = new Decoder<Float>();

    for (i in 0...100) {
      var f = Math.tan(Math.random() * Math.PI);
      asserts.assert(dec.decode(enc.encode(f)) - f < .00001);
    }

    return asserts.done();
  }
}