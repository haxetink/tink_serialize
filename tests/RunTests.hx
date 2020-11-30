package ;

import tink.serialize.*;
import tink.unit.*;
import tink.testrunner.*;
import deepequal.DeepEqual.compare;

@:asserts
class RunTests {

  public function new() {}

  public function random() {
    var e = new Encoder<Random>();
    var data:Random = {
      foo: 'foo value',
      bar: [Hsv({ hue: 120, saturation: 100, value: 50 }), Hsl({ hue: 120, saturation: 100, lightness: 50 })],
      glargh: Some(White),
      blargh: [5419896 => { yo: false }],
      beep: [{ boop: null }, { boop: 432 }]
    }

    var bin = e.encode(data);

    var d = new Decoder<Random>();

    asserts.assert(compare(data, d.decode(bin)).match(Success(_)));

    return asserts.done();
  }

  static function main() {
    Runner.run(TestBatch.make(
      new Primitives(),
      new RunTests()
    )).handle(Runner.exit);
  }

}

typedef Random = {
  foo: String,
  bar:Array<Color>,
  glargh:haxe.ds.Option<Color>,
  blargh:Map<Int, { yo: Bool }>,
  beep: Array<{
    ?boop: Int,
  }>
};

enum Color {
  Rgb(a:Int, b:Int, c:Int);
  Hsv(hsv:{ hue:Int, saturation:Int, value:Int });
  Hsl(value:{ hue:Int, saturation:Int, lightness:Int });
  White;
}
