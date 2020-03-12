import 'dart:async';

import 'agora_rtm_plugin.dart';

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
  final String channelId;
  final int _clientIndex;

  bool _closed;

  StreamSubscription<dynamic> _eventSubscription;

  AgoraRtmChannel(this._clientIndex, this.channelId) {
    _closed = false;
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

  Future<void> leave() async {
    final res = await _callNative("leave", null);
    if (res["errorCode"] != 0)
      throw AgoraRtmChannelException(
          "leave failed errorCode:${res['errorCode']}", res['errorCode']);
  }

  Future<void> close() async {
    if (_closed) return null;
    await _eventSubscription.cancel();
    _closed = true;
  }
}
