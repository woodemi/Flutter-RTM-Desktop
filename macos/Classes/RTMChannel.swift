import FlutterMacOS
import AgoraRtmKit

class RTMChannel: NSObject {
    public var channel: AgoraRtmChannel!

    private var messageChannel: FlutterBasicMessageChannel!

    static func create(_ clientIndex: Int, channelId: String, messenger: FlutterBinaryMessenger, kit: AgoraRtmKit) -> RTMChannel? {
        let rtmChannel = RTMChannel()
        let messageChannel = FlutterBasicMessageChannel(name: "io.agora.rtm.client\(clientIndex).channel\(channelId)", binaryMessenger: messenger)
        guard let channel = kit.createChannel(withId: channelId, delegate: rtmChannel) else {
            return nil
        }
        rtmChannel.channel = channel
        rtmChannel.messageChannel = messageChannel
        return rtmChannel
    }

    private func sendClientEvent(_ name: String, params: Dictionary<String, Any>) {
        var p = params
        p["event"] = name
        messageChannel.sendMessage(p)
    }
}

extension RTMChannel: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        sendClientEvent("onMessageReceived", params: [
            "userId": member.userId,
            "channelId": member.channelId,
            "message": [
                "text": message.text,
                "ts": message.serverReceivedTs,
                "offline": message.isOfflineMessage,
            ],
        ])
    }
}
