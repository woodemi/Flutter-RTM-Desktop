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

  bool _closed;

  final int _clientIndex;

  AgoraRtmClient._(this._clientIndex) {
    _closed = false;
  }
}
