#pragma once
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>

#include "IAgoraRtmService.h"

namespace agora::rtm
{
	using flutter::EncodableValue;
	using flutter::EncodableMap;

	class RTMClient : IRtmServiceEventHandler
	{
	public:
		RTMClient(const std::string& app_id, long client_index, flutter::BinaryMessenger* messenger);

		virtual ~RTMClient();

		IRtmService* rtmService;
	};
}
