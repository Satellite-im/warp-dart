import 'dart:ffi';
import 'package:ffi/ffi.dart';
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

class DateRange {
  DateTime start;
  DateTime end;
  DateRange(this.start, this.end);
}

class Range {
  int start;
  int end;
  Range(this.start, this.end);
}

class MessageOptions {
  Range? range;
  DateRange? dateRange;
  MessageOptions(this.range, this.dateRange);

  setRange(int start, int end) {
    range = Range(start, end);
  }

  setDateRange(DateTime start, DateTime end) {
    dateRange = DateRange(start, end);
  }

  Pointer<G_MessageOptions> toPointer() {
    Pointer<G_MessageOptions> optPtr = bindings.messageoptions_new();
    if (range != null) {
      optPtr =
          bindings.messageoptions_set_range(optPtr, range!.start, range!.end);
    }

    if (dateRange != null) {
      optPtr = bindings.messageoptions_set_date_range(
          optPtr,
          dateRange!.start.microsecondsSinceEpoch,
          dateRange!.end.microsecondsSinceEpoch);
    }

    return optPtr;
  }
}

class Message {
  late String id;
  late String conversationId;
  late String sender;
  late DateTime date;
  bool pinned = false;
  List<Reaction> reactions = [];
  String? replied;
  late List<String> value;
  Map<String, String>? metadata;
  Message(Pointer<G_Message> pointer) {
    Pointer<Char> pId = bindings.message_id(pointer);
    id = pId.cast<Utf8>().toDartString();

    Pointer<Char> pConversationId = bindings.message_conversation_id(pointer);
    conversationId = pConversationId.cast<Utf8>().toDartString();

    Pointer<G_DID> pSender = bindings.message_sender(pointer);
    DID iSender = DID(pSender);
    sender = iSender.toString();

    Pointer<Char> pDate = bindings.message_date(pointer);

    // Rust Chrono uses "UTC" while in dart, UTC is identified by "Z"
    String rawDate = pDate.cast<Utf8>().toDartString().replaceAll(" UTC", 'Z');

    date = DateTime.parse(rawDate);

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
    List<String> mList = [];
    for (int j = 0; j < lineLen; j++) {
      Pointer<Char> line = pLines.ref.ptr.elementAt(j).value;
      mList.add(line.cast<Utf8>().toDartString());
    }

    value = mList;

    calloc.free(pDate);
    calloc.free(pId);
    calloc.free(pConversationId);
    iSender.drop();
    bindings.ffivec_string_free(pLines);
    calloc.free(pReplied);
    bindings.ffivec_reaction_free(pReactions);
    bindings.message_free(pointer);
  }
}

class Reaction {
  late String emoji;
  late List<String> sender;
  Reaction(Pointer<G_Reaction> pointer) {
    Pointer<Char> pEmoji = bindings.reaction_emoji(pointer);
    emoji = pEmoji.cast<Utf8>().toDartString();
    Pointer<G_FFIVec_DID> pReactionSenders = bindings.reaction_users(pointer);

    int reactionSendersIdLen = pReactionSenders.ref.len;
    for (int k = 0; k < reactionSendersIdLen; k++) {
      Pointer<G_DID> pSenderId = pReactionSenders.ref.ptr.elementAt(k).value;
      DID did = DID(pSenderId);
      sender.add(did.toString());
      did.drop();
      // calloc.free(pSenderId);
    }
    calloc.free(pEmoji);
  }
}

class Conversation {
  late String id;
  late ConversationType type;
  String? name;
  late List<String> recipients;
  Conversation(Pointer<G_Conversation> pointer) {
    Pointer<Char> pId = bindings.conversation_id(pointer);
    id = pId.cast<Utf8>().toDartString();
    Pointer<Char> pName = bindings.conversation_name(pointer);
    name = pName != nullptr ? pName.cast<Utf8>().toDartString() : null;
    //TODO: Investigate right conversion conversation
    //type = bindings.conversation_type(pointer) as ConversationType;
    //type = ConversationType.Direct as ConversationType; //?
    Pointer<G_FFIVec_DID> pDIDs = bindings.conversation_recipients(pointer);
    int len = pDIDs.ref.len;
    List<String> rList = [];
    for (int i = 0; i < len; i++) {
      DID did = DID(pDIDs.ref.ptr[i]);
      rList.add(did.toString());
      did.drop();
    }

    recipients = rList;

    bindings.conversation_free(pointer);
  }
}

class Raygun {
  Pointer<G_RayGunAdapter> pRaygun;
  Raygun(this.pRaygun);

  Conversation createConversation(String didKey) {
    // Prepare a DID
    DID did;

    try {
      did = DID.fromString(didKey);
    } on WarpException {
      rethrow;
    }

    // Invoke and result check
    G_FFIResult_Conversation result =
        bindings.raygun_create_conversation(pRaygun, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    Conversation convoId = Conversation(result.data);

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
    }

    return conversations;
  }

  List<Message> getMessages(String conversationID, [MessageOptions? options]) {
    Pointer<G_MessageOptions> optPtr =
        options != null ? options.toPointer() : nullptr;

    G_FFIResult_FFIVec_Message result = bindings.raygun_get_messages(
        pRaygun, conversationID.toNativeUtf8().cast<Char>(), optPtr);

    // Because we no longer need the pointer, it would be better off freeing early
    // in the event of an error
    if (optPtr != nullptr) {
      calloc.free(optPtr);
    }

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Iterate over the messages
    List<Message> msgs = [];
    int length = result.data.ref.len;
    for (int i = 0; i < length; i++) {
      msgs.add(Message(result.data.ref.ptr.elementAt(i).value));
    }
    return msgs;
  }

  Message getMessage(String conversationID, String messageId) {
    G_FFIResult_Message result = bindings.raygun_get_message(
        pRaygun,
        conversationID.toNativeUtf8().cast<Char>(),
        messageId.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    // Iterate over the messages

    return Message(result.data);
  }

  send(String conversationId, List<String> messages) {
    if (messages.isEmpty) {
      throw Exception("Message cannot be empty");
    }

    List<Pointer<Char>> pointerList =
        messages.map((str) => str.toNativeUtf8().cast<Char>()).toList();

    final Pointer<Pointer<Char>> pMessages = malloc
        .allocate<Pointer<Char>>(sizeOf<Pointer<Utf8>>() * pointerList.length);

    messages.asMap().forEach((index, utf) {
      pMessages[index] = pointerList[index];
    });

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
    malloc.free(pMessages);
  }

  edit(String conversationId, String messageId, List<String> messages) {
    if (messages.isEmpty) {
      throw Exception("Message cannot be empty");
    }

    List<Pointer<Char>> pointerList =
        messages.map((str) => str.toNativeUtf8().cast<Char>()).toList();

    final Pointer<Pointer<Char>> pMessages = malloc
        .allocate<Pointer<Char>>(sizeOf<Pointer<Utf8>>() * pointerList.length);

    messages.asMap().forEach((index, utf) {
      pMessages[index] = pointerList[index];
    });

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
    malloc.free(pMessages);
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

    List<Pointer<Char>> pointerList =
        messages.map((str) => str.toNativeUtf8().cast<Char>()).toList();

    final Pointer<Pointer<Char>> pMessages = malloc
        .allocate<Pointer<Char>>(sizeOf<Pointer<Utf8>>() * pointerList.length);

    messages.asMap().forEach((index, utf) {
      pMessages[index] = pointerList[index];
    });

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
