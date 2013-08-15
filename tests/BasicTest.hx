package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import tink.serialize.*;

class BasicTest extends TestCase {
	static var EDGE_CASES = [
		      0x00 => '00',
		      0x7F => '7F',
		      0x80 => '80 80',
		    0x3FFF => 'BF FF',
		    0x4000 => 'C0 40 00',
		  0x1FFFFF => 'DF FF FF',
		  0x200000 => 'E0 20 00 00',
		 0xFFFFFFF => 'EF FF FF FF',
		0x10000000 => 'F0 10 00 00 00',
		0xFFFFFFFF => 'F0 FF FF FF FF',
	];
	
	function testWriteLength() {
		var fake = new FakeOutput();
		var o:Output<FakeOutput> = fake;
		
		function fetch()
			return fake.clear();			
			
		for (v in EDGE_CASES.keys()) {
			o.writeLength(v);
			assertEquals(EDGE_CASES[v], fetch());
		}
	}
	
	function testReadLength() {
		
		var fake = new FakeInput();
		var i:Input<FakeInput> = fake;
		
		
		for (v in EDGE_CASES.keys()) {
			fake.fill(EDGE_CASES[v]);
			assertEquals(v, i.readLength());
			assertTrue(fake.isEmpty());
		}
	}
	
	function testLengthRoundtrip() {
		
		var fakeIn = new FakeInput(),
			fakeOut = new FakeOutput();
			
		var i:Input<FakeInput> = fakeIn,
			o:Output<FakeOutput> = fakeOut;
			
		for (x in 0...100) {
			var v = Std.random(1 << Std.random(30)) << 2;//way to deal with neko's Std.random weirdness and to distribute evenly over different size
			for (v in [v, v + 1, v + 2, v + 3]) {
				o.writeLength(v);
				fakeIn.fill(fakeOut.clear());
				assertEquals(v, i.readLength());
				assertTrue(fakeIn.isEmpty());
			}
		}
	}
	
	function testStringRoundtrip() {
		var cases = 'Ümläötß,+&%Üewif'.split(',');
		
		var fakeIn = new FakeInput(),
			fakeOut = new FakeOutput();
			
		var i:Input<FakeInput> = fakeIn,
			o:Output<FakeOutput> = fakeOut;
		
		for (c in cases) {
			o.writeString(c);
			fakeIn.fill(fakeOut.clear());
			assertEquals(c, i.readString());
			assertTrue(fakeIn.isEmpty());
		}
	}
}

class FakeInput extends haxe.io.Input {
	var data:Array<String>;
	public function new() this.data = [];
	override function readByte():Int {
		return 
			if (data.length > 0)
				Std.parseInt('0x'+this.data.shift());
			else throw 'EOF';
	}
	public function isEmpty():Bool return this.data.length == 0;
	public function fill(s:String) {
		this.data = s.split(' ');
	}
}

class FakeOutput extends haxe.io.Output {
	var data:Array<String>;
	public function new() this.data = [];
	override function writeByte(byte:Int) this.data.push(StringTools.hex(byte, 2));
	public function getContent() return this.data.join(' ');
	public function clear() {
		var ret = getContent();
		data = [];
		return ret;
	}
}