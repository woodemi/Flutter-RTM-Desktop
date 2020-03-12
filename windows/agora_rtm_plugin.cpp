// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include "agora_rtm_plugin.h"

// This must be included before VersionHelpers.h.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>

#include "RTMClient.h"

using namespace agora::rtm;

namespace {
    using flutter::EncodableMap;
    using flutter::EncodableValue;

    class AgoraRtmPlugin : public flutter::Plugin
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

        AgoraRtmPlugin(flutter::PluginRegistrarWindows* registrar);

        virtual ~AgoraRtmPlugin();

    private:
        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue>& method_call,
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
        flutter::PluginRegistrarWindows* registrar)
    {
        auto plugin = std::make_unique<AgoraRtmPlugin>(registrar);

        auto channel =
            std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "io.agora.rtm",
                &flutter::StandardMethodCodec::GetInstance());

        channel->SetMethodCallHandler(
            [plugin_pointer = plugin.get()](const auto& call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

        registrar->AddPlugin(std::move(plugin));
    }

    AgoraRtmPlugin::AgoraRtmPlugin(flutter::PluginRegistrarWindows* registrar) : registrar(registrar) {}

    AgoraRtmPlugin::~AgoraRtmPlugin()
    {
        for (auto clientPair : agoraClients)
            delete clientPair.second;
        agoraClients.clear();
    }

    void AgoraRtmPlugin::HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        auto methodName = method_call.method_name();
        auto arguments = method_call.arguments()->MapValue();
        auto callType = arguments[EncodableValue("call")].StringValue();
        auto params = arguments[EncodableValue("params")].MapValue();

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
	            auto ret = EncodableValue(EncodableMap{
		            {EncodableValue("errorCode"), EncodableValue(-1)},
	            });
                result->Success(&ret);
                return;
            }
            auto appId = params[EncodableValue("appId")].StringValue();

            while (agoraClients.count(nextClientIndex) > 0)
                nextClientIndex++;

            auto rtmClient = new RTMClient(appId, nextClientIndex, registrar->messenger());
            auto ret = EncodableValue(EncodableMap{
	            {EncodableValue("errorCode"), EncodableValue(0)},
	            {EncodableValue("index"), EncodableValue(nextClientIndex)},
            });
            result->Success(&ret);
            agoraClients[nextClientIndex] = rtmClient;
            nextClientIndex++;
        }
        else
            result->NotImplemented();
    }

    void AgoraRtmPlugin::HandleAgoraRtmClientMethod(const std::string& method_name, EncodableMap& params,
        const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result)
    {
        auto clientIndex = params[EncodableValue("clientIndex")].IntValue();
        auto args = params[EncodableValue("args")].MapValue();

        if (agoraClients.count(clientIndex) == 0)
        {
	        auto ret = EncodableValue(EncodableMap{
		        {EncodableValue("errorCode"), EncodableValue(-1)},
	        });
            result->Success(&ret);
            return;
        }
        auto rtmClient = agoraClients[clientIndex];

        if ("login" == method_name)
        {
            auto token = args.count(EncodableValue("token")) > 0 ? args[EncodableValue("token")].StringValue() : "";
            auto userId = args[EncodableValue("userId")].StringValue();
            auto errorCode = rtmClient->rtmService->login(token.c_str(), userId.c_str());
            auto ret = EncodableValue(EncodableMap{
	            {EncodableValue("errorCode"), EncodableValue(errorCode)},
            });
            result->Success(&ret);
        }
        else if ("logout" == method_name)
        {
	        auto errorCode = rtmClient->rtmService->logout();
	        auto ret = EncodableValue(EncodableMap{
		        {EncodableValue("errorCode"), EncodableValue(errorCode)},
	        });
            result->Success(&ret);
        }
        else
            result->NotImplemented();
    }

    void AgoraRtmPlugin::HandleAgoraRtmChannelMethod(const std::string& method_name, EncodableMap& params,
        const std::unique_ptr<flutter::MethodResult<EncodableValue>>& result)
    {
        auto clientIndex = params[EncodableValue("clientIndex")].IntValue();
        auto channelId = params[EncodableValue("channelId")].StringValue();
        auto args = params[EncodableValue("args")].MapValue();
        auto rtmClient = agoraClients[clientIndex];

        if (rtmClient->channels.count(channelId) == 0)
        {
	        auto ret = EncodableValue(EncodableMap{
		        {EncodableValue("errorCode"), EncodableValue(-1)},
	        });
            result->Success(&ret);
        }
        auto rtmChannel = rtmClient->channels[channelId];

        if ("join" == method_name)
        {
	        auto errorCode = rtmChannel->channel->join();
            auto ret = EncodableValue(EncodableMap{
                {EncodableValue("errorCode"), EncodableValue(errorCode)},
            });
            result->Success(&ret);
        }
        else if ("sendMessage" == method_name)
        {
            auto message = args[EncodableValue("message")].StringValue();
            auto rtmMessage = rtmClient->rtmService->createMessage();
            rtmMessage->setText(message.c_str());
            auto errorCode = rtmChannel->channel->sendMessage(rtmMessage);
            rtmMessage->release();
            auto ret = EncodableValue(EncodableMap{
                {EncodableValue("errorCode"), EncodableValue(errorCode)},
            });
            result->Success(&ret);
        }
        else if ("leave" == method_name)
        {
	        auto errorCode = rtmChannel->channel->leave();
            auto ret = EncodableValue(EncodableMap{
                {EncodableValue("errorCode"), EncodableValue(errorCode)},
            });
            result->Success(&ret);
        }
        else
            result->NotImplemented();
    }
}  // namespace

void AgoraRtmPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    // The plugin registrar wrappers owns the plugins, registered callbacks, etc.,
    // so must remain valid for the life of the application.
    static auto* plugin_registrars =
        new std::map<FlutterDesktopPluginRegistrarRef,
        std::unique_ptr<flutter::PluginRegistrarWindows>>;
    auto insert_result = plugin_registrars->emplace(
        registrar, std::make_unique<flutter::PluginRegistrarWindows>(registrar));

    AgoraRtmPlugin::RegisterWithRegistrar(insert_result.first->second.get());
}
