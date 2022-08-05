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
import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libNameIpfs = 'warp_mp_ipfs';
DynamicLibrary ipfs_dlib = DynamicLibrary.open('lib$_libNameIpfs.so');
final WarpDartBindings _ipfs_bindings = WarpDartBindings(ipfs_dlib);

MultiPass multipass_ipfs_temporary(Tesseract tesseract) {
  const String config =
  //"{\"path\":\"/data/data/com.example.warp_dart_example/files\",\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/0\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";
      "{\"path\":null,\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/0\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";

  G_FFIResult_MultiPassAdapter result = _ipfs_bindings
      .multipass_mp_ipfs_temporary(
      nullptr, tesseract.getPointer(), config.toNativeUtf8().cast<Int8>());

  if (result.error.address.toString() != "0") {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}


//Note: Before this function is called, we should make sure tesseract
// - Is unlocked
// - Has a file set
// - Has autosave enabled
MultiPass multipass_ipfs_persistent(Tesseract tesseract, String path) {

  //This will change in the future where configuration object is exported via ffi
  String config =
      "{\"path\":\"$path\",\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/0\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";

  G_FFIResult_MultiPassAdapter result = _ipfs_bindings
      .multipass_mp_ipfs_persistent(
      nullptr, tesseract.getPointer(), config.toNativeUtf8().cast<Int8>());

  if (result.error.address.toString() != "0") {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}
