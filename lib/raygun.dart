import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

class Raygun {
  Pointer<G_RayGunAdapter> pointer;
  Raygun(this.pointer);

  List<String> getMessages(String conversationID) {
    G_FFIResult_FFIVec_Message result = bindings.raygun_get_messages(
        pointer, conversationID.toNativeUtf8().cast<Int8>());

    if (result.error.address.toString() != "0") {
      throw WarpException(result.error);
    }

    List<String> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_Message> pointer = result.data.ref.ptr.elementAt(i).value;
      list.add(pointer.toString());
    }

    return list;
  }
}
