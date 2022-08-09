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

class Message {
  late String id;
  late String conversationId;
  late String senderId;
  late int date;
  // Bool pinned
  // List<Reactions> reactions
  // UUID replied
  late List<String> value;
  // Map<String, String> metadata
}

class Raygun {
  Pointer<G_RayGunAdapter> pointer;
  Raygun(this.pointer);

  List<Message> getMessages(String conversationID) {
    G_FFIResult_FFIVec_Message result = bindings.raygun_get_messages(
        pointer, conversationID.toNativeUtf8().cast<Int8>());

    if (result.error.address.toString() != "0") {
      throw WarpException(result.error);
    }

    List<Message> msgs = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Message message = Message();
      Pointer<G_Message> msgPointer = result.data.ref.ptr.elementAt(i).value;
      message.id = bindings.message_id(msgPointer).toString();
      message.conversationId =
          bindings.message_conversation_id(msgPointer).toString();
      message.senderId = bindings.message_sender_id(msgPointer).toString();

      // TODO: How to convert Rust ffi.Int8 to Dart int?
      // message.date = bindings.message_date(msgPointer);

      // Message body
      Pointer<G_FFIVec_String> lines = bindings.message_lines(msgPointer);
      int lineLen = lines.ref.len;
      for (int j = 0; j < lineLen; j++) {
        message.value.add(lines.ref.ptr.value.toString());
      }
      msgs.add(message);
    }

    return msgs;
  }
}
