import 'dart:async';

import 'package:flutter/services.dart';

class AgoraRtm {
  static const MethodChannel _channel = const MethodChannel('agora_rtm');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
