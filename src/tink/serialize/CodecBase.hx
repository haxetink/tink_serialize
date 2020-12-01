package tink.serialize;

import tink.typecrawler.Crawler;
import tink.typecrawler.Generator;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.MacroApi;

class CodecBase {
  final crawler:Crawler;
  final customMeta:String;

  function new(customMeta, crawler) {
    this.crawler = crawler;
    this.customMeta = customMeta;
  }
  
  function processCustom(custom:CustomRule, original:Type, gen:Type->Expr):Expr {
    throw 'abstract';
  }
  
  public function drive(type:Type, pos:Position, gen:GenType):Expr {
    
    return switch type.getMeta().filter(m -> m.has(customMeta)) {
      case []:
        gen(type, pos);
      case m:
        switch m[0].extract(customMeta)[0] {
          case { params: [custom] }:
            var rule:CustomRule =
              switch custom {
                case { expr: EFunction(_, _) }: WithFunction(custom);
                // case { expr: EParenthesis({ expr: ECheckType(_, TPath(path)) }) }: WithClass(path, custom.pos);
                case _ if(custom.typeof().sure().reduce().match(TFun(_, _))): WithFunction(custom);
                case _: throw 'Unsupported parameter for @$customMeta';
                // default: WithClass(custom.toString().asTypePath(), custom.pos);
              }
            processCustom(rule, type, drive.bind(_, pos, gen));
          case v: v.pos.error('@$customMeta must have exactly one parameter');
        }
    }
  }
}

