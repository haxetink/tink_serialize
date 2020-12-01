package;

typedef Random = {
	foo:String,
	bar:Array<Color>,
	glargh:haxe.ds.Option<Color>,
	blargh:Map<Int, {yo:Bool}>,
	beep:Array<{
		?boop:Int,
  }>,
  date:Date,
  bytes:haxe.io.Bytes,
  custom:Foo,
};

enum Color {
	Rgb(a:Int, b:Int, c:Int);
	Hsv(hsv:{hue:Int, saturation:Int, value:Int});
	Hsl(value:{hue:Int, saturation:Int, lightness:Int});
	White;
}

@:tink.encode(foo -> foo.value)
@:tink.decode(Data.Foo.new)
class Foo {
  public final value:String;
  public function new(value) {
    this.value = value;
  }
}