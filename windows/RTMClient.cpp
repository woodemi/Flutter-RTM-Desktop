#include "RTMClient.h"

#include <flutter/standard_message_codec.h>

namespace agora::rtm
{
	RTMClient::RTMClient(const std::string& app_id, long client_index, flutter::BinaryMessenger* messenger)
	{
		messageChannel = std::make_unique<flutter::BasicMessageChannel<EncodableValue>>(
			messenger,
			"io.agora.rtm.client" + std::to_string(client_index),
			&flutter::StandardMessageCodec::GetInstance());

		rtmService = createRtmService();
		rtmService->initialize(app_id.c_str(), this);
	}

	RTMClient::~RTMClient()
	{
		for (auto channelPair : channels)
			delete channelPair.second;
		channels.clear();

		rtmService->release();
	}

#pragma region IRtmServiceEventHandler
	void RTMClient::onConnectionStateChanged(CONNECTION_STATE state, CONNECTION_CHANGE_REASON reason)
	{
		SendClientEvent("onConnectionStateChanged", EncodableMap{
			{EncodableValue("state"), EncodableValue(state)},
			{EncodableValue("reason"), EncodableValue(reason)},
		});
	}
#pragma endregion
}
