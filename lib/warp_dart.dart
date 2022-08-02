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
final WarpDartBindings _ipfs_bindings = WarpDartBindings(ipfs_dlib);
final WarpDartBindings _bindings = WarpDartBindings(_dylib);

class Tesseract {
  Pointer<G_Tesseract> _tesseract = _bindings.tesseract_new();

  Tesseract() {}

  bool unlock(String passphrase) {
    G_FFIResult_Null bindings = _bindings.tesseract_unlock(
        _tesseract, passphrase.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      return false;
    }

    return true;
  }

  String from_file(String file) {
    G_FFIResult_Tesseract bindings =
        _bindings.tesseract_from_file(file.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      return bindings.error.ref.error_message.cast<Utf8>().toDartString();
    }

    return _bindings
        .tesseract_from_file(file.toNativeUtf8().cast<Int8>())
        .toString();
  }

  bool is_key_check_enabled() {
    return _bindings.tesseract_is_key_check_enabled(_tesseract);
  }

  bool set(String key, String val) {
    unlock("hi");
    G_FFIResult_Null bindings = _bindings.tesseract_set(_tesseract,
        key.toNativeUtf8().cast<Int8>(), val.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      return false;
    }
    return true;
  }

  String retrieve(String key) {
    G_FFIResult_String bindings = _bindings.tesseract_retrieve(
        _tesseract, key.toNativeUtf8().cast<Int8>());

    if (bindings.error.address.toString() != "0") {
      return bindings.error.ref.error_message.cast<Utf8>().toDartString();
    }

    return bindings.data.cast<Utf8>().toDartString();
  }

  String name() {
    return _bindings.multipass_generate_name().cast<Utf8>().toDartString();
  }
}

class MultiPass {
  MultiPass(String passphrase) {}

  MultiPassAdapter init() {
    String passphrase = "";
    //String tesseract_path = "/data/data/com.example.warp_dart_example/files";
    Pointer<G_Tesseract> tesseract = _bindings.tesseract_new();
    //_bindings.tesseract_set_file(
    //    tesseract, tesseract_path.toNativeUtf8().cast<Int8>());
    // _bindings.tesseract_set_autosave(tesseract);

    const String config =
        //"{\"path\":\"/data/data/com.example.warp_dart_example/files\",\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/0\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";
        "{\"path\":\"/storage/emulated/0/Android/data/com.example.warp_dart_example/files/ipfs\",\"bootstrap\":[\"/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN\"], \"listen_on\":[\"/ip4/0.0.0.0/tcp/0\"],\"ipfs_setting\":{\"mdns\":{\"enable\":true},\"autonat\":{\"enable\":false,\"servers\":[]},\"relay_client\":{\"enable\":false,\"relay_address\":null},\"relay_server\":{\"enable\":false},\"dcutr\":{\"enable\":false},\"rendezvous\":{\"enable\":false,\"address\":\"\"}},\"store_setting\":{\"broadcast_interval\":10,\"broadcast_with_connection\":true, \"discovery\":false}}";
    _bindings.tesseract_unlock(
        tesseract, passphrase.toNativeUtf8().cast<Int8>());
    MultiPassAdapter multipass = MultiPassAdapter(_ipfs_bindings
        .multipass_mp_ipfs_temporary(
            nullptr, tesseract, config.toNativeUtf8().cast<Int8>())
        .data);
    _bindings.tesseract_free(tesseract);

    return multipass;
  }

  DID createIdentity(
      MultiPassAdapter multipass, String username, String passphrase) {
    DID did = DID(_bindings
        .multipass_create_identity(
            multipass.multipass,
            username.toNativeUtf8().cast<Int8>(),
            passphrase.toNativeUtf8().cast<Int8>())
        .data);

    print(_ipfs_bindings.did_to_string(did.did).cast<Utf8>().toDartString());

    return did;
  }

  Identity getIdentity(MultiPassAdapter multipass, DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(multipass.multipass, identifier.identifier)
        .data);

    //Identity identity = Identity(_ipfs_bindings.multipass_get_own_identity(multipass.multipass).data);

    return identity;
  }

  String getUsername(MultiPassAdapter multipass, DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(multipass.multipass, identifier.identifier)
        .data);

    String username = _ipfs_bindings
        .multipass_identity_username(identity.identity)
        .cast<Utf8>()
        .toDartString();

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return username;
  }

  int getShortId(MultiPassAdapter multipass, DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(multipass.multipass, identifier.identifier)
        .data);

    int shortId = _ipfs_bindings.multipass_identity_short_id(identity.identity);

    _ipfs_bindings.identifier_free(identifier.identifier);
    _ipfs_bindings.identity_free(identity.identity);

    return shortId;
  }

  String getStatus(MultiPassAdapter multipass, DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(multipass.multipass, identifier.identifier)
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

  String getProfileGraphic(MultiPassAdapter multipass, DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(multipass.multipass, identifier.identifier)
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

  String getBannerGraphic(MultiPassAdapter multipass, DID did) {
    Identifier identifier =
        Identifier(_ipfs_bindings.multipass_identifier_did_key(did.did));
    Identity identity = Identity(_ipfs_bindings
        .multipass_get_identity(multipass.multipass, identifier.identifier)
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

  void modifyName(MultiPassAdapter multipass, String name) {
    _ipfs_bindings.multipass_update_identity(
        multipass.multipass,
        _ipfs_bindings.multipass_identity_update_set_username(
            name.toNativeUtf8().cast<Int8>()));
  }

  void modifyStatus(MultiPassAdapter multipass, String status) {
    _ipfs_bindings.multipass_update_identity(
        multipass.multipass,
        _ipfs_bindings.multipass_identity_update_set_status_message(
            status.toNativeUtf8().cast<Int8>()));
  }

  void modifyProfileGraphics(MultiPassAdapter multipass, String profile) {
    _ipfs_bindings.multipass_update_identity(
        multipass.multipass,
        _ipfs_bindings.multipass_identity_update_set_graphics_picture(
            profile.toNativeUtf8().cast<Int8>()));
  }

  void modifyBannerGraphics(MultiPassAdapter multipass, String status) {
    _ipfs_bindings.multipass_update_identity(
        multipass.multipass,
        _ipfs_bindings.multipass_identity_update_set_graphics_banner(
            status.toNativeUtf8().cast<Int8>()));
  }

  void sendRequest(MultiPassAdapter multipass, String pubkey) {
    DID did = DID(_ipfs_bindings
        .did_from_string(pubkey.toNativeUtf8().cast<Int8>())
        .data);
    _ipfs_bindings.multipass_send_request(multipass.multipass, did.did);
    sleep(Duration(seconds: 1));
  }

  List<String> listOutgoingRequestName(
    MultiPassAdapter multipass,
  ) {
    List<String> list = [];
    int i = 0;
    int length = _ipfs_bindings
        .multipass_list_outgoing_request(multipass.multipass)
        .data
        .ref
        .len;

    for (i; i < length; i++) {
      list.add(_ipfs_bindings
          .multipass_identity_username(_ipfs_bindings
              .multipass_get_identity(
                  multipass.multipass,
                  _ipfs_bindings.multipass_identifier_did_key(
                      _ipfs_bindings.multipass_friend_request_to(_ipfs_bindings
                          .multipass_list_outgoing_request(multipass.multipass)
                          .data
                          .ref
                          .ptr
                          .elementAt(i)
                          .value)))
              .data)
          .cast<Utf8>()
          .toDartString());
    }
    return list;
  }

  List<String> listOutgoingRequestDID(
    MultiPassAdapter multipass,
  ) {
    List<String> list = [];
    int i = 0;
    int length = _ipfs_bindings
        .multipass_list_outgoing_request(multipass.multipass)
        .data
        .ref
        .len;

    for (i; i < length; i++) {
      list.add(_ipfs_bindings
          .did_to_string(_ipfs_bindings.multipass_friend_request_to(
              _ipfs_bindings
                  .multipass_list_outgoing_request(multipass.multipass)
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

  void acceptRequest(MultiPassAdapter multipass, String pubkey) {
    print("hello");
    print(pubkey);
    DID did = DID(_ipfs_bindings
        .did_from_string(pubkey.toNativeUtf8().cast<Int8>())
        .data);
    print(_ipfs_bindings.did_to_string(did.did).cast<Utf8>().toDartString());
    _ipfs_bindings.multipass_accept_request(multipass.multipass, did.did);
    sleep(Duration(seconds: 1));
  }

  void denyRequest(MultiPassAdapter multipass, String pubkey) {
    DID did = DID(_ipfs_bindings
        .did_from_string(pubkey.toNativeUtf8().cast<Int8>())
        .data);
    _ipfs_bindings.multipass_deny_request(multipass.multipass, did.did);
    sleep(Duration(seconds: 1));
  }

  List<String> listFriends(MultiPassAdapter multipass) {
    List<String> list = [];
    int i = 0;
    int length =
        _ipfs_bindings.multipass_list_friends(multipass.multipass).data.ref.len;

    for (i; i < length; i++) {
      list.add(_ipfs_bindings
          .multipass_identity_username(_ipfs_bindings
              .multipass_get_identity(
                  multipass.multipass,
                  _ipfs_bindings.multipass_identifier_did_key(_ipfs_bindings
                      .multipass_list_friends(multipass.multipass)
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
