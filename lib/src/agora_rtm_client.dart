import 'dart:async';

import 'package:flutter/services.dart';

import 'agora_rtm_channel.dart';
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

  var _channels = <String, AgoraRtmChannel>{};

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

  Future<dynamic> _callNative(String methodName, dynamic arguments) {
    return AgoraRtmPlugin.callMethodForClient(
        methodName, {'clientIndex': _clientIndex, 'args': arguments});
  }

  /// Allows a user to log in the Agora RTM system.
  ///
  /// The string length of userId must be less than 64 bytes with the following character scope:
  /// - The 26 lowercase English letters: a to z
  /// - The 26 uppercase English letters: A to Z
  /// - The 10 numbers: 0 to 9
  /// - Space
  /// - "!", "#", "$", "%", "&", "(", ")", "+", "-", ":", ";", "<", "=", ".", ">", "?", "@", "]", "[", "^", "_", " {", "}", "|", "~", ","
  /// Do not set userId as null and do not start with a space.
  /// If you log in with the same user ID from a different instance, you will be kicked out of your previous login and removed from previously joined channels.
  Future login(String token, String userId) async {
    final res = await _callNative("login", {'token': token, 'userId': userId});
    if (res["errorCode"] != 0)
      throw AgoraRtmClientException(
          "login failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  /// Allows a user to log out of the Agora RTM system.
  Future logout() async {
    final res = await _callNative("logout", null);
    if (res["errorCode"] != 0)
      throw AgoraRtmClientException(
          "logout failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  /// Creates an [AgoraRtmChannel].
  ///
  /// channelId is the unique channel name of the Agora RTM session. The string length must not exceed 64 bytes with the following character scope:
  /// - The 26 lowercase English letters: a to z
  /// - The 26 uppercase English letters: A to Z
  /// - The 10 numbers: 0 to 9
  /// - Space
  /// - "!", "#", "$", "%", "&", "(", ")", "+", "-", ":", ";", "<", "=", ".", ">", "?", "@", "]", "[", "^", "_", " {", "}", "|", "~", ","
  /// channelId cannot be empty or set as nil.
  Future<AgoraRtmChannel> createChannel(String channelId) async {
    final res = await _callNative("createChannel", {'channelId': channelId});
    if (res['errorCode'] != 0)
      throw AgoraRtmClientException(
          "createChannel failed errorCode:${res['errorCode']}",
          res['errorCode']);
    AgoraRtmChannel channel = AgoraRtmChannel(_clientIndex, channelId);
    _channels[channelId] = channel;
    return _channels[channelId];
  }

  /// Releases an [AgoraRtmChannel].
  Future<void> releaseChannel(String channelId) async {
    final res = await _callNative("releaseChannel", {'channelId': channelId});
    if (res['errorCode'] != 0)
      throw AgoraRtmClientException(
          "releaseChannel failed errorCode:${res['errorCode']}",
          res['errorCode']);
    _channels[channelId]?.close();
    _channels.removeWhere((String channelId, AgoraRtmChannel channel) =>
        [channelId].contains(channel));
  }
}
