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
    rg = raygun_ipfs_persistent(mp, path);
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
