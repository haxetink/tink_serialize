import tink.serialize.*;

@:asserts
class Primitives {
  public function new() {

  }

  public function ints() {
    var enc = new Encoder<Int>(),
        dec = new Decoder<Int>();

    // trace(enc.encode(16512).toHex());
    var ints = [for (i in 0...32) 1 << i];
    ints.unshift(0);
    // var ints = [16384];

    for (i in ints) {
      // dec.decode(enc.encode(i));
      var res = dec.tryDecode(enc.encode(i));
      // trace(enc.encode(i).toHex());
      asserts.assert(res.match(Success(_)));
      switch res {
        case Success(v):
          asserts.assert(v == i);
        default:
      }
    }
      // asserts.assert(.match(Success(_ == i => true)));
    return asserts.done();
  }
}