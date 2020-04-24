#name "Twitch !map command"
#author "Monkeypac"
#category "Twitch"
#include "TwitchChat.as"

// Go to https://twitchapps.com/tmi/ and paste your token down there:
// string Setting_TwitchToken = "<The Token You Just Got>";
string Setting_TwitchToken = "YourOauth";
string Setting_TwitchNickname = "YouNickName";
string Setting_TwitchChannel = "#yourchannel";

/////////////////////////////////////////////////
// WARNING
//
// Don't edit below unless you want to try stuff
////////////////////////////////////////////////

CGameManiaPlanet@ g_app;
bool g_auto_update;
string g_last_challenge_id;

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
    if (UI::MenuItem("Manually update !map")) {
	startnew(doTheJob);
    }

    if (UI::MenuItem("Auto update !map", "", g_auto_update)) {
	if (g_auto_update) {
	    g_auto_update = false;
	} else {
	    g_auto_update = true;
	}
    }
}

bool shouldAutoUpdate() {
    if (!g_auto_update) {
	return false;
    }

    auto currentMap = GetCurrentMap();

    return currentMap !is null && currentMap.EdChallengeId != g_last_challenge_id;
}

void doTheJob() {
    auto currentMap = GetCurrentMap();
    if (currentMap !is null) {
	doIt(currentMap);
    }
}

void doIt(CGameCtnChallenge@ currentMap) {
    auto mapName = GetMapName(currentMap);
    auto author = GetAuthor(currentMap);
    string message = mapName + " by " + author + ". " + GetMapMXId(currentMap);
    Twitch::SendMessage("!commands edit !map " + message);
    g_last_challenge_id = currentMap.EdChallengeId;
}

string GetMapMXId(CGameCtnChallenge@ challenge) {
    auto sock = Net::Socket();

    if (!sock.Connect("api.mania-exchange.com", 80)) {
	print("Couldn't initiate socket connection.");
	return "";
    }

    print(Time::Now + " Connecting to host...");

    while (!sock.CanWrite()) {
	sleep(10);
	continue;
    }

    print(Time::Now + " Connected! Sending request...");

    if (!sock.WriteRaw(
	    "GET /tm/maps/" + challenge.EdChallengeId + " HTTP/1.1\r\n" +
	    "Host: api.mania-exchange.com\r\n" +
	    "User-agent: Plugin for TM\r\n" +
	    "Connection: close\r\n" +
	    "\r\n"
	)) {
	// If this fails, the socket might not be open. Something is wrong!
	print("Couldn't send data.");
	return "";
    }

    print(Time::Now + " Waiting for headers...");

    // We are now ready to wait for the response. We'll need to note down
    // the content length from the response headers as well.
    int contentLength = 0;

    while (true) {
	// If there is no data available yet, yield and wait.
	while (sock.Available() == 0) {
	    sleep(10);
	    continue;
	}

	// There's buffered data! Try to get a line from the buffer.
	string line;
	if (!sock.ReadLine(line)) {
	    // We couldn't get a line at this point in time, so we'll wait a
	    // bit longer.
	    sleep(10);
	    continue;
	}

	// We got a line! Trim it, since ReadLine() returns the line including
	// the newline characters.
	line = line.Trim();

	// Parse the header line.
	auto parse = line.Split(":");
	if (parse.Length == 2 && parse[0].ToLower() == "content-length") {
	    // If this is the content length, remember it.
	    contentLength = Text::ParseInt(parse[1].Trim());
	}

	// If the line is empty, we are done reading all headers.
	if (line == "") {
	    break;
	}

	// Print the header line.
	// print(Time::Now + " \"" + line + "\"");
    }

    print(Time::Now + " Waiting for response...");

    // At this point, we've parsed all the headers. We can now wait for the
    // actual response body.
    string response = "";

    // While there is content to read from the body...
    while (contentLength > 0) {
	// Try to read up to contentLength.
	string chunk = sock.ReadRaw(contentLength);

	// Add the chunk to the response.
	response += chunk;

	// Subtract what we've read from the content length.
	contentLength -= chunk.Length;

	// If there's more to read, yield until the next frame. (Not necessary,
	// we could also only yield if there's no data available, but in this
	// example we don't care too much.)
	if (contentLength > 0) {
	    sleep(10);
	    continue;
	}
    }

    // We're all done!
    // print(Time::Now + " All done!");
    print(Time::Now + " Response: \"" + response + "\"");

    // Close the socket.
    sock.Close();

    auto titi = Json::Parse(response);
    if (titi.GetType() != Json::Type::Array || titi.Length == 0) {
	return "";
    }

    int toto = titi[0]["TrackID"];

    string result = "See https://tm.mania-exchange.com/tracks/" + toto;

    return result;
}

void printJson(Json::Value titi) {
    if (titi.GetType() == Json::Type::String) {
	print("String");
    } else
    if (titi.GetType() == Json::Type::Number) {
	print("Number");
    } else
    if (titi.GetType() == Json::Type::Object) {
	print("Object");
    } else
    if (titi.GetType() == Json::Type::Array) {
	print("Array");
    } else
    if (titi.GetType() == Json::Type::Boolean) {
	print("Boolean");
    } else
    if (titi.GetType() == Json::Type::Null) {
	print("Null");
    }
}

void Main()
{
    print("Connecting to Twitch chat...");

    @g_app = cast<CGameManiaPlanet>(GetApp());
    g_auto_update = false;
    g_last_challenge_id = "";

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

    while (true) {
	if (shouldAutoUpdate()) {
	    g_last_challenge_id = GetCurrentMap().EdChallengeId;
	    startnew(doTheJob);
	}
	yield();
    }
}

class ChatCallbacks : Twitch::ICallbacks
{
    void OnMessage(IRC::Message@ msg)
    {}

    void OnUserNotice(IRC::Message@ msg)
    {}
}
