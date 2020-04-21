#name "Twitch !map command"
#author "Monkeypac"
#category "Twitch"
#include "TwitchChat.as"

// Go to https://twitchapps.com/tmi/ and paste your token down there:
// string Setting_TwitchToken = "<The Token You Just Got>";
string Setting_TwitchToken = "YourOauth";
string Setting_TwitchNickname = "YouNickName";
string Setting_TwitchChannel = "#yourchannel";

CGameManiaPlanet@ g_app;

CGameCtnChallenge@ GetCurrentMap()
{
    return g_app.RootMap;
}

string GetMapName(CGameCtnChallenge@ challenge)
{
    return StripFormatCodes(challenge.MapName);
}

string GetAuthor(CGameCtnChallenge@ challenge)
{
    return StripFormatCodes(challenge.AuthorLogin);
}

string StripFormatCodes(string s)
{
    return Regex::Replace(s, "\\$([0-9a-fA-F]{1,3}|[iIoOnNmMwWsSzZtTgG<>]|[lLhHpP](\\[[^\\]]+\\])?)", "");
}

void RenderMenu()
{
    if (UI::MenuItem("!map")) {
	auto currentMap = GetCurrentMap();
	if (currentMap !is null) {
	    auto mapName = GetMapName(currentMap);
	    auto author = GetAuthor(currentMap);
	    string message = mapName + " by " + author + ".";
	    Twitch::SendMessage("!commands edit !map " + message);
	}
    }
}

void Main()
{
    print("Connecting to Twitch chat...");

    @g_app = cast<CGameManiaPlanet>(GetApp());

    auto callbacks = ChatCallbacks();
    if (!Twitch::Connect(callbacks)) {
	return;
    }

    print("Connected to Twitch chat!");

    Twitch::Login(
	Setting_TwitchToken,
	Setting_TwitchNickname,
	Setting_TwitchChannel
    );
}

class ChatCallbacks : Twitch::ICallbacks
{
    void OnMessage(IRC::Message@ msg)
    {}

    void OnUserNotice(IRC::Message@ msg)
    {}
}
