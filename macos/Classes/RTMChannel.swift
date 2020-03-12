import FlutterMacOS
import AgoraRtmKit

class RTMChannel: NSObject {
    public var channel: AgoraRtmChannel!

    static func create(_ clientIndex: Int, channelId: String, messenger: FlutterBinaryMessenger, kit: AgoraRtmKit) -> RTMChannel? {
        let rtmChannel = RTMChannel()
        guard let channel = kit.createChannel(withId: channelId, delegate: rtmChannel) else {
            return nil
        }
        rtmChannel.channel = channel
        return rtmChannel
    }
}

extension RTMChannel: AgoraRtmChannelDelegate {

}
