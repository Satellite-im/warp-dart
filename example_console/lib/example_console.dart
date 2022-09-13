import 'dart:ffi';
import 'dart:io';

import 'package:warp_dart/costellation.dart';
import 'package:warp_dart/fs_memory.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/mp_ipfs.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/rg_ipfs.dart';
import 'package:warp_dart/raygun.dart';

MultiPass newAccount(String path, String username, String pass) {
  late Tesseract tesseract;
  try {
    tesseract = Tesseract.fromFile('$path/.keystore');
  } on WarpException {
    tesseract = Tesseract.newStore();
    tesseract.setFile('$path/.keystore');
    tesseract.setAutosave();
  }

  tesseract.unlock(pass);
  late MultiPass mp;
  try {
    mp = multipass_ipfs_temporary(tesseract /*, path*/);
  } on WarpException {
    rethrow;
  }

  try {
    Identity id = mp.getOwnIdentity();
    print("Found account - " + id.username);
  } on WarpException {
    print("Creating account");
    mp.createIdentity(username, "");
    Identity id = mp.getOwnIdentity();
    print("Created account - " + id.username);
  }

  return mp;
}

Raygun newChat(MultiPass mp, String path) {
  late Raygun rg;
  try {
    rg = raygun_ipfs_temporary(
      mp, /*path*/
    );
  } on WarpException {
    rethrow;
  }
  return rg;
}

void getIdentityInfo(Identity identity) {
  String did = identity.did_key.toString();
  String username = identity.username;
  String shortID = identity.short_id;
  String? statusMessage = identity.status_message;
  String profilePicture = identity.graphics.profile_picture;
  String profileBanner = identity.graphics.profile_banner;

  print("DID: $did");
  print("Username: $username");
  print("Short ID: $shortID");
  print("Status Message: $statusMessage");
  print("Profile Picture: $profilePicture");
  print("Profile Banner: $profileBanner");
}

void test_rg_ipfs() {
  try {
    print("==== Test for rg_ipfs ====");

    print("New accounts");
    MultiPass accountA = newAccount("/tmp/warp-dart-a", "warp-dart-a", "warp");
    MultiPass accountB = newAccount("/tmp/warp-dart-b", "warp-dart-b", "warp");

    print("Get own identity");
    Identity idA = accountA.getOwnIdentity();
    Identity idB = accountB.getOwnIdentity();

    print("New chats");
    Raygun rgA = newChat(accountA, "/tmp/warp-dart-a");
    Raygun rgB = newChat(accountB, "/tmp/warp-dart-b");

    sleep(Duration(seconds: 1));

    List<Conversation> conversations = rgA.listConversation();
    print("Create conversation");
    DID didB = idB.did_key;
    String didBString = didB.toString();
    print(didBString);
    late Conversation convo;
    if (conversations.isEmpty) {
      convo = rgA.createConversation(didBString);
    } else {
      convo = conversations.elementAt(0);
    }

    print("");

    print("Send messages via account A");
    List<String> chatMessagesA = [];
    chatMessagesA.add("Hello, World!!");
    chatMessagesA.add("How are you??");
    chatMessagesA.add("Has your day been good???");
    chatMessagesA.add("Mine is great");
    chatMessagesA.add("You there????");
    chatMessagesA.add("Just tired from dealing with C :D");
    chatMessagesA.add("Rust rules!!!");
    rgA.send(convo.id, chatMessagesA);
    sleep(Duration(seconds: 1));

    print("Get messages via account B");
    List<Message> messages = rgB.getMessages(convo.id);
    for (var msg in messages) {
      Identity id = accountB.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print(id.username + " - $line");
      }
    }

    print("");

    print("Send messages via account B");
    List<String> chatMessagesB = [];
    chatMessagesB.add("Hello from Chatter A :D");
    chatMessagesB.add("I've grown tired of C");
    chatMessagesB.add("Rust is life");
    chatMessagesB.add("Sooooooooooo tired");
    chatMessagesB.add(
        "Dreamed of being within a dream and waking up from that dream while in a dream :D");

    rgB.send(convo.id, chatMessagesB);
    sleep(Duration(seconds: 1));

    print("Get messages via account A");
    List<Message> messages2 = rgA.getMessages(convo.id);
    for (var msg in messages2) {
      Identity id = accountA.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print("${id.username} - $line");
      }
    }

    print("Edit second Message");
    chatMessagesB[0] = "hello";
    chatMessagesB[1] = "hi";
    rgB.edit(convo.id, messages2[1].id, chatMessagesB);
    sleep(Duration(seconds: 1));

    print("Get messages via account A after change");
    List<Message> messages3 = rgA.getMessages(convo.id);
    for (var msg in messages3) {
      Identity id = accountA.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print("${id.username} - $line");
      }
    }

    print("Delete second Message");
    rgB.delete(convo.id, messages2[1].id);
    sleep(Duration(seconds: 1));

    print("Get messages via account A after deleting");
    List<Message> messages4 = rgA.getMessages(convo.id);
    for (var msg in messages4) {
      Identity id = accountA.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print("${id.username} - $line");
      }
    }

    print("React to a Message");
    rgB.react(convo.id, messages2[0].id, ReactionState.add, "happy");
    sleep(Duration(seconds: 1));

    print("Get reaction of message from account A");
    List<Message> messages5 = rgA.getMessages(convo.id);
    if (messages5[0].reactions.isNotEmpty) {
      for (var reaction in messages5[0].reactions) {
        print("Emoji: ${reaction.emoji}");
        /*print("Senders:");
        for (var sender in reaction.sender) {
          print(sender.toString());
        }*/
      }
    } else {
      print("No reactions");
    }

    print("Remove Reaction to a Message");
    rgB.react(convo.id, messages2[0].id, ReactionState.remove, "happy");
    sleep(Duration(seconds: 1));

    print("Get reactions of message from account A");
    List<Message> messages6 = rgA.getMessages(convo.id);
    if (messages6[0].reactions.isNotEmpty) {
      for (var reaction in messages6[0].reactions) {
        print("Emoji: ${reaction.emoji}");
        /*print("Senders:");
        for (var sender in reaction.sender) {
          print(sender.toString());
        }*/
      }
    } else {
      print("No reactions");
    }

    print("Pin a Message");
    rgB.pin(convo.id, messages2[0].id, PinState.pin);
    sleep(Duration(seconds: 1));

    print("Verify if message is pinned");
    List<Message> messages7 = rgA.getMessages(convo.id);
    print("Pinned? ${messages7[0].pinned}");

    print("Unpin a Message");
    rgB.pin(convo.id, messages2[0].id, PinState.unpin);
    sleep(Duration(seconds: 1));

    print("Verify if message is pinned");
    List<Message> messages8 = rgA.getMessages(convo.id);
    print("Pinned? ${messages8[0].pinned}");

    print("Reply a Message");
    rgB.reply(convo.id, messages2[0].id, ["HI"]);
    sleep(Duration(seconds: 1));

    print("Get Reply");
    List<Message> messages9 = rgA.getMessages(convo.id);
    print("Reply:  ${messages9[1].replied}");

    /*print("Embed a Message");
    rgB.embed(convo.id, messages2[0].id, EmbedState.enabled);
    sleep(Duration(seconds: 1));

    print("Get Reply");
    List<Message> messages10 = rgA.getMessages(convo.id);
    print("Reply:  ${messages10[0]}");*/
  } on WarpException catch (e) {
    print(e.errorMessage());
  }
}

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

void test_fs_memory() {
  try {
    print("==== Test for fs_memory ====");

    print("\nCreate Filesystem\n");
    Constellation constellation = initConstellation();

    print("\nCreateDiretory\n");
    Directory directory = constellation.newDirectory("warp-dart-directory-1");

    print("\nGet directory details\n");
    print("Directory Id: ${directory.id}");
    print("Directory Name: ${directory.name}");

    /*print("\nAdd description to Directory\n");
    directory.setDescription("This is my directory");

    print("\nGet directory details\n");
    print("Directory Id: ${directory.id}");
    print("Directory Name: ${directory.name}");
    print("Directory Description: ${directory.description}");*/

    String remote = "test";
    String local = "test";

    constellation.UploadToFilesystem(remote, local);

    //constellation.downloadFileFromFilesystem("file.txt", "/tmp/file.txt");
  } on WarpException catch (e) {
    print(e.errorMessage());
  }
}
