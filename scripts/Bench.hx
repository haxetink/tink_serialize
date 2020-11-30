package ;

import Sys.*;

class Bench {
  static function main() {
    function build(args)
      command('haxe -lib tink_json -lib tink_serialize -cp tests -main Benchmark $args');


    println('\n--- nodejs ---\n');
    build('-js bin/bench.js -lib hxnodejs');
    command('node bin/bench.js');

    println('\n--- js ---\n');
    build('-js bin/bench.js');
    command('node bin/bench.js');

    build('-java bin/java -D jvm');
    println('\n--- java ---\n');
    command('java -jar bin/java/Benchmark.jar');

    if (systemName() == 'Windows') {
      build('-cs bin/cs');
      println('\n--- cs ---\n');
      command('bin\\cs\\bin\\Benchmark.exe');
    }

  }
}