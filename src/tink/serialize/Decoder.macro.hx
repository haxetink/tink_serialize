package tink.serialize;

import haxe.macro.Type;
import tink.typecrawler.Generator;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import haxe.macro.Expr;
import tink.macro.BuildCache;

using haxe.macro.Tools;
using tink.MacroApi;
using tink.CoreApi;

class Decoder<T> {
  final crawler:Crawler;

  function new(crawler)
    this.crawler = crawler;

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
    return macro readBool();

  public function date():Expr
    return macro writeFloat(data.getTime());

  public function bytes():Expr
    return macro writeBytes();

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

  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr
    return macro @:pos(pos) {
      var v:$ct = cast $e;
      ${ESwitch(
        macro v,
        [{expr: macro v, values: names}],
        macro {
          var list = $a{names};
          throw new tink.core.Error(422, 'Unrecognized ${ct.toString} value: ' + v);
        }
      ).at(pos)}
    }

  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr>
    return None;

  public function reject(t:Type):String
    return 'cannot serialize ${t.toString()}';

  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);

  public function drive(type:Type, pos:Position, gen:GenType):Expr
    return gen(type, pos);
  static function build()
    return BuildCache.getType('tink.serialize.Decoder', null, null, ctx -> {

      var res = Crawler.crawl(ctx.type, ctx.pos, Decoder.new);

      var name = ctx.name;

      var ret = macro class $name extends tink.serialize.Decoder.DecoderBase {
      }

      function addFields(from) {
        ret.fields = ret.fields.concat(from.fields);
        return from.fields;
      }

      addFields(res);
      addFields(macro class {
        public function decode(data:haxe.io.BytesData) {
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