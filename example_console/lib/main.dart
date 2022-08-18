import 'dart:ffi';

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
    Exception("DID pointer is null");
  }

  return mp;
}

int main() {
  print("Hello");

  MultiPass accountA = newAccount("c_datastore_a");
  MultiPass accountB = newAccount("c_datastore_b");
  if (accountA.pointer == nullptr || accountB.pointer == nullptr) {
    print("Error creating account\n");
    return -1;
  }

  return 0;
}
