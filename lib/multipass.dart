import 'dart:ffi';
import 'package:ffi/ffi.dart';
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

enum FriendRequestStatusEnum {
  uninitialized,
  pending,
  accepted,
  denied,
  friendRemoved,
  requestRemoved
}

enum IdentityStatus { online, offline }

class Relationship {
  bool friends = false;
  bool receivedFriendRequest = false;
  bool sentFriendRequest = false;
  bool blocked = false;
  Relationship(Pointer<G_Relationship> pointer) {
    friends = bindings.multipass_identity_relationship_friends(pointer) != 0;
    receivedFriendRequest = bindings
            .multipass_identity_relationship_received_friend_request(pointer) !=
        0;
    sentFriendRequest =
        bindings.multipass_identity_relationship_sent_friend_request(pointer) !=
            0;
    blocked = bindings.multipass_identity_relationship_blocked(pointer) != 0;

    bindings.relationship_free(pointer);
  }
}

class FriendRequest {
  late DID from;
  late DID to;
  late FriendRequestStatusEnum status;
  // late int date;

  FriendRequest(Pointer<G_FriendRequest> pointer) {
    from = DID(bindings.multipass_friend_request_from(pointer));
    to = DID(bindings.multipass_friend_request_to(pointer));
    final _friendRequestStatusNum =
        bindings.multipass_friend_request_status(pointer);

    final _friendRequestStatusMap = {
      0: FriendRequestStatusEnum.uninitialized,
      1: FriendRequestStatusEnum.pending,
      2: FriendRequestStatusEnum.accepted,
      3: FriendRequestStatusEnum.denied,
      4: FriendRequestStatusEnum.friendRemoved,
      5: FriendRequestStatusEnum.requestRemoved,
    };
    status = _friendRequestStatusMap[_friendRequestStatusNum]!;
    bindings.friendrequest_free(pointer);
  }

  void drop() {
    from.drop();
    to.drop();
  }
}

class MultiPass {
  Pointer<G_MultiPassAdapter> pointer;
  MultiPass(this.pointer);

  DID createIdentity(String? username, String? passphrase) {
    Pointer<Char> pUsername =
        username != null ? username.toNativeUtf8().cast<Char>() : nullptr;

    Pointer<Char> pPassphrase =
        passphrase != null ? passphrase.toNativeUtf8().cast<Char>() : nullptr;

    G_FFIResult_DID result =
        bindings.multipass_create_identity(pointer, pUsername, pPassphrase);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    if (pUsername != nullptr) {
      calloc.free(pUsername);
    }

    if (pPassphrase != nullptr) {
      calloc.free(pPassphrase);
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

  Identity getIdentityByDID(String did_key) {
    Identifier identifier = Identifier.fromDIDString(did_key);
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

  void refreshCache() {
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

  bool receivedFriendRequestFrom(DID did) {
    G_FFIResult_bool result =
        bindings.multipass_received_friend_request_from(pointer, did.pointer);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    bool received = result.data.cast<Int8>().value != 0;
    calloc.free(result.data);

    return received;
  }

  bool sentFriendRequestTo(DID did) {
    G_FFIResult_bool result =
        bindings.multipass_sent_friend_request_to(pointer, did.pointer);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    bool sent = result.data.cast<Int8>().value != 0;
    calloc.free(result.data);

    return sent;
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

  bool isBlocked(DID did) {
    G_FFIResult_bool result =
        bindings.multipass_is_blocked(pointer, did.pointer);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    bool blocked = result.data.value != 0;
    calloc.free(result.data);
    return blocked;
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

    return list;
  }

  void hasFriend(DID key) {
    G_FFIResult_Null result =
        bindings.multipass_has_friend(pointer, key.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  IdentityStatus identityStatus(DID did) {
    G_FFIResult_IdentityStatus result =
        bindings.multipass_identity_status(pointer, did.pointer);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    late IdentityStatus status;
    switch (result.data.value) {
      case 0:
        status = IdentityStatus.online;
        break;
      case 1:
        status = IdentityStatus.offline;
        break;
    }
    calloc.free(result.data);

    return status;
  }

  Relationship identityRelationship(DID did) {
    G_FFIResult_Relationship result =
        bindings.multipass_identity_relationship(pointer, did.pointer);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    return Relationship(result.data);
  }

  void drop() {
    bindings.multipassadapter_free(pointer);
  }
}

String? generateName() {
  Pointer<Char> ptr = bindings.multipass_generate_name();
  if (ptr == nullptr) {
    return null;
  }
  String name = ptr.cast<Utf8>().toDartString();
  calloc.free(ptr);
  return name;
}
