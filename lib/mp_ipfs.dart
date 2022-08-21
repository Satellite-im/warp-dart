//Note: When it comes to extensions, they should be generated separately if at all possible
//      This would allow for them to be plugged into the interface (eg Multipass, etc) easily
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
// import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libNameIpfs = 'warp_mp_ipfs';
DynamicLibrary ipfs_dlib = Platform.isLinux
    ? DynamicLibrary.open('../linux/lib$_libNameIpfs.so')
    : DynamicLibrary.open('lib$_libNameIpfs.so');
final WarpDartBindings _ipfs_bindings = WarpDartBindings(ipfs_dlib);

MultiPass multipass_ipfs_temporary(Tesseract tesseract) {
  Pointer<G_MpIpfsConfig> config = _ipfs_bindings.mp_ipfs_config_testing();

  G_FFIResult_MultiPassAdapter result = _ipfs_bindings
      .multipass_mp_ipfs_temporary(nullptr, tesseract.getPointer(), config);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}

//Note: Before this function is called, we should make sure tesseract
// - Is unlocked
// - Has a file set
// - Has autosave enabled
MultiPass multipass_ipfs_persistent(Tesseract tesseract, String path) {
  G_FFIResult_MpIpfsConfig config = _ipfs_bindings
      .mp_ipfs_config_production(path.toNativeUtf8().cast<Int8>());

  if (config.error != nullptr) {
    throw WarpException(config.error.cast());
  }

  G_FFIResult_MultiPassAdapter result =
      _ipfs_bindings.multipass_mp_ipfs_persistent(
          nullptr, tesseract.getPointer(), config.data);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}
