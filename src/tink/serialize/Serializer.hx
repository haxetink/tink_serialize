package tink.serialize;

import tink.serialize.Output;
import haxe.ds.*;

private class Cache<D, T:haxe.io.Output> {
	var counter:Int = 1;
	var o:Output<T>;
	var map:Map<D, Int>;
	public function new(o, map) {
		this.o = o;
		this.map = map;
	}
	public inline function write(data:D, encoder) 
		if (data == null) o.writeByte(0);
		else {
			var id = map.get(data);
			if (id == null) {
				map.set(data, id = counter++);
				o.writeLength(id);
				encoder(data);
			}
			else o.writeLength(id);			
		}
}

@:autoBuild(tink.serialize.macros.Build.serializer())
class Serializer<D, T:haxe.io.Output> {
	var o:Output<T>;
	
	var strings:Cache<String, T>;
	var idents:Cache<String, T>;
	var anons:Cache<Dynamic, T>;
	
	public function new(o) {
		this.o = o;
		this.idents = new Cache<String, T>(o, new StringMap());
		this.strings = new Cache<String, T>(o, new StringMap());
		this.anons = new Cache<Dynamic, T>(o, new ObjectMap());
	}
	
	inline function writeInt(data:Int) 
		o.writeLength(data);
		
	inline function writeNullInt(data:Null<Int>)
		if (data == null) o.writeByte(0xFF);
		else o.writeLength(data);
		
	inline function writeBool(data:Bool) 
		o.writeByte(data ? 1 : 0);
		
	inline function writeNullBool(data:Null<Bool>) 
		o.writeByte(
			if (data == true) 1 
			else if (data == false) 0 
			else 0xFF
		);
		
	inline function writeFloat(data:Float)
		o.writeDouble(data);
		
	inline function writeNullFloat(data:Null<Float>) {
		writeBool(data == null);
		if (data != null)
			writeFloat(data);
	}
		
	public function serialize(data:D) 
		throw 'abstract';
	
	public function writeString(s:String)
		strings.write(s, o.writeString);
}