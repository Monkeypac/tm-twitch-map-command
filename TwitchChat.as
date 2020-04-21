#include "IRC.as"

/*
Usage:
1. Include this script from your own script.
2. Define and instantiate a class that implements the Twitch::ICallbacks interface below.
3. Call Twitch::Connect(callbacks), where callbacks is an instance of your callbacks class.
4. Call Twitch::Login(token, nickname, channel), where:
   - `token` is an OAuth token. You can generate one here: https://twitchapps.com/tmi/
   - `nickname` is the username of your (bot) account, all lowercase.
   - `channel` is the channel to join, all lowercase and starting with the # sign. For example, "#missterious".
5. Yield an infinite loop in your Main() function where you call Twitch::Update(). For example, `while (true) { Twitch::Update(); yield(); }`
6. Call Twitch::SendMessage(message) to send a chat message to the channel.

For a complete example usage, see Plugin_TwitchChat.as.

Also, refer to the Twitch IRC documentation for more info on the many available IRC tags.
*/

namespace Twitch
{
	interface ICallbacks
	{
		void OnMessage(IRC::Message@ msg);
		void OnUserNotice(IRC::Message@ msg);
	}

	Net::Socket@ g_client;
	ICallbacks@ g_callbacks;
	string g_inChannel;

	void Disconnect()
	{
		if (g_client is null) {
			return;
		}

		g_client.Close();
		@g_client = null;
	}

	bool Connect(ICallbacks@ callbacks)
	{
		if (g_client !is null) {
			Disconnect();
		}

		@g_client = Net::Socket();
		if (!g_client.Connect("irc.chat.twitch.tv", 6667)) {
			print("Couldn't connect to Twitch IRC server!");
			return false;
		}

		@g_callbacks = callbacks;

		while (!g_client.CanWrite()) {
			yield();
		}

		return true;
	}

	void Login(const string &in token, const string &in nickname, const string &in channel)
	{
		g_inChannel = channel;

		g_client.WriteRaw("PASS " + token + "\n");
		g_client.WriteRaw("NICK " + nickname + "\n");
		g_client.WriteRaw("JOIN " + channel + "\n");
		g_client.WriteRaw("CAP REQ :twitch.tv/tags\n");
	}

	void SendMessage(const string &in msg)
	{
		if (g_client is null) {
			return;
		}

		g_client.WriteRaw("PRIVMSG " + g_inChannel + " :" + msg + "\n"))
	}

	void Update()
	{
		if (g_client is null || g_client.Available() == 0) {
			return;
		}

		string line;
		if (g_client.ReadLine(line)) {
			line = line.Trim();

			auto msg = IRC::Message(line);
			if (msg.m_command == "PRIVMSG") {
				g_callbacks.OnMessage(msg);
			} else if (msg.m_command == "USERNOTICE") {
				g_callbacks.OnUserNotice(msg);
			} else if (msg.m_command == "PING") {
				g_client.WriteRaw("PONG :" + msg.m_params[0] + "\n");
			}
		}
	}
}
