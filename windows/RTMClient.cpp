#include "RTMClient.h"

namespace agora::rtm
{
	RTMClient::RTMClient(const std::string& app_id, long client_index, flutter::BinaryMessenger* messenger)
	{
		rtmService = createRtmService();
		rtmService->initialize(app_id.c_str(), this);
	}

	RTMClient::~RTMClient()
	{
		rtmService->release();
	}
}
