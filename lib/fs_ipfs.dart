
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/costellation.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libName = 'warp_fs_ipfs';
final DynamicLibrary _fs_ipfs_dlib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('../macos/lib$_libName.dylib');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open('../linux/lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final WarpDartBindings _ipfs_bindings = WarpDartBindings(_fs_ipfs_dlib);

enum Bootstrap { ipfs, experimental }

class FsIpfsConfig {
  late Pointer<G_FsIpfsConfig> _pointer;

  FsIpfsConfig(this._pointer);
  FsIpfsConfig.fromFile(String file) {
    G_FFIResult_FsIpfsConfig result = _ipfs_bindings
        .fs_ipfs_config_from_file(file.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  FsIpfsConfig.fromString(String jsonData) {
    G_FFIResult_FsIpfsConfig result = _ipfs_bindings
        .fs_ipfs_config_from_str(jsonData.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  FsIpfsConfig.development() {
    _pointer = _ipfs_bindings.fs_ipfs_config_development();
  }

  FsIpfsConfig.testing([Bootstrap? bootstrap = Bootstrap.ipfs]) {
    int experimental = bootstrap == Bootstrap.experimental ? 1 : 0;
    _pointer = _ipfs_bindings.fs_ipfs_config_testing();
  }

  FsIpfsConfig.production(String path, [Bootstrap bootstrap = Bootstrap.ipfs]) {
    int experimental = bootstrap == Bootstrap.experimental ? 1 : 0;
    G_FFIResult_FsIpfsConfig result = _ipfs_bindings
        .fs_ipfs_config_production(path.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  FsIpfsConfig.minimial(String path) {
    G_FFIResult_FsIpfsConfig result = _ipfs_bindings
        .fs_ipfs_config_minimial(path.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error.cast());
    }

    _pointer = result.data;
  }

  Pointer<G_FsIpfsConfig> toPointer() {
    return _pointer;
  }

  @override
  String toString() {
    return "TODO";
  }
}

Constellation fs_ipfs_temporary(MultiPass multipass) {
  FsIpfsConfig config = FsIpfsConfig.testing();

  G_FFIResult_ConstellationAdapter result =
      _ipfs_bindings.constellation_fs_ipfs_temporary_new(
          multipass.pointer, config.toPointer());

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return Constellation(result.data);
}

Constellation fs_ipfs_persistent(MultiPass multipass, String path,
    [FsIpfsConfig? config]) {
  FsIpfsConfig? internalConfig = config;

  if (internalConfig == null) {
    try {
      internalConfig = FsIpfsConfig.production(path);
    } on WarpException {
      rethrow;
    }
  }

  G_FFIResult_ConstellationAdapter result =
      _ipfs_bindings.constellation_fs_ipfs_persistent_new(
          multipass.pointer, internalConfig.toPointer());

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return Constellation(result.data);
}
