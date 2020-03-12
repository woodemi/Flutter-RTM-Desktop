import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';

import 'AppId.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AgoraRtmClient _client;

  @override
  void initState() {
    super.initState();
    _createClient();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora Real Time Message'),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('TODO'),
          ),
        ),
      ),
    );
  }

  void _createClient() async {
    _client = await AgoraRtmClient.createInstance(agoraAppId);
  }
}
