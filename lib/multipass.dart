import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
//import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

class Role {
  late String name;
  late int level;
  Role(Pointer<G_Role> pointer) {
    name = bindings.multipass_role_name(pointer).cast<Utf8>().toDartString();
    level = bindings.multipass_role_level(pointer);
    bindings.role_free(pointer);
  }
}

class Badge {
  late String name;
  late String icon;
  Badge(Pointer<G_Badge> pointer) {
    name = bindings.multipass_badge_name(pointer).cast<Utf8>().toDartString();
    icon = bindings.multipass_badge_icon(pointer).cast<Utf8>().toDartString();
    bindings.badge_free(pointer);
  }
}

class Identifier {
  late Pointer<G_Identifier> _pointer;
  Identifier(this._pointer);

  Identifier.fromUserName(String username) {
    _pointer = bindings
        .multipass_identifier_user_name(username.toNativeUtf8().cast<Char>());
  }

  Identifier.fromDID(DID did_key) {
    _pointer = bindings.multipass_identifier_did_key(did_key.pointer);
  }

  Identifier.fromDIDString(String did_key) {
    DID did;
    try {
      did = DID.fromString(did_key);
    } on WarpException catch (e) {
      rethrow;
    }
    Pointer<G_Identifier> ptr =
        bindings.multipass_identifier_did_key(did.pointer);
    did.drop();
    _pointer = ptr;
  }

  Identifier.own() {
    _pointer = bindings.multipass_identifier_own();
  }

  Pointer<G_Identifier> pointer() {
    return _pointer;
  }

  void drop() {
    bindings.identifier_free(_pointer);
  }
}

class IdentityUpdate {
  late Pointer<G_IdentityUpdate> pointer;
  IdentityUpdate(this.pointer);

  IdentityUpdate.setUsername(String username) {
    pointer = bindings.multipass_identity_update_set_username(
        username.toNativeUtf8().cast<Char>());
  }
  IdentityUpdate.setStatusMessage(String status) {
    pointer = bindings.multipass_identity_update_set_status_message(
        status.toNativeUtf8().cast<Char>());
  }
  IdentityUpdate.setPicture(String picture) {
    pointer = bindings.multipass_identity_update_set_graphics_picture(
        picture.toNativeUtf8().cast<Char>());
  }
  IdentityUpdate.setBanner(String banner) {
    pointer = bindings.multipass_identity_update_set_graphics_banner(
        banner.toNativeUtf8().cast<Char>());
  }
  void drop() {
    bindings.identityupdate_free(pointer);
  }
}

class Graphics {
  late String profile_picture;
  late String profile_banner;
  Graphics(Pointer<G_Graphics> pointer) {
    profile_picture = bindings
        .multipass_graphics_profile_picture(pointer)
        .cast<Utf8>()
        .toDartString();
    profile_banner = bindings
        .multipass_graphics_profile_banner(pointer)
        .cast<Utf8>()
        .toDartString();
    bindings.graphics_free(pointer);
  }
}

class Identity {
  late String username;
  late String short_id;
  late DID did_key;
  late Graphics graphics;
  late String? status_message;
  //late List<Role> roles;
  //late List<Badge> available_badges;
  //late Badge active_badge;
  //late Map<String, String> linked_accounts;
  Identity(Pointer<G_Identity> pointer) {
    Pointer<Char> pUsername = bindings.multipass_identity_username(pointer);
    username = pUsername.cast<Utf8>().toDartString();
    Pointer<Char> pShortId = bindings.multipass_identity_short_id(pointer);
    short_id = pShortId.cast<Utf8>().toDartString();
    did_key = DID(bindings.multipass_identity_did_key(pointer));
    graphics = Graphics(bindings.multipass_identity_graphics(pointer));
    Pointer<Char> ptr = bindings.multipass_identity_status_message(pointer);
    status_message = ptr != nullptr ? ptr.cast<Utf8>().toDartString() : null;

    //TODO: Complete
    calloc.free(pShortId);
    calloc.free(ptr);
    calloc.free(pUsername);
    bindings.identity_free(pointer);
  }
}

class FriendRequest {
  late DID from;
  late DID to;
  late String status;
  // late int date;

  FriendRequest(Pointer<G_FriendRequest> pointer) {
    from = DID(bindings.multipass_friend_request_from(pointer));
    to = DID(bindings.multipass_friend_request_to(pointer));
    int statusInt = bindings.multipass_friend_request_status(pointer);
    switch (statusInt) {
      case 0:
        status = "Uninitialized";
        break;
      case 1:
        status = "Pending";
        break;
      case 2:
        status = "Accepted";
        break;
      case 3:
        status = "Denied";
        break;
      case 4:
        status = "FriendRemoved";
        break;
      case 5:
        status = "RequestRemoved";
        break;
    }
    //bindings.friendrequest_free(pointer);
  }

  String toString() {
    String fromString = from.toString();
    String toString = to.toString();

    String request = "From: $fromString\nTo: $to\nStatus: $status";
    return request;
  }

  void drop() {
    from.drop();
    to.drop();
  }
}

class MultiPass {
  Pointer<G_MultiPassAdapter> pointer;
  MultiPass(this.pointer);

  DID createIdentity(String username, String password) {
    G_FFIResult_DID result = bindings.multipass_create_identity(
        pointer,
        username.toNativeUtf8().cast<Char>(),
        password.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    return DID(result.data);
  }

  List<Identity> getIdentity(Identifier identifier) {
    G_FFIResult_FFIVec_Identity result =
        bindings.multipass_get_identity(pointer, identifier.pointer());
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<Identity> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_Identity> pointer = result.data.ref.ptr.elementAt(i).value;
      Identity identity = Identity(pointer);
      list.add(identity);
    }

    //TODO: Determine if we need to free the pointer array
    // bindings.ffivec_identity_free(result.data);
    return list;
  }

  List<Identity> getIdentityByUsername(String username) {
    Identifier identifier = Identifier.fromUserName(username);
    List<Identity> list;
    try {
      list = getIdentity(identifier);
    } on WarpException {
      rethrow;
    } finally {
      identifier.drop();
    }
    return list;
  }

  Identity getIdentityByDID(String didKey) {
    Identifier identifier = Identifier.fromDIDString(didKey);
    List<Identity> list;
    try {
      list = getIdentity(identifier);
    } on WarpException {
      rethrow;
    } finally {
      identifier.drop();
    }

    if (list.isEmpty) {
      throw Exception("Identity not found");
    }

    return list.first;
  }

  Identity getOwnIdentity() {
    G_FFIResult_Identity result = bindings.multipass_get_own_identity(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    return Identity(result.data);
  }

  void updateIdentity(IdentityUpdate option) {
    G_FFIResult_Null result =
        bindings.multipass_update_identity(pointer, option.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void refresh_cache() {
    G_FFIResult_Null result = bindings.multipass_refresh_cache(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void sendFriendRequest(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_send_request(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void acceptFriendRequest(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_accept_request(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void denyFriendRequest(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_deny_request(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void closeFriendRequest(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_close_request(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  List<FriendRequest> listIncomingRequest() {
    G_FFIResult_FFIVec_FriendRequest result =
        bindings.multipass_list_incoming_request(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<FriendRequest> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_FriendRequest> pointer = result.data.ref.ptr.elementAt(i).value;
      FriendRequest request = FriendRequest(pointer);
      list.add(request);
    }

    //TODO: Free result.data

    return list;
  }

  List<FriendRequest> listOutgoingRequest() {
    G_FFIResult_FFIVec_FriendRequest result =
        bindings.multipass_list_outgoing_request(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<FriendRequest> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_FriendRequest> pointer = result.data.ref.ptr.elementAt(i).value;
      FriendRequest request = FriendRequest(pointer);
      list.add(request);
    }

    //TODO: Determine if we should free the pointers in the list first
    bindings.ffivec_friendrequest_free(result.data);
    return list;
  }

  List<FriendRequest> listAllRequest() {
    G_FFIResult_FFIVec_FriendRequest result =
        bindings.multipass_list_all_request(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<FriendRequest> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_FriendRequest> pointer = result.data.ref.ptr.elementAt(i).value;
      FriendRequest request = FriendRequest(pointer);
      list.add(request);
    }

    //TODO: Determine if we should free the pointers in the list first
    bindings.ffivec_friendrequest_free(result.data);
    return list;
  }

  void removeFriend(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_remove_friend(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void block(DID key) {
    G_FFIResult_Null result = bindings.multipass_block(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void unblock(DID key) {
    G_FFIResult_Null result = bindings.multipass_unblock(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  List<DID> blockList() {
    G_FFIResult_FFIVec_DID result = bindings.multipass_block_list(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<DID> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_DID> pointer = result.data.ref.ptr.elementAt(i).value;
      DID key = DID(pointer);
      list.add(key);
    }

    //TODO: Determine if we should free the pointers in the list first
    //bindings.ffivec_did_free(result.data);
    return list;
  }

  List<DID> listFriends() {
    G_FFIResult_FFIVec_DID result = bindings.multipass_list_friends(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<DID> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_DID> pointer = result.data.ref.ptr.elementAt(i).value;
      DID key = DID(pointer);
      list.add(key);
    }
    //TODO: Determine if we should free the pointers in the list first
    //bindings.ffivec_did_free(result.data);
    return list;
  }

  void hasFriend(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_has_friend(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void drop() {
    bindings.multipassadapter_free(pointer);
  }
}

String generateName() {
  Pointer<Char> ptr = bindings.multipass_generate_name();
  String name = ptr.cast<Utf8>().toDartString();
  //TODO: Free ptr
  return name;
}
