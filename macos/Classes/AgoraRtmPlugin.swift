import Cocoa
import FlutterMacOS
import AgoraRtmKit

public class AgoraRtmPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "io.agora.rtm", binaryMessenger: registrar.messenger)
    let instance = AgoraRtmPlugin()
    instance.methodChannel = channel
    instance.messenger = registrar.messenger
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  var methodChannel: FlutterMethodChannel!

  var nextClientIndex = 0
  var agoraClients = Dictionary<Int, RTMClient>()

  var messenger: FlutterBinaryMessenger!

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let methodName = call.method
    guard let arguments = call.arguments as? Dictionary<String, Any>,
          let callType = arguments["call"] as? String,
          let params = arguments["params"] as? Dictionary<String, Any> else {
      result(["errorCode": -2, "reason": FlutterMethodNotImplemented])
      return
    }

    switch callType {
    case "static":
      handleStaticMethod(methodName, params: params, result: result)
    case "AgoraRtmClient":
      handleAgoraRtmClientMethod(methodName, params: params, result: result)
    case "AgoraRtmChannel":
      handleAgoraRtmChannelMethod(methodName, params: params, result: result)
    default:
      result(["errorCode": -2, "reason": FlutterMethodNotImplemented])
    }
  }

  private func handleStaticMethod(_ name: String, params: [String: Any], result: @escaping FlutterResult) {
    switch name {
    case "createInstance":
      guard let appId = params["appId"] as? String else {
        result(["errorCode": -1])
        return
      }

      while (nil != agoraClients[nextClientIndex]) {
        nextClientIndex += 1
      }

      guard let rtmClient = RTMClient.create(appId: appId, clientIndex: nextClientIndex, messenger: messenger) else {
        result(["errorCode": -1])
        return
      }
      agoraClients[nextClientIndex] = rtmClient
      result(["errorCode": 0, "index": nextClientIndex])
      nextClientIndex += 1
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleAgoraRtmClientMethod(_ name: String, params: [String: Any], result: @escaping FlutterResult) {
    guard let clientIndex = params["clientIndex"] as? Int,
          let args = params["args"] as? Dictionary<String, Any>,
          let rtmClient = agoraClients[clientIndex] else {
      result(["errorCode": -1])
      return
    }

    switch name {
    case "login":
      let token = args["token"] as! String?
      let userId = args["userId"] as! String
      rtmClient.kit.login(byToken: token, user: userId) { errorCode in
        result(["errorCode": errorCode])
      }
    case "logout":
      rtmClient.kit.logout { errorCode in
        result(["errorCode": errorCode])
      }
    case "createChannel":
      let channelId = args["channelId"] as! String
      guard let rtmChannel = RTMChannel.create(clientIndex, channelId: channelId, messenger: messenger, kit: rtmClient.kit) else {
        result(["errorCode": -1])
        return
      }
      rtmClient.channels[channelId] = rtmChannel
      result(["errorCode": 0])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleAgoraRtmChannelMethod(_ name: String, params: [String: Any], result: @escaping FlutterResult) {
    guard let clientIndex = params["clientIndex"] as? Int,
          let channelId = params["channelId"] as? String,
          let args = params["args"] as? Dictionary<String, Any>,
          let rtmClient = agoraClients[clientIndex],
          let rtmChannel = rtmClient.channels[channelId] else {
      result(["errorCode": -1])
      return
    }

    switch name {
    case "join":
      rtmChannel.channel.join { errorCode in
        result(["errorCode": errorCode])
      }
    case "sendMessage":
      let message = args["message"] as! String
      rtmChannel.channel.send(AgoraRtmMessage(text: message)) { errorCode in
        result(["errorCode": errorCode])
      }
    case "leave":
      rtmChannel.channel.leave { errorCode in
        result(["errorCode": errorCode])
      }
    default:
      result(["errorCode": -2, "reason": FlutterMethodNotImplemented])
    }
  }
}