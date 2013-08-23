Tink Serialization
==================

The `tink_serialize` package uses macros to implement reflection-less serialization and unserialization by generating code specifically the given type.

The project is at a very early stage, but preliminary tests (on neko) show a speedup of factor 3 to 50 and a size improvement of factor 2 to 10.