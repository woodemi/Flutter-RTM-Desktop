#include "include/agora_rtm/agora_rtm_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>

#include "include/agora_rtm/RTMClient.h"

using namespace agora::rtm;

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

class AgoraRtmPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AgoraRtmPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~AgoraRtmPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar;

  long nextClientIndex{ 0 };
  std::map<long, RTMClient*> agoraClients{};

  void HandleStaticMethod(const std::string& method_name, EncodableMap& params,
      const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result);
  void HandleAgoraRtmClientMethod(const std::string& method_name, EncodableMap& params,
      const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result);
  void HandleAgoraRtmChannelMethod(const std::string& method_name, EncodableMap& params,
      const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result);
};

// static
void AgoraRtmPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "io.agora.rtm",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AgoraRtmPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AgoraRtmPlugin::AgoraRtmPlugin(flutter::PluginRegistrarWindows* registrar) : registrar(registrar) {}

AgoraRtmPlugin::~AgoraRtmPlugin() {
  for (auto clientPair : agoraClients)
    delete clientPair.second;
  agoraClients.clear();
}

void AgoraRtmPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto methodName = method_call.method_name();
  auto arguments = std::get<EncodableMap>(*method_call.arguments());
  auto callType = std::get<std::string>(arguments[EncodableValue("call")]);
  auto params = std::get<EncodableMap>(arguments[EncodableValue("params")]);

  if ("static" == callType)
    HandleStaticMethod(methodName, params, result);
  else if ("AgoraRtmClient" == callType)
    HandleAgoraRtmClientMethod(methodName, params, result);
  else if ("AgoraRtmChannel" == callType)
    HandleAgoraRtmChannelMethod(methodName, params, result);
  else
    result->NotImplemented();
}

void AgoraRtmPlugin::HandleStaticMethod(const std::string& method_name, EncodableMap& params,
    const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result)
{
  if ("createInstance" == method_name)
  {
    if (params.count(EncodableValue("appId")) == 0)
    {
      result->Success(EncodableMap{
        {"errorCode", -1},
      });
      return;
    }
    auto appId = std::get<std::string>(params[EncodableValue("appId")]);

    while (agoraClients.count(nextClientIndex) > 0)
      nextClientIndex++;

    auto rtmClient = new RTMClient(appId, nextClientIndex, registrar->messenger());
    result->Success(EncodableMap{
      {"errorCode", 0},
      {"index", nextClientIndex},
    });
    agoraClients[nextClientIndex] = rtmClient;
    nextClientIndex++;
  }
  else
    result->NotImplemented();
}

void AgoraRtmPlugin::HandleAgoraRtmClientMethod(const std::string& method_name, EncodableMap& params,
    const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result)
{
  auto clientIndex = std::get<int>(params[EncodableValue("clientIndex")]);
  auto args = params[EncodableValue("args")].IsNull() ? EncodableMap() : std::get<EncodableMap>(params[EncodableValue("args")]);

  if (agoraClients.count(clientIndex) == 0)
  {
    result->Success(EncodableMap{
      {"errorCode", -1},
    });
    return;
  }
  auto rtmClient = agoraClients[clientIndex];

  if ("login" == method_name)
  {
    auto token = args[EncodableValue("token")].IsNull() ? "" : std::get<std::string>(args[EncodableValue("token")]);
    auto userId = std::get<std::string>(args[EncodableValue("userId")]);
    auto errorCode = rtmClient->rtmService->login(token.c_str(), userId.c_str());
    result->Success(EncodableMap{
      {"errorCode", errorCode},
    });
  }
  else if ("logout" == method_name)
  {
    auto errorCode = rtmClient->rtmService->logout();
    result->Success(EncodableMap{
      {"errorCode", errorCode},
    });
  }
  else if ("createChannel" == method_name)
  {
    auto channelId = std::get<std::string>(args[EncodableValue("channelId")]);
    auto rtmChannel = new RTMChannel(clientIndex, channelId, registrar->messenger(), rtmClient->rtmService);
    if (rtmChannel == nullptr)
    {
      result->Success(EncodableMap{
        {"errorCode", -1},
      });
      return;
    }
    rtmClient->channels[channelId] = rtmChannel;
    result->Success(EncodableMap{
      {"errorCode", 0},
    });
  }
  else if ("releaseChannel" == method_name)
  {
    auto channelId = std::get<std::string>(args[EncodableValue("channelId")]);
    auto rtmChannel = rtmClient->channels[channelId];
    if (rtmChannel == nullptr)
    {
      result->Success(EncodableMap{
        {"errorCode", -1},
      });
      return;
    }
    delete rtmChannel;
    rtmClient->channels[channelId] = nullptr;
    result->Success(EncodableMap{
      {"errorCode", 0},
    });
  }
  else
    result->NotImplemented();
}

void AgoraRtmPlugin::HandleAgoraRtmChannelMethod(const std::string& method_name, EncodableMap& params,
    const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result)
{
  auto clientIndex = std::get<int>(params[EncodableValue("clientIndex")]);
  auto channelId = std::get<std::string>(params[EncodableValue("channelId")]);
  auto args = params[EncodableValue("args")].IsNull() ? EncodableMap() : std::get<EncodableMap>(params[EncodableValue("args")]);
  auto rtmClient = agoraClients[clientIndex];

  if (rtmClient->channels.count(channelId) == 0)
  {
    result->Success(EncodableMap{
      {"errorCode", -1},
    });
  }
  auto rtmChannel = rtmClient->channels[channelId];

  if ("join" == method_name)
  {
    auto errorCode = rtmChannel->channel->join();
    result->Success(EncodableMap{
      {"errorCode", errorCode},
    });
  }
  else if ("sendMessage" == method_name)
  {
    auto message = std::get<std::string>(args[EncodableValue("message")]);
    auto rtmMessage = rtmClient->rtmService->createMessage();
    rtmMessage->setText(message.c_str());
    auto errorCode = rtmChannel->channel->sendMessage(rtmMessage);
    rtmMessage->release();
    result->Success(EncodableMap{
      {"errorCode", errorCode},
    });
  }
  else if ("leave" == method_name)
  {
    auto errorCode = rtmChannel->channel->leave();
    result->Success(EncodableMap{
      {"errorCode", errorCode},
    });
  }
  else
    result->NotImplemented();
}

}  // namespace

void AgoraRtmPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  AgoraRtmPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
