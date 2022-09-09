import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
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
final DynamicLibrary ipfs_dlib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    String currentPath = Directory.current.path;
    return DynamicLibrary.open('$currentPath/macos/lib$_libNameIpfs.dylib');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libNameIpfs.so');
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open('$currentPath/linux/lib$_libNameIpfs.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$currentPath/windows/lib$_libNameIpfs.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();
final WarpDartBindings _fs_bindings = WarpDartBindings(ipfs_dlib);

Constellation initConstellation() {
  Pointer<G_ConstellationAdapter> _pointer = _fs_bindings
      .constellation_fs_memory_create_context()
      .cast<G_ConstellationAdapter>();

  return Constellation(_pointer);
}
