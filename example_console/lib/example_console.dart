import 'dart:ffi';
import 'dart:io';

import 'package:warp_dart/warp.dart';
import 'package:warp_dart/mp_ipfs.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/rg_ipfs.dart';
import 'package:warp_dart/raygun.dart';

MultiPass newAccount(String pass) {
  Tesseract? tesseract = Tesseract.newStore();
  tesseract.unlock(pass);

  MultiPass mp = multipass_ipfs_temporary(tesseract);
  DID? did = mp.createIdentity("", "");
  if (did.pointer == nullptr) {
    Exception("Error creating identity");
  }

  return mp;
}

Raygun newChat(MultiPass mp) {
  Raygun rg = raygun_ipfs_temporary(mp);
  return rg;
}

void test_rg_ipfs() {
  print("==== Test for rg_ipfs ====");

  print("New accounts");
  MultiPass accountA = newAccount("c_datastore_a");
  MultiPass accountB = newAccount("c_datastore_b");
  if (accountA.pointer == nullptr || accountB.pointer == nullptr) {
    print("Error creating account\n");
    exit(-1);
  }

  print("Get own identity");
  Identity idB = accountB.getOwnIdentity();
  if (idB.status_message != "N/A") {
    print(""); // TODO: What is the appripriate error message?
    exit(-1);
  }

  print("New chats");
  Raygun rgA = newChat(accountA);
  Raygun rgB = newChat(accountB);
  if (rgA.pRaygun == nullptr || rgB.pRaygun == nullptr) {
    print("Error creating account\n");
    exit(-1);
  }
  sleep(Duration(seconds: 1));

  print("Create conversation");
  DID didB = idB.did_key;
  String didBString = didB.toString();
  String convoID = rgA.createConversation(didBString);

  print("");

  print("Send messages via account A");
  List<String> chatMessagesA = [];
  chatMessagesA.add("Hello, World!!");
  chatMessagesA.add("How are you??");
  // chatMessagesA.add("Has your day been good???");
  // chatMessagesA.add("Mine is great");
  // chatMessagesA.add("You there????");
  // chatMessagesA.add("Just tired from dealing with C :D");
  // chatMessagesA.add("Rust rules!!!");
  rgA.send(convoID, null, chatMessagesA);
  sleep(Duration(seconds: 1));

  print("Get messages via account B");
  List<Message> messages = rgB.getMessages(convoID);
  for (var msg in messages) {
    for (var line in msg.value) {
      print("- $line");
    }
  }

  print("");

  print("Send messages via account B");
  List<String> chatMessagesB = [];
  chatMessagesB.add("Hello from Catter A :D");
  // chatMessagesB.add("I've grown tired of C");
  // chatMessagesB.add("Rust is life");
  // chatMessagesB.add("Sooooooooooo tired");
  // chatMessagesB.add(
  //     "Dreamed of being within a dream and waking up from that dream while in a dream :D");
  rgB.send(convoID, null, chatMessagesB);
  sleep(Duration(seconds: 1));

  print("Get messages via account A");
  List<Message> messages2 = rgA.getMessages(convoID);
  for (var msg in messages2) {
    for (var line in msg.value) {
      print("- $line");
    }
  }
}
