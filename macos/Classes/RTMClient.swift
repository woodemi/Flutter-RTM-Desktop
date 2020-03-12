import FlutterMacOS
import AgoraRtmKit

class RTMClient: NSObject {
    public var kit: AgoraRtmKit!

    static func create(appId: String, clientIndex: Int, messenger: FlutterBinaryMessenger) -> RTMClient? {
        let client = RTMClient()
        guard let kit = AgoraRtmKit(appId: appId, delegate: client) else {
            return nil
        }
        client.kit = kit
        return client
    }
}

// MARK: - AgoraRtmDelegate
extension RTMClient: AgoraRtmDelegate {

}
