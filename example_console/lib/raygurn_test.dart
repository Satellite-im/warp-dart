import 'package:example_console/common.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/raygun.dart';
import 'dart:io';

void test_rg_ipfs() {
  try {
    print("==== Test for rg_ipfs ====");

    print("New accounts");
    MultiPass accountA = newAccount("/tmp/warp-dart-a", "warp-dart-a", "warp");
    MultiPass accountB = newAccount("/tmp/warp-dart-b", "warp-dart-b", "warp");

    print("Get own identity");
    Identity idA = accountA.getOwnIdentity();
    Identity idB = accountB.getOwnIdentity();

    print("New chats");
    Raygun rgA = newChat(accountA, "/tmp/warp-dart-a");
    Raygun rgB = newChat(accountB, "/tmp/warp-dart-b");

    sleep(Duration(seconds: 1));

    List<Conversation> conversations = rgA.listConversation();
    print("Create conversation");
    DID didB = idB.did_key;
    String didBString = didB.toString();
    print(didBString);
    late Conversation convo;
    if (conversations.isEmpty) {
      convo = rgA.createConversation(didBString);
    } else {
      convo = conversations.elementAt(0);
    }

    print("");

    print("Send messages via account A");
    List<String> chatMessagesA = [];
    chatMessagesA.add("Hello, World!!");
    chatMessagesA.add("How are you??");
    chatMessagesA.add("Has your day been good???");
    chatMessagesA.add("Mine is great");
    chatMessagesA.add("You there????");
    chatMessagesA.add("Just tired from dealing with C :D");
    chatMessagesA.add("Rust rules!!!");
    rgA.send(convo.id, chatMessagesA);
    sleep(Duration(seconds: 1));

    print("Get messages via account B");
    List<Message> messages = rgB.getMessages(convo.id);
    print(convo.id);
    for (var msg in messages) {
      Identity id = accountB.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print(id.username + " - $line");
      }
    }
    sleep(Duration(seconds: 1));

    print("");

    print("Send messages via account B");
    List<String> chatMessagesB = [];
    chatMessagesB.add("Hello from Chatter A :D");
    chatMessagesB.add("I've grown tired of C");
    chatMessagesB.add("Rust is life");
    chatMessagesB.add("Sooooooooooo tired");
    chatMessagesB.add(
        "Dreamed of being within a dream and waking up from that dream while in a dream :D");

    rgB.send(convo.id, chatMessagesB);
    sleep(Duration(seconds: 1));

    print("Get messages via account A");
    List<Message> messages2 = rgA.getMessages(convo.id);
    print(convo.id);
    for (var msg in messages2) {
      Identity id = accountA.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print("${id.username} - $line");
      }
    }
    sleep(Duration(seconds: 1));

    print("Edit first Message");
    chatMessagesB[0] = "hello";
    chatMessagesB[1] = "hi";
    rgB.edit(convo.id, messages2[0].id, chatMessagesB);
    sleep(Duration(seconds: 1));

    print("Get messages via account A after change");
    List<Message> messages3 = rgA.getMessages(convo.id);
    for (var msg in messages3) {
      Identity id = accountA.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print("${id.username} - $line");
      }
    }

    print("Delete first Message");
    rgB.delete(convo.id, messages2[0].id);
    sleep(Duration(seconds: 1));

    print("Get messages via account A after deleting");
    List<Message> messages4 = rgA.getMessages(convo.id);
    for (var msg in messages4) {
      Identity id = accountA.getIdentityByDID(msg.sender.toString());
      for (var line in msg.value) {
        print("${id.username} - $line");
      }
    }

    print("React to a Message");
    rgB.react(convo.id, messages2[0].id, ReactionState.add, "happy");
    sleep(Duration(seconds: 1));

    print("Get reaction of message from account A");
    List<Message> messages5 = rgA.getMessages(convo.id);
    if (messages5[0].reactions.isNotEmpty) {
      for (var reaction in messages5[0].reactions) {
        print("Emoji: ${reaction.emoji}");
        /*print("Senders:");
        for (var sender in reaction.sender) {
          print(sender.toString());
        }*/
      }
    } else {
      print("No reactions");
    }

    print("Remove Reaction to a Message");
    rgB.react(convo.id, messages2[0].id, ReactionState.remove, "happy");
    sleep(Duration(seconds: 1));

    print("Get reactions of message from account A");
    List<Message> messages6 = rgA.getMessages(convo.id);
    if (messages6[0].reactions.isNotEmpty) {
      for (var reaction in messages6[0].reactions) {
        print("Emoji: ${reaction.emoji}");
        /*print("Senders:");
        for (var sender in reaction.sender) {
          print(sender.toString());
        }*/
      }
    } else {
      print("No reactions");
    }

    print("Pin a Message");
    rgB.pin(convo.id, messages2[0].id, PinState.pin);
    sleep(Duration(seconds: 1));

    print("Verify if message is pinned");
    List<Message> messages7 = rgA.getMessages(convo.id);
    print("Pinned? ${messages7[0].pinned}");

    print("Unpin a Message");
    rgB.pin(convo.id, messages2[0].id, PinState.unpin);
    sleep(Duration(seconds: 1));

    print("Verify if message is pinned");
    List<Message> messages8 = rgA.getMessages(convo.id);
    print("Pinned? ${messages8[0].pinned}");

    print("Reply a Message");
    rgB.reply(convo.id, messages2[0].id, ["HI"]);
    sleep(Duration(seconds: 1));

    print("Get Reply");
    List<Message> messages9 = rgA.getMessages(convo.id);
    print("Reply:  ${messages9[1].replied}");

    /*print("Embed a Message");
    rgB.embed(convo.id, messages2[0].id, EmbedState.enabled);
    sleep(Duration(seconds: 1));

    print("Get Reply");
    List<Message> messages10 = rgA.getMessages(convo.id);
    print("Reply:  ${messages10[0]}");*/
  } on WarpException catch (e) {
    print(e.errorMessage());
  }
}
