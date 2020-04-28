#name "Twitch commands"
#author "Monkeypac"
#category "Twitch"
#include "TwitchChat.as"

/////////////////////////////////////////////////
// WARNING
//
// Don't edit below unless you want to try stuff
////////////////////////////////////////////////

[Setting name="Auto update" description="If enabled, the command will be automatically updated when entering a map."]
bool Setting_AutoUpdate = false;

[Setting name="Display author name" description="If enabled, the command will contain the author login."]
bool Setting_DisplayAuthorName = true;

[Setting name="Display author time" description="If enabled, the command will contain the author time MM:SS.mm"]
bool Setting_DisplayAuthorTime = true;

[Setting name="Display MX link (if available)" description="If enabled, the command will be filled with the mania-exchange link of the map."]
bool Setting_DisplayMXLink = true;

[Setting name="Map karma" description="If enabled, the chat will be able to vote for map karma."]
bool Setting_MapKarma = false;

[Setting name="Command name" description="Name of the command to update."]
string Setting_CommandName = "!map";

[Setting password name="Twitch token" description="Go to https://twitchapps.com/tmi/ and paste the result here."]
string Setting_TwitchToken = "";

[Setting name="Twitch channel" description="If your Twitch name is 'qwerty', your twitch channel should be '#qwerty'."]
string Setting_TwitchChannel = "#channel";

[Setting name="DEBUG: Send to twitch" description="If disabled, the command won't be udpated, just printed in the logs."]
bool Setting_SendToTwitch = true;

[Setting name="NOT HERE: Map-karma path"]
string Setting_MapKarmaPath = "";

[Setting name="NOT HERE: Karma X"]
float Setting_KarmaX;

[Setting name="NOT HERE: Karma Y"]
float Setting_KarmaY;

[Setting name="NOT HERE: Karma Width"]
float Setting_KarmaWidth;

[Setting name="NOT HERE: Karma Height"]
float Setting_KarmaHeight;

[Setting name="NOT HERE: Karma Radius"]
float Setting_KarmaRadius;

[Setting name="NOT HERE: Karma Text Size"]
float Setting_KarmaTextSize;

[Setting name="NOT HERE: Karma Red"]
float Setting_KarmaR;

[Setting name="NOT HERE: Karma Green"]
float Setting_KarmaG;

[Setting name="NOT HERE: Karma Blue"]
float Setting_KarmaB;

[Setting name="NOT HERE: Karma Alpha"]
float Setting_KarmaA;

string Setting_TwitchNickname = "Nickname";

CGameManiaPlanet@ g_app;
string g_last_challenge_id;
string g_last_challenge_name;

// About the Map

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

string GetAuthorTime(CGameCtnChallenge@ challenge) {
    float baseTime = challenge.TMObjective_AuthorTime;
    float allSeconds = baseTime / 1000;
    int minutes = int(Math::Floor(allSeconds / 60));
    float seconds = allSeconds % 60;

    return "" + minutes + ":" + seconds;
}

string StripFormatCodes(string s)
{
    return Regex::Replace(s, "\\$([0-9a-fA-F]{1,3}|[iIoOnNmMwWsSzZtTgG<>]|[lLhHpP](\\[[^\\]]+\\])?)", "");
}

// Retrieve the map ID from MX and format the url
// If the map has been updated on MX, it won't be found
string GetMapMXLinkMessage(CGameCtnChallenge@ challenge) {
    Json::Value payload = GetMXPayload(challenge.EdChallengeId);
    if (payload.GetType() != Json::Type::Array || payload.Length == 0) {
	return "";
    }

    int trackId = payload[0]["TrackID"];

    string result = " See https://tm.mania-exchange.com/tracks/" + trackId;

    return result;
}

// Network
// Tweaked code from the tutorial
Json::Value GetMXPayload(string mapId) {
    auto sock = Net::Socket();

    if (!sock.Connect("api.mania-exchange.com", 80)) {
	print("Couldn't initiate socket connection.");
	return Json::Value();
    }

    print(Time::Now + " Connecting to host...");

    while (!sock.CanWrite()) {
	sleep(10);
	continue;
    }

    print(Time::Now + " Connected! Sending request...");

    if (!sock.WriteRaw(
	    "GET /tm/maps/" + mapId + " HTTP/1.1\r\n" +
	    "Host: api.mania-exchange.com\r\n" +
	    "User-agent: Plugin for TM\r\n" +
	    "Connection: close\r\n" +
	    "\r\n"
	)) {
	// If this fails, the socket might not be open. Something is wrong!
	print("Couldn't send data.");
	return Json::Value();
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

    return Json::Parse(response);
}

// for debug purposes
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

dictionary votes = {};

// Void callbacks for twitch
class ChatCallbacks : Twitch::ICallbacks
{
    void OnMessage(IRC::Message@ msg)
    {
	if (!Setting_MapKarma) {
	    return;
	}
	if (GetCurrentMap() is null) {
	    return;
	}

	string username = msg.m_prefix.m_user;
	string message = msg.m_params[1];

	if (message == "--") {
	    UpdateVotes(username, 0);
	}
	if (message == "-") {
	    UpdateVotes(username, 25);
	}
	if (message == "-+" || msg.m_params[1] == "+-") {
	    UpdateVotes(username, 50);
	}
	if (message == "+") {
	    UpdateVotes(username, 75);
	}
	if (message == "++") {
	    UpdateVotes(username, 100);
	}
    }

    void OnUserNotice(IRC::Message@ msg)
    {}
}

void UpdateVotes(string username, int value) {
    if (votes.Exists(username)) {
	g_totalVotes -= int(votes[username]);
    }
    votes.Set(username, value);
    g_totalVotes += value;
    g_voteScore = g_totalVotes / votes.GetSize();
}

string GetVoteFileName() {
    return Setting_MapKarmaPath + GetMapID() + ".txt";
}

string GetMapID() {
    if (g_last_challenge_id == "") {
	auto currentMap = GetCurrentMap();

	if (currentMap is null) {
	    return "";
	}

	return currentMap.EdChallengeId;
    }

    return g_last_challenge_id;
}

string GetLastMapName() {
    if (g_last_challenge_name == "") {
	auto currentMap = GetCurrentMap();

	if (currentMap is null) {
	    return "";
	}

	return GetMapName(currentMap);
    }

    return g_last_challenge_name;
}

void SaveVotes() {
    if (GetMapID() == "") {
	return;
    }

    string fileName = GetVoteFileName();

    print("Writing votes to: " + fileName);

    IO::File file(fileName);
    file.Open(IO::FileMode::Write);

    MemoryBuffer buf;

    string[]@ keys = votes.GetKeys();
    for (int i = 0; i < int(keys.Length); i ++) {
	buf.Write(uint64(keys[i].Length));
	buf.Write(keys[i]);
	buf.Write(int(votes[keys[i]]));
    }

    file.Write(buf);
    file.Close();

    g_historyNames.InsertLast(GetLastMapName());
    g_historyValues.InsertLast(g_voteScore);
}

void ResetVotes() {
    votes.DeleteAll();
    g_totalVotes = 0;
    g_voteScore = 0;
}

void LoadVotes() {
    if (GetMapID() == "") {
	return;
    }

    ResetVotes();

    string fileName = GetVoteFileName();
    if (!IO::FileExists(fileName)) {
	return;
    }

    print("Loading votes from: " + fileName);

    IO::File file(fileName);
    file.Open(IO::FileMode::Read);

    MemoryBuffer buf = file.Read(file.Size());

    while (!buf.AtEnd()) {
	string username = buf.ReadString(buf.ReadUInt64());
	int vote = buf.ReadInt32();
	UpdateVotes(username, vote);
    }

    file.Close();
}

// Main functions

void Main()
{
    print("Connecting to Twitch chat...");

    @g_app = cast<CGameManiaPlanet>(GetApp());
    Setting_AutoUpdate = false;
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
	if (changedMap()) {
	    g_last_challenge_id = GetMapID();
	    g_last_challenge_name = GetMapName(GetCurrentMap());
	    if (Setting_AutoUpdate) {
		startnew(doTheJob);
	    }
	    if (Setting_MapKarma) {
		startnew(LoadVotes);
	    }
	}
	if (Setting_MapKarma) {
	    if (leftMap()) {
		SaveVotes();
		g_last_challenge_id = "";
		g_last_challenge_name = "";
	    }

	    if (onMap()) {
		Twitch::Update();
	    }
	}

	yield();
    }
}

bool changedMap() {
    auto currentMap = GetCurrentMap();

    return currentMap !is null && currentMap.EdChallengeId != g_last_challenge_id;
}

bool leftMap() {
    return GetCurrentMap() is null && g_last_challenge_id != "";
}

bool onMap() {
    return GetCurrentMap() !is null;
}

void doTheJob() {
    auto currentMap = GetCurrentMap();
    if (currentMap !is null) {
	doIt(currentMap);

	if (g_chatVoteEnabled) {
	    LoadVotes();
	}
    }
}

void doIt(CGameCtnChallenge@ currentMap) {
    if (Setting_CommandName == "") {
	Setting_CommandName = "!map";
    }

    string message = "!commands edit " + Setting_CommandName + " " + GetMapName(currentMap);

    if (Setting_DisplayAuthorName) {
	message = message + " by " + GetAuthor(currentMap);
    }

    if (Setting_DisplayAuthorTime) {
	message = message + " in " + GetAuthorTime(currentMap);
    }

    message = message + ".";

    if (Setting_DisplayMXLink) {
	message = message + GetMapMXLinkMessage(currentMap);
    }

    if (Setting_SendToTwitch) {
	Twitch::SendMessage(message);
    }

    print(message);
    g_last_challenge_id = currentMap.EdChallengeId;
    g_last_challenge_name = GetMapName(currentMap);
}

void RenderMenu()
{
    if (UI::MenuItem("Manually update command")) {
	startnew(doTheJob);
    }

    if (UI::MenuItem("Call command in chat")) {
	if (Setting_SendToTwitch) {
	    Twitch::SendMessage(Setting_CommandName);
	}
	print(Setting_CommandName);
    }

    if (Setting_MapKarma) {
	if (UI::MenuItem("Show map karma", "", g_chatVoteEnabled)) {
	    g_chatVoteEnabled = !g_chatVoteEnabled;
	}

	if (UI::MenuItem("Show map karma history", "", g_chatVoteHistoryEnabled)) {
	    g_chatVoteHistoryEnabled = !g_chatVoteHistoryEnabled;
	}

	if (UI::MenuItem("Save karma to file")) {
	    if (g_chatVoteEnabled) {
		SaveVotes();
	    }
	}

	if (UI::MenuItem("Load karma from file")) {
	    if (g_chatVoteEnabled) {
		LoadVotes();
	    }
	}
    }
}

bool g_chatVoteEnabled = true;
bool g_chatVoteHistoryEnabled = false;
float g_voteScore = 0;
float g_totalVotes = 0;
array<string> g_historyNames;
array<float> g_historyValues;

void RenderInterface()
{
    if (!Setting_MapKarma) {
	return;
    }

    if (g_chatVoteHistoryEnabled) {
	if (UI::Begin("Map Karma History", g_chatVoteHistoryEnabled)) {
	    for (int i = 0; i < int(g_historyNames.Length); i ++) {
		UI::Text(g_historyNames[i] + " : " + int(g_historyValues[i]) + "%");
	    }
	}
	UI::End();
    }

    if (onMap() && g_chatVoteEnabled) {
	if (UI::Begin("Map Karma", g_chatVoteEnabled)) {
	    UI::Text("Current value");
	    UI::SliderFloat("", g_voteScore, 0, 100);
	    if (UI::Button("Reset current map")) {
		ResetVotes();
	    }

	    UI::Separator();

	    UI::Text("Common settings");
	    Setting_KarmaX = UI::SliderFloat("X", Setting_KarmaX, 0, Draw::GetWidth());
	    Setting_KarmaY = UI::SliderFloat("Y", Setting_KarmaY, 0, Draw::GetHeight());

	    UI::Separator();

	    UI::Text("Advanced settings");
	    Setting_KarmaWidth = UI::SliderFloat("Width", Setting_KarmaWidth, 0, Draw::GetWidth());
	    Setting_KarmaHeight = UI::SliderFloat("Height", Setting_KarmaHeight, 0, Draw::GetHeight());
	    Setting_KarmaRadius = UI::SliderFloat("Radius", Setting_KarmaRadius, 0, 180);

	    UI::NewLine();

	    Setting_KarmaTextSize = UI::SliderFloat("Text size", Setting_KarmaTextSize, 0, 100);

	    UI::NewLine();

	    Setting_KarmaR = UI::SliderFloat("Red", Setting_KarmaR, 0, 1);
	    Setting_KarmaG = UI::SliderFloat("Green", Setting_KarmaG, 0, 1);
	    Setting_KarmaB = UI::SliderFloat("Blue", Setting_KarmaB, 0, 1);
	    Setting_KarmaA = UI::SliderFloat("Alpha", Setting_KarmaA, 0, 1);

	    UI::NewLine();

	    Setting_MapKarmaPath = UI::InputText("Save path", Setting_MapKarmaPath);
	}
	UI::End();
    }
}

void Render() {
    if (Setting_MapKarma && onMap() && g_chatVoteEnabled) {
	vec4 purple = vec4(0.38, 0.05, 0.43, 1);
	vec4 black = vec4(0, 0, 0, 1);
	vec4 white = vec4(1, 1, 1, 1);
	vec4 blackTransparent = vec4(0, 0, 0, 0.5);
	vec4 color = vec4(Setting_KarmaR, Setting_KarmaG, Setting_KarmaB, Setting_KarmaA);

	// Background
	vec4 rect = vec4(Setting_KarmaX-10, Setting_KarmaY-10, Setting_KarmaWidth + 20, Setting_KarmaHeight + Setting_KarmaHeight + 10);
	Draw::FillRect(rect, blackTransparent, Setting_KarmaRadius);

	// Score bar
	if (g_voteScore != 0) {
	    vec4 rect3 = vec4(Setting_KarmaX, Setting_KarmaY, Setting_KarmaWidth * (g_voteScore/100), Setting_KarmaHeight);
	    Draw::FillRect(rect3, color, Setting_KarmaRadius);
	}

	// Contour
	vec4 rect2 = vec4(Setting_KarmaX, Setting_KarmaY, Setting_KarmaWidth, Setting_KarmaHeight);
	Draw::DrawRect(rect2, color, Setting_KarmaRadius);

	// Text
	vec2 textPos = vec2(Setting_KarmaX, Setting_KarmaY + Setting_KarmaHeight);
	string text = "Map Karma: " + int(g_voteScore) + " % (" + votes.GetSize() + " votes)";
	Draw::DrawString(textPos, color, text, null, Setting_KarmaTextSize);
    }
}
