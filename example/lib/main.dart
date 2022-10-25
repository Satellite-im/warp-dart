import 'dart:math';

import 'package:flutter/material.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/mp_ipfs.dart';

void main() {
  runApp(const MaterialApp(
    title: "Dart Wrapper Identity",
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

Tesseract? store;

Identity? identity;
MultiPass? multipass;

class Details extends StatelessWidget {
  const Details({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("First Route"),
      ),
      body: ListView(children: [
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Name: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    identity!.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "ShortId: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    identity!.short_id.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Status: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    identity!.status_message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Profile: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    identity!.graphics.profile_picture,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Banner: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    identity!.graphics.profile_banner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Outcomings: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    multipass!.listOutgoingRequest().toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Center(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Friends: ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    multipass!.listFriends().toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const Modify() /*ChangeName(id: id)*/));
          },
          icon: const Icon(
            // <-- Icon
            Icons.change_circle,
            size: 24.0,
          ),
          label: const Text('Modify'), // <-- Text
        ),
      ]),
    );
  }
}

class ChangeName extends StatelessWidget {
  ChangeName({
    Key? key,
  }) : super(key: key);

  final List<DropdownMenuItem<String>> listDrop = [];

  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Username"),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Insert New Username",
            style: TextStyle(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextField(
            controller: textEditingController,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
        ElevatedButton(
          child:
              const Text('Go to second screen', style: TextStyle(fontSize: 24)),
          onPressed: () {
            _sendDataToSecondScreen(context);
          },
        )
      ]),
    );
  }

  void _sendDataToSecondScreen(BuildContext context) {
    IdentityUpdate update =
        IdentityUpdate.setUsername(textEditingController.text);
    multipass!.updateIdentity(update);

    identity = multipass!.getOwnIdentity();

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Details()));
  }
}

class ChangeStatus extends StatelessWidget {
  ChangeStatus({
    Key? key,
  }) : super(key: key);

  final List<DropdownMenuItem<String>> listDrop = [];

  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Status"),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Insert New Status",
            style: TextStyle(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextField(
            controller: textEditingController,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
        ElevatedButton(
          child:
              const Text('Go to second screen', style: TextStyle(fontSize: 24)),
          onPressed: () {
            _sendDataToSecondScreen(context);
          },
        )
      ]),
    );
  }

  void _sendDataToSecondScreen(BuildContext context) {
    IdentityUpdate update =
        IdentityUpdate.setStatusMessage(textEditingController.text);
    multipass!.updateIdentity(update);
    identity = multipass!.getOwnIdentity();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Details()));
  }
}

class ChangeProfile extends StatelessWidget {
  ChangeProfile({
    Key? key,
  }) : super(key: key);

  final List<DropdownMenuItem<String>> listDrop = [];

  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Profile"),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Insert New Profile",
            style: TextStyle(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextField(
            controller: textEditingController,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
        ElevatedButton(
          child:
              const Text('Go to second screen', style: TextStyle(fontSize: 24)),
          onPressed: () {
            _sendDataToSecondScreen(context);
          },
        )
      ]),
    );
  }

  void _sendDataToSecondScreen(BuildContext context) {
    IdentityUpdate update =
        IdentityUpdate.setPicture(textEditingController.text);
    multipass!.updateIdentity(update);
    identity = multipass!.getOwnIdentity();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Details()));
  }
}

class ChangeBanner extends StatelessWidget {
  ChangeBanner({
    Key? key,
  }) : super(key: key);

  final List<DropdownMenuItem<String>> listDrop = [];

  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Profile"),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Insert New Banner",
            style: TextStyle(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextField(
            controller: textEditingController,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
        ElevatedButton(
          child:
              const Text('Go to second screen', style: TextStyle(fontSize: 24)),
          onPressed: () {
            _sendDataToSecondScreen(context);
          },
        )
      ]),
    );
  }

  void _sendDataToSecondScreen(BuildContext context) {
    IdentityUpdate update =
        IdentityUpdate.setBanner(textEditingController.text);
    multipass!.updateIdentity(update);
    identity = multipass!.getOwnIdentity();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Details()));
  }
}

class SendRequest extends StatelessWidget {
  SendRequest({
    Key? key,
  }) : super(key: key);

  final List<DropdownMenuItem<String>> listDrop = [];

  final TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Request"),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Insert DID for sending request",
            style: TextStyle(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: TextField(
            controller: textEditingController,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
        ElevatedButton(
          child:
              const Text('Go to second screen', style: TextStyle(fontSize: 24)),
          onPressed: () {
            _sendDataToSecondScreen(context);
          },
        )
      ]),
    );
  }

  void _sendDataToSecondScreen(BuildContext context) {
    multipass!.sendFriendRequest(textEditingController.text);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Details()));
  }
}

class _MyAppState extends State<MyApp> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    store = Tesseract.newStore();
    store!.unlock("Hello");

    multipass = multipass_ipfs_temporary(store!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Account")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              "Insert Username",
              style: TextStyle(fontSize: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: TextField(
              controller: textEditingController,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            child: const Text('Go to second screen',
                style: TextStyle(fontSize: 24)),
            onPressed: () {
              _sendDataToSecondScreen(context);
            },
          )
        ],
      ),
    );
  }

  void _sendDataToSecondScreen(BuildContext context) {
    try {
      multipass!.createIdentity(textEditingController.text, "");
    } on WarpException catch (e) {
      print(e);
    }

    identity = multipass!.getOwnIdentity();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Details()));
  }
}

class Modify extends StatelessWidget {
  const Modify({
    Key? key,
  }) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: Center(
          child: DropdownButton<String>(
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? newValue) {
              if (newValue == "Change Username") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChangeName()));
              }
              if (newValue == "Change Status") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChangeStatus()));
              }
              if (newValue == "Change Profile") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChangeProfile()));
              }
              if (newValue == "Change Banner") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChangeBanner()));
              }
              if (newValue == "Send Request") {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SendRequest()));
              }
              if (newValue == "Select Request") {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelectRequest()));
              }
            },
            items: <String>[
              'Change Username',
              'Change Status',
              'Change Profile',
              'Change Banner',
              'Send Request',
              'Select Request'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class SelectRequest extends StatelessWidget {
  const SelectRequest({
    Key? key,
  }) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    List<FriendRequest> list = multipass!.listIncomingRequest();
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: Center(
          child: DropdownButton<String>(
            isExpanded: true,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? newValue) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AcceptOrDenyRequest(did: newValue!)));
            },
            items: list.map<DropdownMenuItem<String>>((FriendRequest value) {
              return DropdownMenuItem<String>(
                value: value.to.toString(),
                child: Text(value.to.toString()),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class AcceptOrDenyRequest extends StatelessWidget {
  final String? did;
  const AcceptOrDenyRequest({
    Key? key,
    this.did,
  }) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    List<FriendRequest> list = multipass!.listIncomingRequest();
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: Center(
          child: DropdownButton<String>(
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? newValue) {
              if (newValue == "Accept Request") {
                multipass!.acceptFriendRequest(did!);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Details()));
              }
              if (newValue == "Deny Request") {
                multipass!.denyFriendRequest(did!);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Details()));
              }
            },
            items: <String>['Accept Request', 'Deny Request']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
