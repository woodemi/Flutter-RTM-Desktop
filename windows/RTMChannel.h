#pragma once
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>

#include "IAgoraRtmService.h"

namespace agora::rtm
{
	using flutter::EncodableValue;
	using flutter::EncodableMap;

	class RTMChannel : IChannelEventHandler
	{
	public:
		RTMChannel(long client_index, const std::string& channel_id, flutter::BinaryMessenger* messenger, IRtmService* rtm_service);

		virtual ~RTMChannel();

		IChannel* channel;

#pragma region IRtmServiceEventHandler
		void onMemberJoined(IChannelMember* member) override;
		void onMemberLeft(IChannelMember* member) override;
		void onMessageReceived(const char* userId, const IMessage* message) override;
#pragma endregion

	private:
		std::unique_ptr<flutter::BasicMessageChannel<EncodableValue>> messageChannel;

		void SendChannelEvent(std::string name, EncodableMap params)
		{
			params[EncodableValue("event")] = name;
			messageChannel->Send(EncodableValue(params));
		}
	};
}
