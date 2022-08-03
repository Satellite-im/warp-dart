import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'warp_dart_bindings_generated.dart';

const String _libName = 'warp';
const String _libNameIpfs = 'warp_mp_ipfs';

class DID {
  Pointer<G_DID> did;

  DID(this.did);
}

class Identity {
  Pointer<G_Identity> identity;

  Identity(this.identity);
}

class Identifier {
  Pointer<G_Identifier> identifier;

  Identifier(this.identifier);
}

class MultiPassAdapter {
  Pointer<G_MultiPassAdapter> multipass;

  MultiPassAdapter(this.multipass);
}

/// The dynamic library in which the symbols for [WarpDartBindings] can be found.
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

/// The bindings to the native functions in [_dylib].
DynamicLibrary ipfs_dlib = DynamicLibrary.open('lib$_libNameIpfs.so');
// Note: Extensions should have it bindings separate from warp bindings
final WarpDartBindings _ipfs_bindings = WarpDartBindings(ipfs_dlib);
final WarpDartBindings _bindings = WarpDartBindings(_dylib);

class WarpException implements Exception {
  late String error_type;
  late String error_message;

  WarpException(Pointer<G_FFIError> error) {
    error_type = error.ref.error_type.cast<Utf8>().toDartString();
    error_message = error.ref.error_message.cast<Utf8>().toDartString();
    _bindings.ffierror_free(error);
  }

  String errorType() {
    return error_type;
  }

  String errorMessage() {
    return error_message;
  }
}

String generateName() {
  return _bindings.multipass_generate_name().cast<Utf8>().toDartString();
}


Tesseract newTesseractInstance() {
  return Tesseract(_bindings.tesseract_new());
}


class Tesseract {
  late Pointer<G_Tesseract> pointer;

  Tesseract(this.pointer);

  Pointer<G_Tesseract> getPointer() {
    return pointer;
  }

  Tesseract fromFile(String path) {
      G_FFIResult_Tesseract bindings =
      _bindings.tesseract_from_file(path.toNativeUtf8().cast<Int8>());

      if (bindings.error.address.toString() != "0") {
        throw WarpException(bindings.error);
      }

      return Tesseract(bindings.data);
  }

  void unlock(String passphrase) {
    G_FFIResult_Null bindings = _bindings.tesseract_unlock(
        pointer, passphrase.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      throw WarpException(bindings.error);
    }
  }

  bool is_key_check_enabled() {
    return _bindings.tesseract_is_key_check_enabled(pointer) == 0;
  }

  void set(String key, String val) {
    G_FFIResult_Null bindings = _bindings.tesseract_set(pointer,
        key.toNativeUtf8().cast<Int8>(), val.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      throw WarpException(bindings.error);
    }
  }

  String retrieve(String key) {
    G_FFIResult_String bindings = _bindings.tesseract_retrieve(
        pointer, key.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      throw WarpException(bindings.error);
    }

    //store in variable and free the pointer
    return bindings.data.cast<Utf8>().toDartString();
  }

  void drop() {
    _bindings.tesseract_free(pointer);
  }


}

MultiPass multipass_ipfs_temporary(Tesseract tesseract) {

  tesseract.unlock(""); //this should be on the outside

  const String config =
  //"{\"path\":\"/data/data/com.example.warp_dart_example/files\",\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/0\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";
      "{\"path\":null,\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/4100\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";

  G_FFIResult_MultiPassAdapter result_multiPassAdapter = _ipfs_bindings
      .multipass_mp_ipfs_temporary(
      nullptr, tesseract.getPointer(), config.toNativeUtf8().cast<Int8>());

  if (result_multiPassAdapter.error.address.toString() != "0") {
    throw WarpException(result_multiPassAdapter.error.cast());
  }

  return MultiPass(result_multiPassAdapter.data);

}

class MultiPass {
  Pointer<G_MultiPassAdapter> adapter;

  MultiPass(this.adapter);

  DID createIdentity(String username, String passphrase) {
    DID did = DID(_bindings
        .multipass_create_identity(
            adapter,
            username.toNativeUtf8().cast<Int8>(),
            passphrase.toNativeUtf8().cast<Int8>())
        .data);

    print(_ipfs_bindings.did_to_string(did.did).cast<Utf8>().toDartString());

    return did;
  }

  Identity getIdentity(DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(adapter, identifier.identifier)
        .data);

    //Identity identity = Identity(_ipfs_bindings.multipass_get_own_identity(multipass.multipass).data);

    return identity;
  }

  String getUsername(DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(adapter, identifier.identifier)
        .data);

    String username = _ipfs_bindings
        .multipass_identity_username(identity.identity)
        .cast<Utf8>()
        .toDartString();

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return username;
  }

  int getShortId(DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(adapter, identifier.identifier)
        .data);

    int shortId = _ipfs_bindings.multipass_identity_short_id(identity.identity);

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return shortId;
  }

  String getStatus(DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(adapter, identifier.identifier)
        .data);

    if (_ipfs_bindings
            .multipass_identity_status_message(identity.identity)
            .address
            .toString() ==
        "0") {
      return "NaN";
    }

    String status = _ipfs_bindings
        .multipass_identity_status_message(identity.identity)
        .cast<Utf8>()
        .toDartString();

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return status;
  }

  //redir add udp:sourceport:destport
  String getProfileGraphic(DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(adapter, identifier.identifier)
        .data);

    String profile = _ipfs_bindings
        .multipass_graphics_profile_picture(
            _ipfs_bindings.multipass_identity_graphics(identity.identity))
        .cast<Utf8>()
        .toDartString();

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return profile;
  }

  String getBannerGraphic(DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(adapter, identifier.identifier)
        .data);

    String banner = _ipfs_bindings
        .multipass_graphics_profile_banner(
            _ipfs_bindings.multipass_identity_graphics(identity.identity))
        .cast<Utf8>()
        .toDartString();

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return banner;
  }

  void modifyName(String name) {
    _ipfs_bindings.multipass_update_identity(
        adapter,
        _ipfs_bindings.multipass_identity_update_set_username(
            name.toNativeUtf8().cast<Int8>()));
  }

  void modifyStatus(String status) {
    _ipfs_bindings.multipass_update_identity(
        adapter,
        _ipfs_bindings.multipass_identity_update_set_status_message(
            status.toNativeUtf8().cast<Int8>()));
  }

  void modifyProfileGraphics(String profile) {
    _ipfs_bindings.multipass_update_identity(
        adapter,
        _ipfs_bindings.multipass_identity_update_set_graphics_picture(
            profile.toNativeUtf8().cast<Int8>()));
  }

  void modifyBannerGraphics(String status) {
    _ipfs_bindings.multipass_update_identity(
        adapter,
        _ipfs_bindings.multipass_identity_update_set_graphics_banner(
            status.toNativeUtf8().cast<Int8>()));
  }

  void sendRequest(String pubkey) {
    DID did = DID(_ipfs_bindings
        .did_from_string(pubkey.toNativeUtf8().cast<Int8>())
        .data);
    _ipfs_bindings.multipass_send_request(adapter, did.did);
    sleep(Duration(seconds: 1));
  }

  List<String> listOutgoingRequestName() {
    List<String> list = [];
    int i = 0;

    G_FFIResult_FFIVec_FriendRequest result_requests = _ipfs_bindings.multipass_list_outgoing_request(adapter);

    if (result_requests.error.address.toString() != "0") {
      throw WarpException(result_requests.error);
    }

    Pointer<G_FFIVec_FriendRequest> request_list = result_requests.data;

    int length = request_list
        .ref
        .len;

    for (i; i < length; i++) {
      Pointer<G_FriendRequest> request = request_list.ref.ptr.elementAt(i).value;
      Pointer<G_DID> did = _bindings.multipass_friend_request_to(request);
      Pointer<G_Identifier> identifer = _bindings.multipass_identifier_did_key(did);

      G_FFIResult_Identity result_ident = _bindings.multipass_get_identity(adapter, identifer);

      if (result_ident.error.address.toString() != "0") {
        // WarpException error = WarpException(result_ident.error);
        // print(error.errorMessage());
        continue;
      }

      Pointer<Int8> strPtr = _bindings.multipass_identity_username(result_ident.data);

      list.add(strPtr.cast<Utf8>().toDartString());
      //TODO: Remember to free pointers
    }
    return list;
  }

  List<String> listOutgoingRequestDID() {
    List<String> list = [];
    int i = 0;
    int length = _ipfs_bindings
        .multipass_list_outgoing_request(adapter)
        .data
        .ref
        .len;

    for (i; i < length; i++) {
      list.add(_ipfs_bindings
          .did_to_string(_ipfs_bindings.multipass_friend_request_to(
              _ipfs_bindings
                  .multipass_list_outgoing_request(adapter)
                  .data
                  .ref
                  .ptr
                  .elementAt(i)
                  .value))
          .cast<Utf8>()
          .toDartString());
    }
    return list;
  }

  void acceptRequest(String pubkey) {
    print("hello");
    print(pubkey);
    DID did = DID(_ipfs_bindings
        .did_from_string(pubkey.toNativeUtf8().cast<Int8>())
        .data);
    print(_ipfs_bindings.did_to_string(did.did).cast<Utf8>().toDartString());
    _ipfs_bindings.multipass_accept_request(adapter, did.did);
    sleep(Duration(seconds: 1));
  }

  void denyRequest(String pubkey) {
    DID did = DID(_ipfs_bindings
        .did_from_string(pubkey.toNativeUtf8().cast<Int8>())
        .data);
    _ipfs_bindings.multipass_deny_request(adapter, did.did);
    sleep(Duration(seconds: 1));
  }

  List<String> listFriends() {
    List<String> list = [];
    int i = 0;
    int length =
        _ipfs_bindings.multipass_list_friends(adapter).data.ref.len;

    for (i; i < length; i++) {
      list.add(_ipfs_bindings
          .multipass_identity_username(_ipfs_bindings
              .multipass_get_identity(
          adapter,
                  _ipfs_bindings.multipass_identifier_did_key(_ipfs_bindings
                      .multipass_list_friends(adapter)
                      .data
                      .ref
                      .ptr
                      .elementAt(i)
                      .value))
              .data)
          .cast<Utf8>()
          .toDartString());
    }
    return list;
  }
}
