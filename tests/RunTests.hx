package ;

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

  static function main() {
    Runner.run(TestBatch.make(
      new Primitives(),
      new RunTests()
    )).handle(Runner.exit);
  }

}

