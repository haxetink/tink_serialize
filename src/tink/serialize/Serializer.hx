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
			o.writeNullInt(id);
			if (id == null) {
				map.set(data, id = counter++);
				encoder(data);
			}
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
		
	public function serialize(data:D) 
		throw 'abstract';
	
	public function writeString(s:String)
		strings.write(s, o.writeString);
}