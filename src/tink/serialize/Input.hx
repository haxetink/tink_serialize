package tink.serialize;

abstract Input<T:haxe.io.Input>(T) from T to T {
	public function readByte():Int 
		return this.readByte();
		
	function doReadInt(?first:Null<Int> = null):Int {
		var b = 
			if (first == null) readByte();
			else first;
		return 
			if (b < 0x80) b;
			else if (b < 0xC0) ((b & 0x3F) << 8) + readByte();
			else if (b < 0xE0) ((b & 0x1F) << 16) + (readByte() << 8) + readByte();
			else if (b < 0xF0) ((b & 0x0F) << 24) + (readByte() << 16) + (readByte() << 8) + readByte();
			else (readByte() << 24) + (readByte() << 16) + (readByte() << 8) + readByte();
	}
	public inline function readInt():Int
		return doReadInt();
		
	public inline function readFloat():Float
		return this.readDouble();
		
	public inline function readSingle():Float
		return this.readFloat();
	
	public inline function readString():String 
		return StringTools.urlDecode(this.readString(readInt()));
		
		
	public inline function readNullInt():Null<Int>
		return switch readByte() {
			case 0xFF: null;
			case v: doReadInt(v);
		}
		
	public inline function readBool():Bool 
		return readByte() == 1;
		
	public inline function readNullBool():Null<Bool>
		return 
			switch readByte() {
				case 0xFF: null;
				case v: v == 1;
			}
		
	public inline function readNullFloat() 
		return
			if (readBool()) null;
			else readFloat();
	
}