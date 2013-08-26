package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class Run {
	static var tests:Array<TestCase> = [
		new BasicTest(),
		new SerializerTest()
	];
	static function main() {
		var runner = new TestRunner();
		for (test in tests)
			runner.add(test);
		runner.run();
	}
}

// class Read extends tink.serialize.Unserializer<{ foo:String }, haxe.io.Input> {}

// class Write extends tink.serialize.Serializer<Map<String, Int>, haxe.io.BytesOutput> {}
// class Read extends tink.serialize.Unserializer<Map<String, Int>, haxe.io.Input> {}