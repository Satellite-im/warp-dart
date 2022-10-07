import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

class PocketDimension {
  Pointer<G_PocketDimensionAdapter> _pointer;
  PocketDimension(this._pointer);

  void drop() {
    bindings.pocketdimensionadapter_free(_pointer);
  }
}
