import 'dart:ffi';
import 'dart:io';
import 'package:example_console/common.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';

void test_mp_ipfs() {
  try {
    print("==== Test for mp_ipfs ====");

    IdentityUpdate identityUpdate = IdentityUpdate(nullptr);

    print("New accounts");
    MultiPass accountA = newAccount("/tmp/warp-dart-c", "warp-dart-c", "warp");
    MultiPass accountB = newAccount("/tmp/warp-dart-d", "warp-dart-d", "warp");

    if (accountA.pointer == nullptr || accountB.pointer == nullptr) {
      print("Error creating account\n");
      exit(-1);
    }

    print("\nGet own identity");
    Identity idA = accountA.getOwnIdentity();
    if (idA.status_message != null) {
      print(""); // TODO: What is the appripriate error message?
      exit(-1);
    }

    print("\nGet account info\n");
    getIdentityInfo(idA);

    print("\nSet username and show account info\n");
    identityUpdate = IdentityUpdate.setUsername("John");
    accountA.updateIdentity(identityUpdate);
    idA = accountA.getOwnIdentity();
    getIdentityInfo(idA);

    print("\nSet status message and show account info\n");
    identityUpdate = IdentityUpdate.setStatusMessage("Hello I'm here");
    accountA.updateIdentity(identityUpdate);
    idA = accountA.getOwnIdentity();
    getIdentityInfo(idA);

    print("\nSet profile picture and show account info\n");
    identityUpdate = IdentityUpdate.setPicture("My profile");
    accountA.updateIdentity(identityUpdate);
    idA = accountA.getOwnIdentity();
    getIdentityInfo(idA);

    print("\nSet profile banner and show account info\n");
    identityUpdate = IdentityUpdate.setBanner("My banner");
    accountA.updateIdentity(identityUpdate);
    idA = accountA.getOwnIdentity();
    getIdentityInfo(idA);

    print("\nCreate a second Identity\n");
    Identity idB = accountB.getOwnIdentity();
    idB.username = "Phil";
    getIdentityInfo(idB);

    print("\nUser A send a friend request to user B\n");
    accountA.sendFriendRequest(idB.did_key);
    List<FriendRequest> outgoingRequest = accountA.listOutgoingRequest();
    sleep(Duration(seconds: 1));
    List<FriendRequest> incomingRequest = accountB.listIncomingRequest();
    print("List Ougoing Request From User A: $outgoingRequest");
    print("List Incoming Request From User B: $incomingRequest");
    sleep(Duration(seconds: 1));
    //sleep(Duration(hours: 1));

    print("\nBlock a friend\n");
    try {
      accountB.block(idA.did_key);
      String user = idA.did_key.toString();
      print("User: $user is blocked now\n");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }
    List<DID> blockList = accountB.blockList();
    print("List of blocked users:");
    for (var element in blockList) {
      print(element.toString());
    }

    print("\nUser B accepts a friend request from user A\n");
    try {
      accountB.acceptFriendRequest(idA.did_key);
      sleep(Duration(seconds: 1));
      outgoingRequest = accountA.listOutgoingRequest();
      incomingRequest = accountB.listIncomingRequest();
      print("List Ougoing Request From User A: $outgoingRequest");
      print("List Incoming Request From User B: $incomingRequest");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }
    try {
      accountB.hasFriend(idA.did_key);
      print("User A and User B are friends");
    } catch (e) {
      print("User A and User B are not friends");
    }

    print("\nUnblock a friend\n");
    try {
      accountB.unblock(idA.did_key);
      String user = idA.did_key.toString();
      print("User: $user is unblocked now\n");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }
    blockList = accountB.blockList();
    print("List of blocked users:");
    for (var element in blockList) {
      print(element.toString());
    }

    print("\nUser B accepts a friend request from user A\n");
    try {
      accountB.acceptFriendRequest(idA.did_key);
      sleep(Duration(seconds: 1));
      outgoingRequest = accountA.listOutgoingRequest();
      incomingRequest = accountB.listIncomingRequest();
      print("List Ougoing Request From User A: $outgoingRequest");
      print("List Incoming Request From User B: $incomingRequest");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }
    try {
      accountB.hasFriend(idA.did_key);
      print("User A and User B are friends");
    } catch (e) {
      print("User A and User B are not friends");
    }

    print("\nUser B remove user A as friend\n");
    accountB.removeFriend(idA.did_key);
    sleep(Duration(seconds: 1));
    try {
      accountB.hasFriend(idA.did_key);
      print("User A and User B are friends");
    } catch (e) {
      print("User A and User B are not friends");
    }

    print("\nUser A send a friend request to user B\n");
    accountA.sendFriendRequest(idB.did_key);
    outgoingRequest = accountA.listOutgoingRequest();
    sleep(Duration(seconds: 1));
    incomingRequest = accountB.listIncomingRequest();
    print("List Ougoing Request From User A: $outgoingRequest");
    print("List Incoming Request From User B: $incomingRequest");
    sleep(Duration(seconds: 1));
    //sleep(Duration(hours: 1));

    print("\nUser B deny a friend request from user A\n");
    accountB.denyFriendRequest(idA.did_key);
    sleep(Duration(seconds: 1));
    outgoingRequest = accountA.listOutgoingRequest();
    incomingRequest = accountB.listIncomingRequest();
    print("List Ougoing Request From User A: $outgoingRequest");
    print("List Incoming Request From User B: $incomingRequest");
    try {
      accountB.hasFriend(idA.did_key);
      print("User A and User B are friends");
    } catch (e) {
      print("User A and User B are not friends");
    }
  } on WarpException catch (e) {
    print(e.errorMessage());
  }
}
