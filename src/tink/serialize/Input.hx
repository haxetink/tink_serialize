package tink.serialize;

abstract Input<T:haxe.io.Input>(T) from T to T {
	public function readByte() return this.readByte();
	public function readLength():Int {
		var b = readByte();
		return 
			if (b < 0x80) b;
			else if (b < 0xC0) ((b & 0x3F) << 8) + readByte();
			else if (b < 0xE0) ((b & 0x1F) << 16) + (readByte() << 8) + readByte();
			else if (b < 0xF0) ((b & 0x0F) << 24) + (readByte() << 16) + (readByte() << 8) + readByte();
			else (readByte() << 24) + (readByte() << 16) + (readByte() << 8) + readByte();
	}
	public function readString():String {
		return StringTools.urlDecode(this.readString(readLength()));
	}
}