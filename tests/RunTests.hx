package ;

import tink.core.Pair;
import tink.serialize.*;
import tink.unit.*;
import tink.testrunner.*;
import deepequal.DeepEqual.compare;
import Data;

@:asserts
class RunTests {

  public function new() {}

  public function random() {
    final data:Random = {
      foo: 'foo value',
      bar: [Hsv({ hue: 120, saturation: 100, value: 50 }), Hsl({ hue: 120, saturation: 100, lightness: 50 })],
      glargh: Some(White),
      blargh: [5419896 => { yo: false }],
      beep: [{ boop: null }, { boop: 432 }],
      date: Date.now(),
      bytes: haxe.io.Bytes.ofString('bytes'),
      custom: new Foo('foobar'),
    }

    final bin = tink.Serialize.encode(data);
    final decoded:Random = tink.Serialize.decode(bin);

    asserts.assert(compare(data, decoded).match(Success(_)));

    return asserts.done();
  }
  
  public function pair() {
    final data:Pair<Int, String> = new Pair(1, 'foo');
    final bin = tink.Serialize.encode(data);
    final decoded:Pair<Int, String> = tink.Serialize.decode(bin);

    asserts.assert(decoded.a == data.a);
    asserts.assert(decoded.b == data.b);

    return asserts.done();
  }
  
  public function arrayInput() {
    final data = [for(i in 0...3) i];
    final bin = tink.Serialize.encode(data);
    final decoded:Array<Int> = tink.Serialize.decode(bin);

    asserts.assert(decoded.length == data.length);
    for(i in 0...decoded.length)
      asserts.assert(decoded[i] == data[i]);

    return asserts.done();
  }

  public function stringCache() {
    final data = [for (i in 0...20) ['foo', 'bar', '', 'a much longer string', 'föö 🙂']];
    final big = tink.Serialize.encode(data, { stringCacheThreshold: 0 }),
          small = tink.Serialize.encode(data),
          partial = tink.Serialize.encode(data, { stringCacheThreshold: 10 });

    asserts.assert(small.length < partial.length);
    asserts.assert(partial.length < big.length);

    for (bin in [big, small, partial]) {
      final decoded:Array<Array<String>> = tink.Serialize.decode(bin);
      asserts.assert(compare(data, decoded).match(Success(_)));
    }

    return asserts.done();
  }

  static function main() {
    Runner.run(TestBatch.make(
      new Primitives(),
      new RunTests()
    )).handle(Runner.exit);
  }

}

