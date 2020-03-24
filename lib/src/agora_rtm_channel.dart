import 'dart:async';

import 'package:flutter/services.dart';

import 'agora_rtm_plugin.dart';
import 'utils.dart';

class AgoraRtmChannelException implements Exception {
  final reason;
  final code;

  AgoraRtmChannelException(this.reason, this.code) : super();

  Map<String, dynamic> toJson() => {"reason": reason, "code": code};

  @override
  String toString() {
    return this.reason;
  }
}

class AgoraRtmChannel {
  /// Occurs when you receive error events.
  void Function(dynamic error) onError;

  /// Occurs when receiving a channel message.
  void Function(AgoraRtmMessage message, AgoraRtmMember fromMember)
      onMessageReceived;

  /// Occurs when a user joins the channel.
  void Function(AgoraRtmMember member) onMemberJoined;

  /// Occurs when a channel member leaves the channel.
  void Function(AgoraRtmMember member) onMemberLeft;

  final String channelId;
  final int _clientIndex;

  bool _closed;

  BasicMessageChannel messageChannel;

  _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'onMessageReceived':
        AgoraRtmMessage message = AgoraRtmMessage.fromJson(map['message']);
        AgoraRtmMember member = AgoraRtmMember.fromJson(map);
        this?.onMessageReceived(message, member);
        break;
      case 'onMemberJoined':
        AgoraRtmMember member = AgoraRtmMember.fromJson(map);
        this?.onMemberJoined(member);
        break;
      case 'onMemberLeft':
        AgoraRtmMember member = AgoraRtmMember.fromJson(map);
        this?.onMemberLeft(member);
    }
  }

  AgoraRtmChannel(this._clientIndex, this.channelId) {
    _closed = false;
    messageChannel = new BasicMessageChannel(
        'io.agora.rtm.client$_clientIndex.channel$channelId',
        StandardMessageCodec());
    messageChannel.setMessageHandler(_eventListener);
  }

  Future<dynamic> _callNative(String methodName, dynamic arguments) {
    return AgoraRtmPlugin.callMethodForChannel(methodName, {
      'clientIndex': _clientIndex,
      'channelId': channelId,
      'args': arguments
    });
  }

  Future<void> join() async {
    final res = await _callNative("join", null);
    if (res["errorCode"] != 0)
      throw AgoraRtmChannelException(
          "join failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<void> sendMessage(AgoraRtmMessage message) async {
    final res = await _callNative("sendMessage", {'message': message.text});
    if (res["errorCode"] != 0)
      throw AgoraRtmChannelException(
          "sendMessage failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<void> leave() async {
    final res = await _callNative("leave", null);
    if (res["errorCode"] != 0)
      throw AgoraRtmChannelException(
          "leave failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<void> close() async {
    if (_closed) return null;
    messageChannel.setMessageHandler(null);
    _closed = true;
  }
}
