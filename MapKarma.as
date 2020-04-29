
namespace MapKarma {
    bool g_chatVoteEnabled = true;
    bool g_chatVoteHistoryEnabled = false;

    dictionary votes = {};
    float g_voteScore = 0;
    float g_totalVotes = 0;

    array<string> g_historyNames;
    array<float> g_historyValues;

    void OnMessage(string message, string username) {
	if (GetCurrentMap() is null) {
	    return;
	}

	if (message == "--") {
	    UpdateVotes(username, 0);
	}
	if (message == "-") {
	    UpdateVotes(username, 25);
	}
	if (message == "-+" || message == "+-") {
	    UpdateVotes(username, 50);
	}
	if (message == "+") {
	    UpdateVotes(username, 75);
	}
	if (message == "++") {
	    UpdateVotes(username, 100);
	}
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
	return Context::Setting_MapKarmaPath + GetLastMapID() + ".txt";
    }

    void SaveVotes() {
	if (GetLastMapID() == "") {
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
	if (GetCurrentMapID() == "") {
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

    void renderMenu() {
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

    void renderInterface() {
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
		Context::Setting_KarmaX = UI::SliderFloat("X", Context::Setting_KarmaX, 0, Draw::GetWidth());
		Context::Setting_KarmaY = UI::SliderFloat("Y", Context::Setting_KarmaY, 0, Draw::GetHeight());

		UI::Separator();

		UI::Text("Advanced settings");
		Context::Setting_KarmaWidth = UI::SliderFloat("Width", Context::Setting_KarmaWidth, 0, Draw::GetWidth());
		Context::Setting_KarmaHeight = UI::SliderFloat("Height", Context::Setting_KarmaHeight, 0, Draw::GetHeight());
		Context::Setting_KarmaRadius = UI::SliderFloat("Radius", Context::Setting_KarmaRadius, 0, 180);

		UI::NewLine();

		Context::Setting_KarmaTextSize = UI::SliderFloat("Text size", Context::Setting_KarmaTextSize, 0, 100);

		UI::NewLine();

		Context::Setting_KarmaR = UI::SliderFloat("Red", Context::Setting_KarmaR, 0, 1);
		Context::Setting_KarmaG = UI::SliderFloat("Green", Context::Setting_KarmaG, 0, 1);
		Context::Setting_KarmaB = UI::SliderFloat("Blue", Context::Setting_KarmaB, 0, 1);
		Context::Setting_KarmaA = UI::SliderFloat("Alpha", Context::Setting_KarmaA, 0, 1);

		UI::NewLine();

		Context::Setting_MapKarmaPath = UI::InputText("Save path", Context::Setting_MapKarmaPath);
	    }
	    UI::End();
	}
    }

    void render() {
	if (onMap() && g_chatVoteEnabled) {
	    vec4 purple = vec4(0.38, 0.05, 0.43, 1);
	    vec4 black = vec4(0, 0, 0, 1);
	    vec4 white = vec4(1, 1, 1, 1);
	    vec4 blackTransparent = vec4(0, 0, 0, 0.5);
	    vec4 color = vec4(Context::Setting_KarmaR, Context::Setting_KarmaG, Context::Setting_KarmaB, Context::Setting_KarmaA);

	    // Background
	    vec4 rect = vec4(Context::Setting_KarmaX-10, Context::Setting_KarmaY-10, Context::Setting_KarmaWidth + 20, Context::Setting_KarmaHeight + Context::Setting_KarmaHeight + 10);
	    Draw::FillRect(rect, blackTransparent, Context::Setting_KarmaRadius);

	    // Score bar
	    if (g_voteScore != 0) {
		vec4 rect3 = vec4(Context::Setting_KarmaX, Context::Setting_KarmaY, Context::Setting_KarmaWidth * (g_voteScore/100), Context::Setting_KarmaHeight);
		Draw::FillRect(rect3, color, Context::Setting_KarmaRadius);
	    }

	    // Contour
	    vec4 rect2 = vec4(Context::Setting_KarmaX, Context::Setting_KarmaY, Context::Setting_KarmaWidth, Context::Setting_KarmaHeight);
	    Draw::DrawRect(rect2, color, Context::Setting_KarmaRadius);

	    // Text
	    vec2 textPos = vec2(Context::Setting_KarmaX, Context::Setting_KarmaY + Context::Setting_KarmaHeight);
	    string text = "Map Karma: " + int(g_voteScore) + " % (" + votes.GetSize() + " votes)";
	    Draw::DrawString(textPos, color, text, null, Context::Setting_KarmaTextSize);
	}
    }
}
