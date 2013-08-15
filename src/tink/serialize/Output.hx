package tink.serialize;

abstract Output<T:haxe.io.Output>(T) from T to T {
	
	public function writeByte(b:Int) this.writeByte(b);
	
	static var prefixes = [0, 0x8000, 0xC00000, 0xE0000000, 0];
	public function writeLength(i:Int) {
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
	public function writeString(s:String) {
		s = StringTools.urlEncode(s);
		writeLength(s.length);
		this.writeString(s);
	}
	static public function bytes():Output<haxe.io.BytesOutput> {
		return new haxe.io.BytesOutput();
	}
}

typedef Cache = {
	
}