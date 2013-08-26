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
			switch i.readNullInt() {
				case 0: null;
				case v:
					if (v == null) {//TODO: move to separate case, once null patterns are allowed
						var ret = decoder();
						map.set(counter++, ret);
						ret;						
					}
					else map.get(v);
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
		
	public function unserialize():D 
		return throw 'abstract';
	
	function readString():String
		return strings.read(i.readString);
}