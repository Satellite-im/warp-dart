import 'dart:ffi';
import 'dart:io';

import 'package:warp_dart/warp.dart';
import 'package:warp_dart/mp_ipfs.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/rg_ipfs.dart';
import 'package:warp_dart/raygun.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

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

void rg_ipfs_test() {
  print("Test for rg_ipfs");

  MultiPass accountA = newAccount("c_datastore_a");
  MultiPass accountB = newAccount("c_datastore_b");
  if (accountA.pointer == nullptr || accountB.pointer == nullptr) {
    print("Error creating account\n");
    exit(-1);
  }

  Identity idB = accountB.getOwnIdentity();
  if (idB.status_message != "N/A") {
    print(""); // TODO: What is the appripriate error message?
    exit(-1);
  }

  Raygun rgA = newChat(accountA);
  Raygun rgB = newChat(accountB);
  if (rgA.pRaygun == nullptr || rgB.pRaygun == nullptr) {
    print("Error creating account\n");
    exit(-1);
  }

  sleep(Duration(seconds: 1));

  DID didB = idB.did_key;
  rgA.createConversation(didB.toString()); // Doesn't return but throw an error
  List<String> convoID = rgA.listConversation();

  sleep(Duration(seconds: 1));

  List<String> chatMessageA = [];
  chatMessageA.add("Hello, World!!");
  chatMessageA.add("How are you??");
  chatMessageA.add("Has your day been good???");
  chatMessageA.add("Mine is great");
  chatMessageA.add("You there????");
  chatMessageA.add("Just tired from dealing with C :D");
  chatMessageA.add("Rust rules!!!");

  rgA.send(convoID[0], null, chatMessageA); // Doesn't return but throw an error

  sleep(Duration(seconds: 1));

  List<Message> messages = rgB.getMessages(convoID[0]);
  print(messages);
}

int main() {
  rg_ipfs_test();
  print("End of tests");
  return 0;
}
