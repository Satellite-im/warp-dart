//Note: When it comes to extensions, they should be generated separately if at all possible
//      This would allow for them to be plugged into the interface (eg Multipass, etc) easily
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libNameIpfs = 'warp_mp_ipfs';
DynamicLibrary ipfs_dlib = DynamicLibrary.open('lib$_libNameIpfs.so');
final WarpDartBindings _ipfs_bindings = WarpDartBindings(ipfs_dlib);

enum Bootstrap { ipfs, experimental }

// class Mdns {

// }

// class RelayClient {

// }

// class RelayServer {

// }

// class IpfsSetting {

// }

// class MpIpfsConfig {

// }

class MpIpfsConfig {
  //String? path;
  //Bootstrap bootstrap = Bootstrap.ipfs;
  //List<String> listenOn = ["/ip4/0.0.0.0/tcp/0", "/ip6/::/tcp/0"];
  late Pointer<G_MpIpfsConfig> _pointer;

  MpIpfsConfig(this._pointer);
  MpIpfsConfig.fromFile(String file) {
    G_FFIResult_MpIpfsConfig result = _ipfs_bindings
        .mp_ipfs_config_from_file(file.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  MpIpfsConfig.fromString(String jsonData) {
    G_FFIResult_MpIpfsConfig result = _ipfs_bindings
        .mp_ipfs_config_from_str(jsonData.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  MpIpfsConfig.development() {
    _pointer = _ipfs_bindings.mp_ipfs_config_development();
  }

  MpIpfsConfig.testing([Bootstrap? bootstrap = Bootstrap.ipfs]) {
    int experimental = bootstrap == Bootstrap.experimental ? 1 : 0;
    _pointer = _ipfs_bindings.mp_ipfs_config_testing(experimental);
  }

  MpIpfsConfig.production(String path, [Bootstrap bootstrap = Bootstrap.ipfs]) {
    int experimental = bootstrap == Bootstrap.experimental ? 1 : 0;
    G_FFIResult_MpIpfsConfig result = _ipfs_bindings.mp_ipfs_config_production(
        path.toNativeUtf8().cast<Char>(), experimental);

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  MpIpfsConfig.minimial(String path) {
    G_FFIResult_MpIpfsConfig result = _ipfs_bindings
        .mp_ipfs_config_minimial(path.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  Pointer<G_MpIpfsConfig> toPointer() {
    return _pointer;
  }

  @override
  String toString() {
    return "TODO";
  }
}

MultiPass multipass_ipfs_temporary(Tesseract tesseract) {
  MpIpfsConfig config = MpIpfsConfig.testing();

  G_FFIResult_MultiPassAdapter result =
      _ipfs_bindings.multipass_mp_ipfs_temporary(
          nullptr, tesseract.getPointer(), config.toPointer());

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}

MultiPass multipass_ipfs_persistent(Tesseract tesseract, String path,
    [MpIpfsConfig? config]) {
  MpIpfsConfig? internalConfig = config;

  if (internalConfig == null) {
    try {
      internalConfig = MpIpfsConfig.production(path);
    } on WarpException {
      rethrow;
    }
  }

  final _repoLockExist = File('$path/repo_lock').existsSync();
  if (_repoLockExist) {
    File('$path/repo_lock').deleteSync();
  }

  G_FFIResult_MultiPassAdapter result =
      _ipfs_bindings.multipass_mp_ipfs_persistent(
          nullptr, tesseract.getPointer(), internalConfig.toPointer());

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}
