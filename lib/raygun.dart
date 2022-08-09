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
  late DateTime date;
  late bool pinned;
  late List<Reaction> reactions;
  late String replied;
  late List<String> value;
  late Map<String, String> metadata;
}

class Reaction {
  late String emoji;
  late List<String> senderId;
}

enum Uid {
  id,
  didKey,
}

class SenderId {
  late Uid uid;
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

      message.id = bindings.message_id(msgPointer).value.toString();
      message.conversationId =
          bindings.message_conversation_id(msgPointer).value.toString();

      // TODO: sender ID can be uuid or did with its own class, how to?
      Pointer<G_SenderId> senderIdPointer =
          bindings.message_sender_id(msgPointer);

      Pointer<Int8> senderId = bindings.sender_id_get_id(senderIdPointer);
      if (senderId.value != 0) {
        message.senderId = senderId.value.toString();
      } else {
        Pointer<G_DID> senderDid =
            bindings.sender_id_get_did_key(senderIdPointer);
        message.senderId = DID(senderDid).toString();
      }

      // TODO: Is this the right way to convert Rust ffi.Int8 to Dart DateTime?
      message.date = DateTime(bindings.message_date(msgPointer).value);

      // TODO: Reactions
      // - seems like we suppose to use the returned pointer for reaction_emoji and reaction_users
      // - but the message_reactions returns only 1 pointer. Shouldn't there be a list?
      // message.reactions =
      bindings.message_reactions(msgPointer);

      message.pinned = bindings.message_pinned(msgPointer) == 0 ? false : true;

      // TODO: Replied - where is it?
      // bindings.message_

      // Message body
      Pointer<G_FFIVec_String> lines = bindings.message_lines(msgPointer);
      int lineLen = lines.ref.len;
      for (int j = 0; j < lineLen; j++) {
        message.value.add(lines.ref.ptr.value.toString());
      }
      msgs.add(message);

      // TODO: Metadata - Rust struct has a map, but no related function appears.
      // bindings.metadata
    }

    return msgs;
  }
}
