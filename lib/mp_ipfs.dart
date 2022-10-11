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
//   String? path;
//   Bootstrap bootstrap = Bootstrap.ipfs;
//   List<String> listenOn = ["/ip4/0.0.0.0/tcp/0", "/ip6/::/tcp/0"];

// }

MultiPass multipass_ipfs_temporary(Tesseract tesseract,
    [Bootstrap bootstrap = Bootstrap.ipfs]) {
  int experimental = bootstrap == Bootstrap.experimental ? 1 : 0;

  Pointer<G_MpIpfsConfig> config =
      _ipfs_bindings.mp_ipfs_config_testing(experimental);

  G_FFIResult_MultiPassAdapter result = _ipfs_bindings
      .multipass_mp_ipfs_temporary(nullptr, tesseract.getPointer(), config);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return MultiPass(result.data);
}

MultiPass multipass_ipfs_persistent(Tesseract tesseract, String path,
    [Bootstrap bootstrap = Bootstrap.ipfs]) {
  int experimental = bootstrap == Bootstrap.experimental ? 1 : 0;

  G_FFIResult_MpIpfsConfig config = _ipfs_bindings.mp_ipfs_config_production(
      path.toNativeUtf8().cast<Char>(), experimental);

  final _repoLockExist = File('$path/repo_lock').existsSync();
  if (_repoLockExist) {
    File('$path/repo_lock').deleteSync();
  }

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
