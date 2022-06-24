import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

import 'warp_dart_bindings_generated.dart';

const String _libName = 'warp';

/// The dynamic library in which the symbols for [WarpDartBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final WarpDartBindings _bindings = WarpDartBindings(_dylib);

class WarpDart {
  String ffiTest(String name) =>
      _bindings.ffi_test(name.toNativeUtf8().cast<Int8>()).cast<Utf8>().toDartString();
}

class DTesseract {
  Pointer<Tesseract> _tesseract = _bindings.tesseract_new();

  DTesseract() {}

  bool unlock(String passphrase) {
    return _bindings.tesseract_unlock(_tesseract, passphrase.toNativeUtf8().cast<Int8>());
  }
}