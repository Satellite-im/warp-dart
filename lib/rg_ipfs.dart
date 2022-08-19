import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:warp_dart/multipass.dart';
// import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/raygun.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libNameRaygunIpfs = 'warp_rg_ipfs';
DynamicLibrary raygun_ipfs_dlib = Platform.isLinux
    ? DynamicLibrary.open('../linux/lib$_libNameRaygunIpfs.so')
    : DynamicLibrary.open('lib$_libNameRaygunIpfs.so');
final WarpDartBindings _raygun_ipfs_bindings =
    WarpDartBindings(raygun_ipfs_dlib);

Raygun raygun_ipfs_temporary(MultiPass mp) {
  Pointer<G_RgIpfsConfig> config =
      _raygun_ipfs_bindings.rg_ipfs_config_testing();

  G_FFIResult_RayGunAdapter result = _raygun_ipfs_bindings
      .warp_rg_ipfs_temporary_new(mp.pointer, nullptr, config);

  if (result.error.address.toString() != "0") {
    throw WarpException(result.error.cast());
  }

  return Raygun(result.data);
}
