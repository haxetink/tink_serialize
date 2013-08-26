package ;

import haxe.unit.TestCase;

#if macro
	import haxe.macro.Expr;
	using tink.macro.Tools;
#else
	import tink.serialize.*;
	import haxe.ds.Option;
	import Type;
#end

enum Dummy {
	One;
	Two;
	Three(a:Int, ?b:Float);
	Four(a:Bool, ?b:Int);
	Five(a:Array<Dummy>);
}
class SerializerTest extends Base {
	macro static function roundtrip(v:Expr) {
		var t = v.typeof().sure().toComplex();
		
		function define(superClass:String, hxType:String) {
			var name = String.tempName(superClass.split('.').pop());
			haxe.macro.Context.defineType({
				pos: v.pos,
				params: [{name:'T', constraints:[hxType.asComplexType()]}],
				pack: [],
				name: name,
				meta: [],
				isExtern: false,
				fields: [],
				kind: TDClass(superClass.asTypePath([TPType(t), TPType('T'.asComplexType())]), [], false)
			});
			return name;
		}
		
		var writer = define('tink.serialize.Serializer', 'haxe.io.Output'),
			reader = define('tink.serialize.Unserializer', 'haxe.io.Input');
			
		var ret = macro {
			var data = $v,
				dst = new haxe.io.BytesOutput();
			var writer = new $writer(dst);
			
			writer.serialize(data);
			
			var rep = dst.getBytes();
			var src = new haxe.io.BytesInput(rep);
			
			var reader = new $reader(src);
			var result = reader.unserialize();
			assertStructEq(data, result);
			result;
		}
		return ret;
	}
	#if !macro
	function assertStructEq<A>(expected:A, found:A) {
		function compare(e:Dynamic, f:Dynamic):Bool
			return 
				switch Type.typeof(e) {
					case TNull, TInt, TBool, TFloat, TUnknown, TClass(String): e == f;
					case TObject:
						var ret = true;
						//TODO: consider checking surplus fields
						for (field in Reflect.fields(e)) 
							if (field != '__id__' && !compare(Reflect.field(e, field), Reflect.field(f, field))) {
								ret = false;
								break;
							}
						ret;
					case TEnum(enm):
						Std.is(found, enm) 
						&& 
						compare(Type.enumIndex(e), Type.enumIndex(f))
						&&
						compare(Type.enumParameters(e), Type.enumParameters(f));
					case TClass(Array):
						var ret = compare(e.length, f.length);
						if (ret)
							for (i in 0...e.length)
								if (!compare(e[i], f[i])) {
									ret = false;
									break;
								}
						ret;
					case TClass(_) if (Std.is(e, Map.IMap)):
						var e:Map.IMap<Dynamic, Dynamic> = e,
							f:Map.IMap<Dynamic, Dynamic> = f;
							
						var ret = true;
						function find(orig:Dynamic) {
							for (copy in f.keys())
								if (compare(orig, copy)) 
									return copy;
							return orig;
						}
						if (ret)
							for (k in e.keys())
								if (!compare(e.get(k), f.get(find(k)))) {
									ret = false;
									break;
								}
						e.toString();
						ret;
					default:
						throw 'assert';
				}
		if (compare(expected, found)) assertTrue(true);
		else fail('expected $expected, found $found');
	}
	
	function testAtoms() {
		roundtrip(5);
		roundtrip('foo');
		roundtrip({ var a:Array<Int> = []; a; });//Unkown will cause trouble
		roundtrip([5, 4, 3]);
		roundtrip({});
		roundtrip({ foo: 4 });
		roundtrip({ foo: 'foo', bar: 5 });
		roundtrip(One);
		roundtrip(Two);
		roundtrip(Three(4));
		roundtrip(Three(5, 4));
		roundtrip(Four(true));
		roundtrip(Four(true, 6));
		roundtrip(["foo" => 5, "quack" => 6]);
		roundtrip([1 => 5, 3 => 6]);
		roundtrip([{ x: 3 } => true, { x: 5} => false ]);
	}
	
	function testComplex() {
		roundtrip([for (i in 0...100) {
			reoijergt: i,
			str: 'foo$i'
		}]);
	}
	
	function testIdentities() {
		var datas = [{}, {}, {}, {}];
		var res = roundtrip([for (i in 0...100) datas[i % datas.length]]);
		for (i in 0...res.length-datas.length) {
			assertEquals(res[i], res[i+datas.length]);
			for (j in 1...datas.length)
				assertFalse(res[i] == res[i + j]);
		}
		
	}
	#end
}