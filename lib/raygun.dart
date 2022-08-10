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
    // Iterate over the messages
    int length = result.data.ref.len;
    for (int i = 0; i < length; i++) {
      Message message = Message();
      Pointer<G_Message> msgPointer = result.data.ref.ptr.elementAt(i).value;

      // Message ID
      message.id = bindings.message_id(msgPointer).value.toString();
      // Conversation ID
      message.conversationId =
          bindings.message_conversation_id(msgPointer).value.toString();
      // Sender ID, DID only
      Pointer<G_SenderId> senderIdPointer =
          bindings.message_sender_id(msgPointer);
      Pointer<G_DID> senderDid =
          bindings.sender_id_get_did_key(senderIdPointer);
      message.senderId = DID(senderDid).toString();
      // DateTime
      // TODO: test required
      // The value from Rust is integer (UTC from Chrono ).
      // Possibly DateTime.fromMillisecondsSinceEpoch() can be used.
      message.date = DateTime(bindings.message_date(msgPointer).value);
      // Reactions
      List<Reaction> reactions = [];
      Pointer<G_FFIVec_Reaction> reactionsPointer =
          bindings.message_reactions(msgPointer);
      int reactionsLen = reactionsPointer.ref.len;
      for (int j = 0; j < reactionsLen; j++) {
        Reaction reaction = Reaction();
        Pointer<G_Reaction> reactionPointer =
            reactionsPointer.ref.ptr.elementAt(j).value;
        reaction.emoji = bindings.reaction_emoji(reactionPointer).toString();
        Pointer<G_FFIVec_SenderId> reactionSendersId =
            bindings.reaction_users(reactionPointer);
        int reactionSendersIdLen = reactionSendersId.ref.len;
        for (int k = 0; k < reactionSendersIdLen; k++) {
          reaction.senderId
              .add(reactionSendersId.ref.ptr.elementAt(k).value.toString());
        }
      }
      message.reactions = reactions;
      // Pinned
      message.pinned = bindings.message_pinned(msgPointer) == 0 ? false : true;
      // Message body
      Pointer<G_FFIVec_String> lines = bindings.message_lines(msgPointer);
      int lineLen = lines.ref.len;
      for (int j = 0; j < lineLen; j++) {
        message.value.add(lines.ref.ptr.value.toString());
      }
      msgs.add(message);

      // TODO: Replied - Rust binding is not ready
      // TODO: Metadata - Rust binding is not ready
    }

    return msgs;
  }
}
