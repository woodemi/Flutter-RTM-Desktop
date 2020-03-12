import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';

import 'AppId.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _infoStrings = <String>[];

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
          child: Column(
            children: [
              _buildInfoList(),
            ],
          ),
        ),
      ),
    );
  }

  void _createClient() async {
    _client = await AgoraRtmClient.createInstance(agoraAppId);
    _client.onConnectionStateChanged = (int state, int reason) {
      _log('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
    };
  }

  Widget _buildInfoList() {
    return Expanded(
        child: Container(
            child: ListView.builder(
      itemExtent: 24,
      itemBuilder: (context, i) {
        return ListTile(
          contentPadding: const EdgeInsets.all(0.0),
          title: Text(_infoStrings[i]),
        );
      },
      itemCount: _infoStrings.length,
    )));
  }

  void _log(String info) {
    print(info);
    setState(() {
      _infoStrings.insert(0, info);
    });
  }
}
