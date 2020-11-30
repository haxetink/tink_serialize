class Benchmark {
  static function main() {
    var msg:Message = {
      foo: '123',
      bar: 'hoho'
    };

    var s = null,
        writer = new tink.json.Writer<Message>(),
        parser = new tink.json.Parser<Message>();

    measure('stringify', () -> {
      for (i in 0...100000)
        s = writer.write(msg);
    });

    measure('parse', () -> {
      for (i in 0...100000)
        parser.parse(s);
    });

    var bin = null,
        enc = new tink.serialize.Encoder<Message>(),
        dec = new tink.serialize.Decoder<Message>();

    measure('encode', () -> {
      for (i in 0...100000)
        bin = enc.encode(msg);
    });

    measure('decode', () -> {
      for (i in 0...100000)
        dec.decode(bin);
    });
  }

  static function measure(name, f) {
    var start = haxe.Timer.stamp();
    f();
    var msg = '$name took ${haxe.Timer.stamp() - start}';
    #if sys
      Sys.println(msg);
    #elseif js
      js.Browser.console.log(msg);
    #else
      trace(msg, null);
    #end
  }
}

typedef Message = {
  var foo:String;
  var bar:String;
}