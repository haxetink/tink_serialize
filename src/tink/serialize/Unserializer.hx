package tink.serialize;

import tink.serialize.Input;
import haxe.ds.*;

private class Cache<D, T:haxe.io.Input> {
	var counter:Int = 1;
	var i:Input<T>;
	var map:IntMap<D>;
	public function new(i) {
		this.i = i;
		this.map = new IntMap();
	}
	public function read(decoder):Null<D> 
		return
			switch i.readLength() {
				case 0: null;
				case v:
					var ret = map.get(v);
					if (ret == null)
						map.set(v, ret = decoder());
					ret;
			}
}

@:autoBuild(tink.serialize.macros.Build.unserializer())
class Unserializer<D, T:haxe.io.Input> {
	var i:Input<T>;
	
	var strings:Cache<String, T>;
	var idents:Cache<String, T>;
	var anons:Cache<Dynamic, T>;
	
	public function new(i) {
		this.i = i;
		this.idents = new Cache<String, T>(i);
		this.strings = new Cache<String, T>(i);
		this.anons = new Cache<Dynamic, T>(i);
	}
	
	inline function readInt():Int
		return i.readLength();
		
	inline function readNullInt():Null<Int>
		return switch i.readByte() {
			case 0xFF: null;
			case v: i.readLength(v);
		}
		
	inline function readBool():Bool 
		return i.readByte() == 1;
		
	inline function readNullBool():Null<Bool>
		return 
			switch i.readByte() {
				case 0xFF: null;
				case v: v == 1;
			}
		
	inline function readFloat():Float
		return i.readDouble();
		
	inline function readNullFloat() 
		return
			if (readBool()) null;
			else readFloat();
		
	public function unserialize():D return throw 'abstract';
	
	public function readString():String
		return strings.read(i.readString);
}