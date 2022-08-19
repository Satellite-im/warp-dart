import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libName = 'warp';

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

final WarpDartBindings bindings = WarpDartBindings(_dylib);

class WarpException implements Exception {
  late String error_type;
  late String error_message;

  WarpException(Pointer<G_FFIError> error) {
    error_type = error.ref.error_type.cast<Utf8>().toDartString();
    error_message = error.ref.error_message.cast<Utf8>().toDartString();
    bindings.ffierror_free(error);
  }

  String errorType() {
    return error_type;
  }

  String errorMessage() {
    return error_message;
  }
}

String mnemonic_standard_phrase() {
  Pointer<Int8> ptr = bindings.generate_mnemonic_phrase(PhraseType.Standard);
  if (ptr.address.toString() != "0") {
    throw Exception("Invalid Pointer");
  }
  String phrase = ptr.cast<Utf8>().toDartString();
  calloc.free(ptr);
  return phrase;
}

String mnemonic_secured_phrase() {
  Pointer<Int8> ptr = bindings.generate_mnemonic_phrase(PhraseType.Secure);
  if (ptr.address.toString() != "0") {
    throw Exception("Invalid Pointer");
  }
  String phrase = ptr.cast<Utf8>().toDartString();
  calloc.free(ptr);
  return phrase;
}

void mnemonic_into_tesseract(Tesseract tesseract, String phrase) {
  G_FFIResult_Null result = bindings.mnemonic_into_tesseract(tesseract.getPointer(), phrase.toNativeUtf8().cast<Int8>());
  if (result.error != nullptr) {
    throw WarpException(result.error);
  }
}

class DID {
  late Pointer<G_DID> pointer;
  DID(this.pointer);

  DID.fromString(String key) {
    G_FFIResult_DID result =
        bindings.did_from_string(key.toNativeUtf8().cast<Int8>());
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    DID(result.data);
  }

  String toString() {
    Pointer<Int8> ptr = bindings.did_to_string(pointer);
    if (ptr == nullptr) {
      throw Exception("Invalid Pointer");
    }
    String key = ptr.cast<Utf8>().toDartString();
    calloc.free(ptr);
    return key;
  }

  void drop() {
    bindings.did_free(pointer);
  }
}

class Tesseract {
  late Pointer<G_Tesseract> _pointer;

  Tesseract(this._pointer);

  Pointer<G_Tesseract> getPointer() {
    return _pointer;
  }

  Tesseract.newStore() {
    _pointer = bindings.tesseract_new();
  }

  Tesseract.fromFile(String path) {
    G_FFIResult_Tesseract result =
        bindings.tesseract_from_file(path.toNativeUtf8().cast<Int8>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    _pointer = result.data;
  }

  void toFile(String path) {
    G_FFIResult_Null result =
        bindings.tesseract_to_file(_pointer, path.toNativeUtf8().cast<Int8>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void setFile(String path) {
    bindings.tesseract_set_file(_pointer, path.toNativeUtf8().cast<Int8>());
  }

  void setAutosave() {
    bindings.tesseract_set_autosave(_pointer);
  }

  bool isKeyCheckEnabled() {
    return bindings.tesseract_is_key_check_enabled(_pointer) != 0;
  }

  bool isAutosaveEnabled() {
    return bindings.tesseract_autosave_enabled(_pointer) != 0;
  }

  void enableKeyCheck() {
    bindings.tesseract_enable_key_check(_pointer);
  }

  void unlock(String passphrase) {
    G_FFIResult_Null result = bindings.tesseract_unlock(
        _pointer, passphrase.toNativeUtf8().cast<Int8>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  bool is_unlock() {
    return bindings.tesseract_is_unlock(_pointer) != 0;
  }

  void lock() {
    bindings.tesseract_lock(_pointer);
  }

  bool exist(String key) {
    return bindings.tesseract_exist(_pointer, key.toNativeUtf8().cast<Int8>()) !=
        0;
  }

  void save() {
    G_FFIResult_Null result = bindings.tesseract_save(_pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void set(String key, String val) {
    G_FFIResult_Null result = bindings.tesseract_set(_pointer,
        key.toNativeUtf8().cast<Int8>(), val.toNativeUtf8().cast<Int8>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  String retrieve(String key) {
    G_FFIResult_String result =
        bindings.tesseract_retrieve(_pointer, key.toNativeUtf8().cast<Int8>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    String data = result.data.cast<Utf8>().toDartString();
    calloc.free(result.data);
    return data;
  }

  void delete(String key) {
    G_FFIResult_Null result =
        bindings.tesseract_delete(_pointer, key.toNativeUtf8().cast<Int8>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void clear() {
    bindings.tesseract_clear(_pointer);
  }

  void drop() {
    bindings.tesseract_free(_pointer);
  }
}
