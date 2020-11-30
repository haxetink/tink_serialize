package ;

import tink.unit.*;
import tink.testrunner.*;

class RunTests {

  static function main() {
    Runner.run(TestBatch.make(
      new Primitives()
    )).handle(Runner.exit);
    // var e = new Encoder<Random>();
    // var bin = e.encode({
    //   foo: 'foo value',
    //   bar: [Hsv({ hue: 120, saturation: 100, value: 50 }), Hsl({ hue: 120, saturation: 100, lightness: 50 })],
    //   glargh: Some(White),
    //   blargh: [5419896 => { yo: false }]
    // });

    // var d = new Decoder<Random>();
    // trace(d.tryDecode(bin));
    // travix.Logger.println('it works');
    // travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }

}

typedef Random = {
  foo: String,
  bar:Array<Color>,
  glargh:haxe.ds.Option<Color>,
  blargh:Map<Int, { yo: Bool }>
};

enum Color {
  Rgb(a:Int, b:Int, c:Int);
  Hsv(hsv:{ hue:Float, saturation:Float, value:Float });//notice the single argument with name equal to the constructor
  Hsl(value:{ hue:Float, saturation:Float, lightness:Float });
  White;//no constructor
}
