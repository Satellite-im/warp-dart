import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
// import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

enum Uid {
  id,
  didKey,
}

enum ReactionState {
  add,
  remove,
}

enum PinState {
  pin,
  unpin,
}

enum EmbedState {
  enabled,
  disabled,
}

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

class SenderId {
  late Uid uid;
}

class Raygun {
  Pointer<G_RayGunAdapter> pRaygun;
  Raygun(this.pRaygun);

  List<Message> getMessages(String conversationID) {
    // During the conversion, make sure:
    // - the IDs should go with toString as it is an index of something
    // - the message body should go with toDartString as it is an actual string

    // Get messages and null check
    G_FFIResult_FFIVec_Message messages = bindings.raygun_get_messages(
        pRaygun, conversationID.toNativeUtf8().cast<Int8>());
    if (messages.error != nullptr) {
      throw WarpException(messages.error);
    }
    // Iterate over the messages
    List<Message> msgs = [];
    int length = messages.data.ref.len;
    for (int i = 0; i < length; i++) {
      Message message = Message();
      Pointer<G_Message> pMsg = messages.data.ref.ptr.elementAt(i).value;
      // Message ID
      message.id = bindings.message_id(pMsg).value.toString();
      // Conversation ID
      message.conversationId =
          bindings.message_conversation_id(pMsg).value.toString();
      // Sender ID, DID only
      Pointer<G_SenderId> pSenderId = bindings.message_sender_id(pMsg);
      Pointer<G_DID> pSenderDid = bindings.sender_id_get_did_key(pSenderId);
      message.senderId = DID(pSenderDid).toString();
      // DateTime
      // TODO: test required
      // The value from Rust is integer (UTC from Chrono ).
      // Possibly DateTime.fromMillisecondsSinceEpoch() can be used.
      message.date = DateTime(bindings.message_date(pMsg).value);
      // Pinned
      message.pinned = bindings.message_pinned(pMsg) != 0;
      // Reactions
      List<Reaction> reactions = [];
      Pointer<G_FFIVec_Reaction> pReactions = bindings.message_reactions(pMsg);
      int reactionsLen = pReactions.ref.len;
      for (int j = 0; j < reactionsLen; j++) {
        Reaction reaction = Reaction();
        Pointer<G_Reaction> pReaction = pReactions.ref.ptr.elementAt(j).value;
        reaction.emoji = bindings.reaction_emoji(pReaction).toString();
        Pointer<G_FFIVec_SenderId> pReactionSendersId =
            bindings.reaction_users(pReaction);
        int reactionSendersIdLen = pReactionSendersId.ref.len;
        for (int k = 0; k < reactionSendersIdLen; k++) {
          reaction.senderId
              .add(pReactionSendersId.ref.ptr.elementAt(k).value.toString());
        }
        calloc.free(pReaction);
        calloc.free(pReactionSendersId);
      }
      message.reactions = reactions;
      // Replied
      Pointer<Int8> pReplied = bindings.message_replied(pMsg);
      if (pReplied.address.toString() != "0") {
        message.replied = pReplied.toString();
      }
      // Message body
      Pointer<G_FFIVec_String> pLines = bindings.message_lines(pMsg);
      int lineLen = pLines.ref.len;
      for (int j = 0; j < lineLen; j++) {
        message.value
            .add(pLines.ref.ptr.elementAt(j).cast<Utf8>().toDartString());
      }
      // Add to the upstream variable
      msgs.add(message);
      // Release
      calloc.free(pMsg);
      calloc.free(pReactions);
      calloc.free(pReplied);
      calloc.free(pLines);
      calloc.free(pSenderDid);
      calloc.free(pSenderId);

      // TODO: Metadata - Rust binding is not ready
    }

    return msgs;
  }

  // This method serves for sending and editing.
  // If there is message sent, Warp will cover the editing part.
  send(String conversationId, [String? messageId, List<String>? messages]) {
    // Parameter validation
    if (messageId == null && messages == null) {
      throw Exception("Both given message ID and body are null");
    }
    if (messages != null && messages.isEmpty) {
      throw Exception("The given message is not null but empty");
    }
    // With the using keyword the allocated memories by Arena will be released
    using((Arena arena) {
      // Convert given values to native friendly types
      Pointer<Int8> pConvoId = calloc<Int8>();
      pConvoId = conversationId.toNativeUtf8().cast<Int8>();
      Pointer<Int8> pMessageId = calloc<Int8>();
      pMessageId =
          messageId != null ? messageId.toNativeUtf8().cast<Int8>() : nullptr;
      // Allocation
      Pointer<Pointer<Int8>> pMessages =
          Arena().allocate<Pointer<Int8>>(messages!.length);
      // Copy
      for (int i = 0; i < messages.length; i++) {
        pMessages[i] = messages[i].toNativeUtf8().cast<Int8>();
      }
      // Invoke and result check
      G_FFIResult_Null result = bindings.raygun_send(
          pRaygun, pConvoId, pMessageId, pMessages, messages.length);
      if (result.error != nullptr) {
        throw WarpException(result.error);
      }
      // Release
      calloc.free(pConvoId);
      calloc.free(pMessageId);
    });
  }

  delete(String conversationId, [String? messageId]) {
    // Convert given values to native friendly types
    Pointer<Int8> pConvoId = conversationId.toNativeUtf8().cast<Int8>();
    Pointer<Int8> pMessageId =
        messageId != null ? messageId.toNativeUtf8().cast<Int8>() : nullptr;
    // Invoke and result check
    G_FFIResult_Null result =
        bindings.raygun_delete(pRaygun, pConvoId, pMessageId);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pConvoId);
    calloc.free(pMessageId);
  }

  react(String conversationId, String messageId, ReactionState reactionState,
      String emoji) {
    // Convert given values to native friendly types
    Pointer<Int8> pConvoId = conversationId.toNativeUtf8().cast<Int8>();
    Pointer<Int8> pMessageId = messageId.toNativeUtf8().cast<Int8>();
    int _reactionState = reactionState.index;
    Pointer<Int8> _emoji = emoji.toNativeUtf8().cast<Int8>();
    // Invoke and result check
    G_FFIResult_Null result = bindings.raygun_react(
        pRaygun, pConvoId, pMessageId, _reactionState, _emoji);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pConvoId);
    calloc.free(pMessageId);
  }

  pin(String conversationId, String messageId, PinState pinState) {
    // Convert given values to native friendly types
    Pointer<Int8> pConvoId = conversationId.toNativeUtf8().cast<Int8>();
    Pointer<Int8> pMessageId = messageId.toNativeUtf8().cast<Int8>();
    int vPinState = pinState.index;
    // Invoke and result check
    G_FFIResult_Null result =
        bindings.raygun_pin(pRaygun, pConvoId, pMessageId, vPinState);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pConvoId);
    calloc.free(pMessageId);
  }

  reply(String conversationId, [String? messageId, List<String>? messages]) {
    // Parameter validation
    if (messageId == null && messages == null) {
      throw Exception("Both given message ID and body are null");
    }
    if (messages != null && messages.isEmpty) {
      throw Exception("The given message is not null but empty");
    }
    // With the using keyword the allocated memories by Arena will be released
    using((Arena arena) {
      // Convert given values to native friendly types
      Pointer<Int8> pConvoId = calloc<Int8>();
      pConvoId = conversationId.toNativeUtf8().cast<Int8>();
      Pointer<Int8> pMessageId = calloc<Int8>();
      pMessageId =
          messageId != null ? messageId.toNativeUtf8().cast<Int8>() : nullptr;
      // Allocation
      Pointer<Pointer<Int8>> _pMessages =
          Arena().allocate<Pointer<Int8>>(messages!.length);
      // Copy
      for (int i = 0; i < messages.length; i++) {
        _pMessages[i] = messages[i].toNativeUtf8().cast<Int8>();
      }
      // Invoke and result check
      G_FFIResult_Null result = bindings.raygun_reply(
          pRaygun, pConvoId, pMessageId, _pMessages, messages.length);
      if (result.error != nullptr) {
        throw WarpException(result.error);
      }
      // Release
      calloc.free(pConvoId);
      calloc.free(pMessageId);
    });
  }

  embed(String conversationId, String messageId, EmbedState embedState) {
    // Convert given values to native friendly types
    Pointer<Int8> pConvoId = conversationId.toNativeUtf8().cast<Int8>();
    Pointer<Int8> pMessageId = messageId.toNativeUtf8().cast<Int8>();
    int vEmbedState = embedState.index;
    // Invoke and result check
    G_FFIResult_Null result =
        bindings.raygun_embeds(pRaygun, pConvoId, pMessageId, vEmbedState);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pConvoId);
    calloc.free(pMessageId);
  }

  createConversation(String didKey) {
    // Prepare a DID
    DID did = DID.fromString(didKey);
    // Invoke and result check
    G_FFIResult_String result =
        bindings.raygun_create_conversation(pRaygun, did.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    did.drop();
  }

  List<String> listConversation() {
    // Invoke and result check
    G_FFIResult_FFIVec_String result =
        bindings.raygun_list_conversations(pRaygun);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Collect conversation IDs
    int conversationsLen = result.data.ref.len;
    List<String> conversationIDs = [];
    for (int i = 0; i < conversationsLen; i++) {
      Pointer<Int8> pConversationID = result.data.ref.ptr.elementAt(i).value;
      conversationIDs.add(pConversationID.toString());
      calloc.free(pConversationID);
    }

    return conversationIDs;
  }
}
