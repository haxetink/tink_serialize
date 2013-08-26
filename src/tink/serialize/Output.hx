package tink.serialize;

abstract Output<T:haxe.io.Output>(T) from T to T {
	
	public inline function writeByte(b:Int) this.writeByte(b);
	
	static var prefixes = [0, 0x8000, 0xC00000, 0xE0000000, 0];
	
	public function writeInt(i:Int) {
		var size = 4;
		while (size > 0) {
			if ((i >> (7 * size)) & 0x7F != 0) break;
			else size --;
		}
		
		i |= prefixes[size];
		
		if (size == 4) {
			writeByte(0xF0);
			size -= 1;
		}
		
		while (size >= 0) 
			writeByte((i >> (8 * size--)) & 0xFF);
	}
	
	public inline function writeFloat(x) this.writeDouble(x);
	public inline function writeSingle(x) this.writeFloat(x);
		
	public inline function writeNullInt(data:Null<Int>)
		if (data == null) writeByte(0xFF);
		else writeInt(data);
		
	public inline function writeBool(data:Bool) 
		writeByte(data ? 1 : 0);
		
	public inline function writeNullBool(data:Null<Bool>) 
		writeByte(
			if (data == true) 1 
			else if (data == false) 0 
			else 0xFF
		);
		
	public inline function writeNullFloat(data:Null<Float>) {
		writeBool(data == null);
		if (data != null)
			writeFloat(data);
	}	
	public inline function writeString(s:String) {
		s = StringTools.urlEncode(s);
		writeInt(s.length);
		this.writeString(s);
	}
	static public function bytes():Output<haxe.io.BytesOutput> {
		return new haxe.io.BytesOutput();
	}
}