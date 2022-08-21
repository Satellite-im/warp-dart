import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
// import 'package:flutter/foundation.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/raygun.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libNameRaygunIpfs = 'warp_rg_ipfs';
DynamicLibrary raygun_ipfs_dlib = Platform.isLinux
    ? DynamicLibrary.open('../linux/lib$_libNameRaygunIpfs.so')
    : DynamicLibrary.open('lib$_libNameRaygunIpfs.so');
final WarpDartBindings _raygun_ipfs_bindings =
    WarpDartBindings(raygun_ipfs_dlib);

Raygun raygun_ipfs_temporary(MultiPass account) {
  Pointer<G_RgIpfsConfig> config =
      _raygun_ipfs_bindings.rg_ipfs_config_testing();

  G_FFIResult_RayGunAdapter result = _raygun_ipfs_bindings
      .warp_rg_ipfs_temporary_new(account.pointer, nullptr, config);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return Raygun(result.data);
}

Raygun raygun_ipfs_persistent(MultiPass account, String path) {
  G_FFIResult_RgIpfsConfig config = _raygun_ipfs_bindings
      .rg_ipfs_config_production(path.toNativeUtf8().cast<Int8>());

  if (config.error != nullptr) {
    throw WarpException(config.error.cast());
  }

  G_FFIResult_RayGunAdapter result = _raygun_ipfs_bindings
      .warp_rg_ipfs_persistent_new(account.pointer, nullptr, config.data);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return Raygun(result.data);
}
