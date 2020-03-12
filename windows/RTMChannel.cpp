#include "RTMChannel.h"

#include <flutter/standard_message_codec.h>

namespace agora::rtm
{
	RTMChannel::RTMChannel(long client_index, const std::string& channel_id, flutter::BinaryMessenger* messenger, IRtmService* rtm_service)
	{
		channel = rtm_service->createChannel(channel_id.c_str(), this);
	}

	RTMChannel::~RTMChannel()
	{
		if (channel != nullptr)
			channel->release();
		channel = nullptr;
	}
}
