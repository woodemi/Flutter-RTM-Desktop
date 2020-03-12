import 'dart:async';

import 'package:flutter/services.dart';

import 'agora_rtm_plugin.dart';

class AgoraRtmClientException implements Exception {
  final reason;
  final code;

  AgoraRtmClientException(this.reason, this.code) : super();

  Map<String, dynamic> toJson() => {"reason": reason, "code": code};

  @override
  String toString() {
    return this.reason;
  }
}

class AgoraMessageHandler {
  final _messageController = StreamController<dynamic>();

  Stream get stream => _messageController.stream;

  Future<dynamic> handleMessage(dynamic message) async {
    _messageController.add(message);
  }
}

class AgoraRtmClient {
  static var _clients = <int, AgoraRtmClient>{};

  /// Initializes an [AgoraRtmClient] instance
  ///
  /// The Agora RTM SDK supports multiple [AgoraRtmClient] instances.
  static Future<AgoraRtmClient> createInstance(String appId) async {
    final res = await AgoraRtmPlugin.callMethodForStatic(
        "createInstance", {'appId': appId});
    if (res["errorCode"] != 0)
      throw AgoraRtmClientException(
          "Create client failed errorCode:${res['errorCode']}",
          res['errorCode']);
    final index = res['index'];
    AgoraRtmClient client = AgoraRtmClient._(index);
    _clients[index] = client;
    return _clients[index];
  }

  /// Occurs when the connection state between the SDK and the Agora RTM system changes.
  void Function(int state, int reason) onConnectionStateChanged;

  /// Occurs when you receive error events.
  void Function() onError;

  bool _closed;

  final int _clientIndex;
  StreamSubscription<dynamic> _clientSubscription;

  // FIXME Windows `EventChannel` not implemented yet
  Stream _createEventStream(int clientIndex) {
    var messageHandler = AgoraMessageHandler();
    BasicMessageChannel(
            'io.agora.rtm.client$clientIndex', StandardMessageCodec())
        .setMessageHandler(messageHandler.handleMessage);
    return messageHandler.stream;
  }

  _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'onConnectionStateChanged':
        int state = map['state'];
        int reason = map['reason'];
        this?.onConnectionStateChanged(state, reason);
        break;
    }
  }

  AgoraRtmClient._(this._clientIndex) {
    _closed = false;
    _clientSubscription = _createEventStream(_clientIndex)
        .listen(_eventListener, onError: onError);
  }
}
