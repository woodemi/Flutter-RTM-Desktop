#pragma once
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>

#include "IAgoraRtmService.h"
#include "RTMChannel.h"

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

		std::map<std::string, RTMChannel*> channels{};

#pragma region IRtmServiceEventHandler
		void onConnectionStateChanged(CONNECTION_STATE state, CONNECTION_CHANGE_REASON reason) override;
#pragma endregion

	private:
		std::unique_ptr<flutter::BasicMessageChannel<EncodableValue>> messageChannel;

		void SendClientEvent(std::string name, EncodableMap params)
		{
			params[EncodableValue("event")] = name;
			messageChannel->Send(EncodableValue(params));
		}
	};
}
