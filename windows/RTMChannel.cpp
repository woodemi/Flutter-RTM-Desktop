#include "RTMChannel.h"

#include <flutter/standard_message_codec.h>

namespace agora::rtm
{
	RTMChannel::RTMChannel(long client_index, const std::string& channel_id, flutter::BinaryMessenger* messenger, IRtmService* rtm_service)
	{
		messageChannel = std::make_unique<flutter::BasicMessageChannel<flutter::EncodableValue>>(
			messenger,
			"io.agora.rtm.client" + std::to_string(client_index) + ".channel" + channel_id,
			&flutter::StandardMessageCodec::GetInstance());

		channel = rtm_service->createChannel(channel_id.c_str(), this);
	}

	RTMChannel::~RTMChannel()
	{
		if (channel != nullptr)
			channel->release();
		channel = nullptr;
	}

	void RTMChannel::onMessageReceived(const char* userId, const IMessage* message)
	{
		SendChannelEvent("onMessageReceived", EncodableMap{
			{EncodableValue("userId"), EncodableValue(userId)},
			{EncodableValue("channelId"), EncodableValue(channel->getId())},
			{EncodableValue("message"), EncodableValue(EncodableMap{
				{EncodableValue("text"), EncodableValue(message->getText())},
				{EncodableValue("ts"), EncodableValue(message->getServerReceivedTs())},
				{EncodableValue("offline"), EncodableValue(message->isOfflineMessage())},
			})},
		});
	}
}
