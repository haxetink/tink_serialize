package tink.serialize;

import haxe.macro.Type;
import tink.typecrawler.Generator;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

class Decoder<T> extends CodecBase {
  public function wrap(placeholder:Expr, ct:ComplexType):Function
    return placeholder.func(ct);

  public function nullable(e:Expr):Expr
    return macro if (esc()) null else $e;

  public function string():Expr
    return macro string();

  public function float():Expr
    return macro float();

  public function int():Expr
    return macro dynInt();

  public function dyn(e:Expr, ct:ComplexType):Expr
    return macro ($e : Dynamic<$ct>);

  public function dynAccess(e:Expr):Expr
    return macro {
      var __ret = new haxe.DynamicAccess();
      while (!esc())
        __ret[string()] = $e;
      __ret;
    }

  public function bool():Expr
    return macro bool();

  public function date():Expr
    return macro Date.fromTime(float());

  public function bytes():Expr
    return macro bytes();

  public function anon(fields:Array<FieldInfo>, ct:ComplexType):Expr
    return EObjectDecl([for (f in fields) {
      field: f.name,
      expr: f.expr
    }]).at();

  public function array(e:Expr):Expr
    return macro [for (i in 0...len()) $e];

  public function map(k:Expr, v:Expr):Expr
    return macro [while (!esc()) $k => $v];

  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr
    return ESwitch(macro dynInt(), [
      for (c in constructors) {
        var ident = macro $i{c.ctor.name};
        {
          values: [macro $v{c.ctor.index}],
          expr: switch c.ctor.type {
            case TFun(args, _):
              if (c.inlined) {
                var obj = EObjectDecl([
                  for (f in c.fields) {
                    field: f.name,
                    expr: f.expr
                  }
                ]).at();
                macro $ident($obj);
              }
              else {
                var exprs = [for (f in c.fields) f.name => f.expr];
                var args = [for (a in args) exprs[a.name]];
                macro $ident($a{args});
              }
            default:
              ident;
          },
        }
      }
    ], macro throw 'assert').at();

  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    // TODO: the following is exactly copied from tink_json
    // get the values of the enum abstract statically
    final values = names.map(e -> {
      final e = macro ($i{e.toString().split('.').pop()}:$ct); // this ECheckType + DirectType approach makes sure we can punch through the type system even if the abstract is private
      switch Context.typeExpr(e) {
        case {expr: TParenthesis({expr: TCast({expr: TCast(texpr, _)}, _)})}:
          Context.getTypedExpr(texpr);
        case _:
          throw 'TODO';
      }
    });
        
    return macro @:pos(pos) {
      final v = $e;
      ${ESwitch(
        macro v,
        [{expr: macro (cast v:$ct), values: values}],
        macro throw new tink.core.Error(422, 'Unrecognized enum value: ' + v + '. Accepted values are: ' + tink.Json.stringify(${macro $a{values}}))
      ).at(pos)}
    } 
  }
    
    
  override function processCustom(custom:CustomRule, original:Type, gen:Type->Expr):Expr {
    var original = original.toComplex();
    return switch custom {
      case WithFunction(e):
        var rep = (macro @:pos(e.pos) { var f = null; (($e)(f()) : $original); f(); }).typeof().sure();
        macro @:pos(e.pos) ($e)(${gen(rep)});
    }
  }

  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr>
    return None;

  public function reject(t:Type):String
    return 'cannot serialize ${t.toString()}';

  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);

  static function build()
    return BuildCache.getType('tink.serialize.Decoder', null, null, ctx -> {

      var res = Crawler.crawl(ctx.type, ctx.pos, Decoder.new.bind(':tink.decode'));

      var name = ctx.name;

      var ret = macro class $name extends tink.serialize.Decoder.DecoderBase {
      }

      function addFields(from) {
        ret.fields = ret.fields.concat(from.fields);
        return from.fields;
      }

      addFields(res);
      addFields(macro class {
        public function decode(data:haxe.io.Bytes) {
          reset(data);
          return ${res.expr};
        }

        public function tryDecode(data)
          return
            tink.core.Error.catchExceptions(() -> decode(data));
      });

      ret;
    });
}