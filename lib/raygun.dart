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
  late DID sender;
  late DateTime date;
  late bool pinned;
  late List<Reaction> reactions;
  late String? replied;
  late List<String> value;
  late Map<String, String> metadata;
  Message(Pointer<G_Message> pointer) {
    Pointer<Char> pId = bindings.message_id(pointer);
    id = pId.value.toString();

    Pointer<Char> pConversationId = bindings.message_conversation_id(pointer);
    conversationId = pConversationId.cast<Utf8>().toDartString();

    Pointer<G_DID> pSender = bindings.message_sender(pointer);
    sender = DID(pSender);

    date = DateTime(bindings.message_date(pointer).value);

    pinned = bindings.message_pinned(pointer) != 0;

    Pointer<G_FFIVec_Reaction> pReactions = bindings.message_reactions(pointer);
    int reactionLen = pReactions.ref.len;
    for (int i = 0; i < reactionLen; i++) {
      reactions.add(Reaction(pReactions.ref.ptr.elementAt(i).value));
    }

    Pointer<Char> pReplied = bindings.message_replied(pointer);
    if (pReplied != nullptr) {
      replied = pReplied.cast<Utf8>().toDartString();
      calloc.free(pReplied);
    }

    Pointer<G_FFIVec_String> pLines = bindings.message_lines(pointer);
    int lineLen = pLines.ref.len;
    for (int j = 0; j < lineLen; j++) {
      Pointer<Char> line = pLines.ref.ptr.elementAt(j).value;
      value.add(pLines.cast<Utf8>().toDartString());
      calloc.free(line);
    }

    calloc.free(pId);
    calloc.free(pConversationId);
    calloc.free(pLines);
    calloc.free(pReplied);
    bindings.ffivec_reaction_free(pReactions);
    bindings.message_free(pointer);
  }
}

class Reaction {
  late String emoji;
  late List<DID> sender;
  Reaction(Pointer<G_Reaction> pointer) {
    Pointer<Char> pEmoji = bindings.reaction_emoji(pointer);
    emoji = pEmoji.cast<Utf8>().toDartString();
    Pointer<G_FFIVec_DID> pReactionSenders = bindings.reaction_users(pointer);

    int reactionSendersIdLen = pReactionSenders.ref.len;
    for (int k = 0; k < reactionSendersIdLen; k++) {
      Pointer<G_DID> pSenderId = pReactionSenders.ref.ptr.elementAt(k).value;
      sender.add(DID(pSenderId));
      calloc.free(pSenderId);
    }
    calloc.free(pEmoji);
  }
}

class Conversation {
  late String id;
  late ConversationType type;
  late String? name;
  late List<DID> recipients;
  Conversation(Pointer<G_Conversation> pointer) {
    Pointer<Char> pId = bindings.conversation_id(pointer);
    id = pId.cast<Utf8>().toDartString();
    Pointer<Char> pName = bindings.conversation_name(pointer);
    name = pName.cast<Utf8>().toDartString();
    type = bindings.conversation_type(pointer) as ConversationType;
    Pointer<G_FFIVec_DID> pDIDs = bindings.conversation_recipients(pointer);
    int len = pDIDs.ref.len;
    for (int i = 0; i < len; i++) {
      recipients.add(DID(pDIDs.ref.ptr[i]));
    }
  }
}

class Raygun {
  Pointer<G_RayGunAdapter> pRaygun;
  Raygun(this.pRaygun);

  Conversation createConversation(String didKey) {
    // Prepare a DID
    late DID did;

    try {
      did = DID.fromString(didKey);
    } on WarpException {
      rethrow;
    }

    // Invoke and result check
    G_FFIResult_Conversation result =
        bindings.raygun_create_conversation(pRaygun, did.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    Conversation convoId = Conversation(result.data);

    did.drop();

    return convoId;
  }

  List<Conversation> listConversation() {
    // Invoke and result check
    G_FFIResult_FFIVec_Conversation result =
        bindings.raygun_list_conversations(pRaygun);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Collect conversation 
    int conversationsLen = result.data.ref.len;
    List<Conversation> conversations = [];
    for (int i = 0; i < conversationsLen; i++) {
      Pointer<G_Conversation> pConversation =
          result.data.ref.ptr.elementAt(i).value;
      conversations.add(Conversation(pConversation));
      calloc.free(pConversation);
    }

    return conversations;
  }

  List<Message> getMessages(String conversationID) {
    G_FFIResult_FFIVec_Message result = bindings.raygun_get_messages(
        pRaygun, conversationID.toNativeUtf8().cast<Char>());
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Iterate over the messages
    List<Message> msgs = [];
    int length = result.data.ref.len;
    for (int i = 0; i < length; i++) {
      msgs.add(Message(result.data.ref.ptr.elementAt(i).value));
    }

    bindings.ffivec_message_free(result.data);

    return msgs;
  }

  send(String conversationId, List<String> messages) {
    if (messages.isEmpty) {
      throw Exception("Message cannot be empty");
    }

    Pointer<Pointer<Char>> pMessages =
        calloc.allocate<Pointer<Char>>(messages.length);
    // Copy
    for (int i = 0; i < messages.length; i++) {
      pMessages[i] = messages[i].toNativeUtf8().cast<Char>();
    }
    // Invoke and result check
    G_FFIResult_Null result = bindings.raygun_send(
        pRaygun,
        conversationId.toNativeUtf8().cast<Char>(),
        nullptr,
        pMessages,
        messages.length);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pMessages);
  }

  edit(String conversationId, String messageId, List<String> messages) {
    if (messages.isEmpty) {
      throw Exception("Message cannot be empty");
    }

    Pointer<Pointer<Char>> pMessages =
        calloc.allocate<Pointer<Char>>(messages.length);
    // Copy
    for (int i = 0; i < messages.length; i++) {
      pMessages[i] = messages[i].toNativeUtf8().cast<Char>();
    }
    // Invoke and result check
    G_FFIResult_Null result = bindings.raygun_send(
        pRaygun,
        conversationId.toNativeUtf8().cast<Char>(),
        messageId.toNativeUtf8().cast<Char>(),
        pMessages,
        messages.length);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pMessages);
  }

  delete(String conversationId, [String? messageId]) {
    // Convert given values to native friendly types
    Pointer<Char> pConvoId = conversationId.toNativeUtf8().cast<Char>();
    Pointer<Char> pMessageId =
        messageId != null ? messageId.toNativeUtf8().cast<Char>() : nullptr;
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
    Pointer<Char> pConvoId = conversationId.toNativeUtf8().cast<Char>();
    Pointer<Char> pMessageId = messageId.toNativeUtf8().cast<Char>();
    int _reactionState = reactionState.index;
    Pointer<Char> _emoji = emoji.toNativeUtf8().cast<Char>();
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
    Pointer<Char> pConvoId = conversationId.toNativeUtf8().cast<Char>();
    Pointer<Char> pMessageId = messageId.toNativeUtf8().cast<Char>();
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

  reply(String conversationId, String messageId, List<String> messages) {
    // Parameter validation
    if (messages.isEmpty) {
      throw Exception("Message cannot be empty");
    }

    Pointer<Pointer<Char>> pMessages =
        calloc.allocate<Pointer<Char>>(messages.length);
    // Copy
    for (int i = 0; i < messages.length; i++) {
      pMessages[i] = messages[i].toNativeUtf8().cast<Char>();
    }
    // Invoke and result check
    G_FFIResult_Null result = bindings.raygun_reply(
        pRaygun,
        conversationId.toNativeUtf8().cast<Char>(),
        messageId.toNativeUtf8().cast<Char>(),
        pMessages,
        messages.length);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Release
    calloc.free(pMessages);
  }

  embed(String conversationId, String messageId, EmbedState embedState) {
    // Convert given values to native friendly types
    Pointer<Char> pConvoId = conversationId.toNativeUtf8().cast<Char>();
    Pointer<Char> pMessageId = messageId.toNativeUtf8().cast<Char>();
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

  drop() {
    bindings.raygunadapter_free(pRaygun);
  }
}
