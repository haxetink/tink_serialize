package tink.serialize.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
using tink.macro.Tools;

class Build {
	static function getParam(superClass:String) {
		var cl = Context.getLocalClass().get();
		if (cl.superClass.t.toString() != superClass)
			cl.pos.error('Cannot extend subclasses of $superClass');
		return cl.superClass.params[0];	
	}
	static function getEnumInfo(e:EnumType, name:String) {
		var args =
			switch e.constructs.get(name).type {
				case TFun(args, _): args;
				default: [];
			}
			
		var pattern = name.resolve(),
			signature = [];
			
		if (args.length > 0) {
			
			pattern = pattern.call([for (p in args) p.name.resolve()]);
			
			var ct = (e.module+'.'+e.name).asComplexType();
			for (p in args) {
				var type = (macro {
					var e:$ct = null;
					switch e {
						case $pattern: $i{p.name};
						default: throw 'unreachable';
					}
				}).typeof().sure();
				if (p.opt) {
					var ct = type.toComplex();
					type = (macro : Null<$ct>).toType().sure();
				}
				signature.push({
					name:p.name,
					type:type
				});
			}
		}
		return {
			pattern: pattern,
			signature: signature
		}
	}
	static function normalizeFields(type:Ref<{fields:Array<ClassField>}>) {
		var fields = type.get().fields;
		//TODO: filter out methods and (get, never) fields
		fields.sort(function (f1, f2) return Reflect.compare(f1.name, f2.name));
		return fields;
	}
	static var isPrimitive = [
		'Int' => true,
		'Single' => true,
		'Float' => true,
		'Bool' => true
	].exists;
	
	static public function unserializer():Array<Field> {
		var ret = [],
			complexReaders = new haxe.ds.StringMap<Expr>();
			
		function getReader(t:Type):Expr
			return
				switch t {
					case TType(nil, [p]) if (nil.toString() == 'Null' && isPrimitive(p.getID())):
						('i.readNull'+p.getID()).resolve();
					default:
						var id = t.getID();
						switch id {
							case 'String': macro readString;
							case 'Int', 'Bool', 'Float', 'Single': 
								'i.read$id'.resolve();
							default: 
								t = t.reduce();
								var sig = Context.signature(t) + Std.string(t);
								if (!complexReaders.exists(sig)) {
									
									function addReader(body:Expr, ?args:Array<FunctionArg>) {
										var name = 'read_' + ret.length;
										var reader = tink.macro.Member.method(
											name, 
											body.func(
												args, 
												args == null ? t.toComplex() : null,
												args == null
											)
										);
										ret.push(reader);
										reader.isPublic = false;
										return name.resolve(body.pos);
									}
									
									function cached(init:Expr, decodeTo:Expr)
										return macro anons.read(function () return $init, ${addReader(decodeTo, ['ret'.toArg()])});
												
									var body = [];
									complexReaders.set(sig, addReader(body.toMBlock()));
									body.push(
										switch t {
											case TEnum(e, _):
												var clauses = [],
													e = e.get();
												function add(body)
													clauses.push({
														values: [clauses.length.toExpr()],
														guard: null,
														expr: body
													});
												
												add(macro null);
												
												for (name in e.names) {
													var info = getEnumInfo(e, name);
													var ret = name.resolve();
													if (info.signature.length > 0)
														ret = ret.call([
															for (p in info.signature)
																getReader(p.type).call()													
														]);
														
													add(ret);
												}
												clauses.push({
													values: [macro v],
													guard: null,
													expr: macro throw 'unexpected '+StringTools.hex(v)
												});
												ESwitch(macro i.readByte(), clauses, null).at();
											case TInst(cl, [p]) if (cl.toString() == 'Array' || cl.toString() == 'List'):
												var reader = getReader(p),
													cl = cl.toString();
												cached(macro new $cl(), macro {
													for (x in 0...i.readInt())
														ret.push($reader());
												});
											case TAnonymous(anon): 
												cached(
													macro cast {}, 
													[for (f in normalizeFields(anon)) 
														['ret', f.name].drill().assign(getReader(f.type).call())
													].toBlock()
												);
											case map if (Context.unify(map, (macro : Map<Dynamic, Dynamic>).toType().sure())):
												var ct = map.toComplex();
												
												function getType(name) 
													return (macro {
														var map:$ct = null;
														map.$name().next();
													}).typeof().sure();
													
												var k = getType('keys'),
													v = getType('iterator');
												var kct = k.toComplex(),
													vct = v.toComplex();
												cached(macro new Map<$kct, $vct>(), macro readMap(ret, ${getReader(k)}, ${getReader(v)}));	
											case v: 
												Context.currentPos().error('Type not supported: $t');
										}
									);
								}
								complexReaders.get(sig);								
						}						
				}
		var type = getParam('tink.serialize.Unserializer');
		var main = getReader(type);
		var m = tink.macro.Member.method('unserialize', (macro $main()).func(type.toComplex()));
		
		m.overrides = true;
		ret.push(m);			
		
		return ret;
	}
	
	static public function serializer():Array<Field> {
		var ret = [],
			complexWriters = new haxe.ds.StringMap<Expr>();			
				
		function getWriter(t:Type):Expr
			return
				switch t {
					case TType(nil, [p]) if (nil.toString() == 'Null' && isPrimitive(p.getID())):
						('o.writeNull'+p.getID()).resolve();
					default:
						var id = t.getID();
						switch id {
							case 'String': 
								macro writeString;
							case 'Int', 'Bool', 'Float', 'Single': 
								'o.write$id'.resolve();
							default: 
								t = t.reduce();
								var sig = Context.signature(t) + Std.string(t);
								if (!complexWriters.exists(sig)) {
									
									function addWriter(body:Expr) {
										var name = 'write_' + ret.length;
										ret.push(tink.macro.Member.method(name, body.func(['data'.toArg(t.toComplex())], false)));									
										return name.resolve(body.pos);
									}
									function cached(e:Expr) 
										return macro anons.write(data, $e{addWriter(e)});
										
									var body = [];
									
									complexWriters.set(sig, addWriter(body.toMBlock()));
									
									body.push(
										switch t {
											case TEnum(e, _):
												var clauses = [],
													e = e.get();
												var index = 1;
												for (name in e.names) {
													var encode = [macro o.writeInt($v{index++})];	
													var info = getEnumInfo(e, name);
													
													for (p in info.signature)
														encode.push(macro ${getWriter(p.type)}($i{p.name}));
													
													clauses.push({
														values: [info.pattern],
														guard: null,
														expr: encode.toBlock()
													});
												}
												var sw = ESwitch(macro data, clauses, null).at();
												macro 
													if (data == null) o.writeByte(0);
													else $sw;
											case TInst(cl, params) if (cl.toString() == 'Array' || cl.toString() == 'List'):
												var writer = getWriter(params[0]);
												cached(macro {
													o.writeInt(data.length);
													for (data in data)
														$writer(data);
												});
											case TAnonymous(anon): 	
												cached([for (f in normalizeFields(anon))
													getWriter(f.type).call([['data', f.name].drill()]),
												].toBlock());
												
											case map if (Context.unify(map, (macro : Map<Dynamic, Dynamic>).toType().sure())):
												var ct = map.toComplex();
												
												function writer(name) 
													return getWriter((macro {
														var map:$ct = null;
														map.$name().next();
													}).typeof().sure());
													
												var k = writer('keys'),
													v = writer('iterator');
												cached(macro writeMap(data, $k, $v));
											case v: 
												Context.currentPos().error('Type not supported: $t');
										}
									);
								}
								complexWriters.get(sig);								
						}						
				}
		
		var main = getWriter(getParam('tink.serialize.Serializer'));
		var m = tink.macro.Member.method('serialize', (macro $main(data)).func(['data'.toArg()]));
		m.overrides = true;
		ret.push(m);
		return ret;
	}
}