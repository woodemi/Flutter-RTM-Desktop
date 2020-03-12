class AgoraRtmMessage {
  String text;
  int ts;
  bool offline;

  AgoraRtmMessage(this.text, this.ts, this.offline);

  AgoraRtmMessage.fromText(String text) : text = text;

  AgoraRtmMessage.fromJson(Map<dynamic, dynamic> json)
      : text = json['text'],
        ts = json['ts'],
        offline = json['offline'];

  Map<String, dynamic> toJson() => {'text': text, 'ts': ts, 'offline': offline};

  @override
  String toString() {
    return "{text: $text, ts: $ts, offline: $offline}";
  }
}

class AgoraRtmMember {
  String userId;
  String channelId;

  AgoraRtmMember(this.userId, this.channelId);

  AgoraRtmMember.fromJson(Map<dynamic, dynamic> json)
      : userId = json['userId'],
        channelId = json['channelId'];

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'channelId': channelId,
      };

  @override
  String toString() {
    return "{uid: $userId, cid: $channelId}";
  }
}