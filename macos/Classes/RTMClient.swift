import FlutterMacOS
import FlutterMacOS
import AgoraRtmKit

class RTMClient: NSObject {
    public var kit: AgoraRtmKit!

    public var channels = Dictionary<String, RTMChannel>()

    private var messageChannel: FlutterBasicMessageChannel!

    static func create(appId: String, clientIndex: Int, messenger: FlutterBinaryMessenger) -> RTMClient? {
        let client = RTMClient()
        let messageChannel = FlutterBasicMessageChannel(name: "io.agora.rtm.client\(clientIndex)", binaryMessenger: messenger)
        guard let kit = AgoraRtmKit(appId: appId, delegate: client) else {
            return nil
        }
        client.kit = kit
        client.messageChannel = messageChannel
        return client
    }

    private func sendClientEvent(_ name: String, params: Dictionary<String, Any>) {
        var p = params
        p["event"] = name
        messageChannel.sendMessage(p)
    }
}

// MARK: - AgoraRtmDelegate
extension RTMClient: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        sendClientEvent("onConnectionStateChanged", params: ["state": state, "reason": reason])
    }
}
