import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
//import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';
import 'package:warp_dart/costellation.dart';

const String _libNameIpfs = 'warp_fs_memory';
String currentPath = io.Directory.current.path;
final DynamicLibrary ipfs_dlib = () {
  if (io.Platform.isMacOS || io.Platform.isIOS) {
    return DynamicLibrary.open('$currentPath/macos/lib$_libNameIpfs.dylib');
  }
  if (io.Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libNameIpfs.so');
  }
  if (io.Platform.isLinux) {
    return DynamicLibrary.open('$currentPath/linux/lib$_libNameIpfs.so');
  }
  if (io.Platform.isWindows) {
    return DynamicLibrary.open('$currentPath/windows/lib$_libNameIpfs.dll');
  }
  throw UnsupportedError('Unknown platform: ${io.Platform.operatingSystem}');
}();
final WarpDartBindings _fs_bindings = WarpDartBindings(ipfs_dlib);

Constellation initConstellation() {
  Pointer<G_ConstellationAdapter> _pointer = _fs_bindings
      .constellation_fs_memory_create_context()
      .cast<G_ConstellationAdapter>();

  return Constellation(_pointer);
}
