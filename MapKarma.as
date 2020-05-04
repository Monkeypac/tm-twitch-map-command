
namespace MapKarma {
    bool g_chatVoteEnabled = false;
    bool g_chatVoteHistoryEnabled = false;

    dictionary votes = {};
    float g_voteScore = 0;
    float g_totalVotes = 0;

    dictionary history = {};
    array<string> historyOrder;

    string toSaveMapID;
    string toSaveMapName;

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

	if (!history.Exists(toSaveMapName)) {
	    historyOrder.InsertLast(toSaveMapName);
	}
	history[toSaveMapName] = g_voteScore;
    }

    string GetSaveVoteFileName() {
	return Context::Setting_MapKarmaPath + toSaveMapID + ".txt";
    }

    string GetSaveVoteFileMappingName() {
	return Context::Setting_MapKarmaPath + toSaveMapID + "_mapping.txt";
    }

    void SetToSave(CGameCtnChallenge@ map) {
	if (map is null) {
	    return;
	}

	toSaveMapID = GetMapID(map);
	toSaveMapName = GetMapName(map);
    }

    void SaveVotes() {
	if (toSaveMapID == "") {
	    return;
	}

	string fileName = GetSaveVoteFileName();

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

	string fileNameMapping = GetSaveVoteFileMappingName();
	IO::File fileMapping(fileNameMapping);
	fileMapping.Open(IO::FileMode::Write);
	fileMapping.WriteLine(toSaveMapName);
	fileMapping.Close();

	if (history.Exists(toSaveMapName)) {
	    history.Set(toSaveMapName, g_voteScore);
	} else {
	    history.Set(toSaveMapName, g_voteScore);
	    historyOrder.InsertLast(toSaveMapName);
	}
    }

    void ResetVotes() {
	votes.DeleteAll();
	g_totalVotes = 0;
	g_voteScore = 0;
    }

    void ResetHistory() {
	history.DeleteAll();
	historyOrder.RemoveRange(0, historyOrder.Length);
    }

    void LoadVotes() {
	SetToSave(GetCurrentMap());
	if (toSaveMapID == "") {
	    return;
	}

	ResetVotes();

	loadVotes(GetSaveVoteFileName());
    }

    void loadVotes(string fileName) {
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

    void LoadAllVotes() {
	string[]@ files = IO::IndexFolder(Context::Setting_MapKarmaPath, true);

	for (uint i = 0; i < files.Length; i++) {
	    string currentFile = files[i];

	    if (currentFile.EndsWith("_mapping.txt")) {
		continue;
	    }

	    string fileNameMapping = currentFile.SubStr(0, currentFile.Length - 4) + "_mapping.txt";

	    IO::File fileMapping(fileNameMapping);
	    fileMapping.Open(IO::FileMode::Read);
	    string mapName = fileMapping.ReadLine();
	    fileMapping.Close();

	    toSaveMapName = mapName;
	    loadVotes(currentFile);
	}
    }

    void SaveAndLoadVotes() {
	SaveVotes();
	LoadVotes();
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
		for (int i = 0; i < int(historyOrder.Length); i ++) {
		    UI::Text(historyOrder[i] + " : " + float(history[historyOrder[i]]) + "%");
		}
	    }
	    UI::End();
	}

	if (g_chatVoteEnabled) {
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

	    if (g_chatVoteHistoryEnabled) {
		UI::Separator();
		UI::Separator();

		UI::Text("History settings");
		if (UI::Button("Reset history")) {
		    ResetHistory();
		}

		if (UI::Button("Load history")) {
		    LoadAllVotes();
		}

		UI::Separator();

		UI::Text("Common settings");
		Context::Setting_KarmaHistoryX = UI::SliderFloat("History X", Context::Setting_KarmaHistoryX, 0, Draw::GetWidth());
		Context::Setting_KarmaHistoryY = UI::SliderFloat("History Y", Context::Setting_KarmaHistoryY, 0, Draw::GetHeight());

		UI::Separator();

		UI::Text("Advanced settings");
		Context::Setting_KarmaHistoryWidth = UI::SliderFloat("History Width", Context::Setting_KarmaHistoryWidth, 0, Draw::GetWidth());
		Context::Setting_KarmaHistoryHeight = UI::SliderFloat("History Height", Context::Setting_KarmaHistoryHeight, 0, Draw::GetHeight());
		UI::NewLine();

		Context::Setting_KarmaHistoryTextSize = UI::SliderFloat("History Text size", Context::Setting_KarmaHistoryTextSize, 0, 100);
	    }
	    UI::End();
	}
    }

    void render() {
	vec4 blackTransparent = vec4(0, 0, 0, 0.5);
	if (onMap() && g_chatVoteEnabled) {
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

	if (onMap() && g_chatVoteHistoryEnabled) {
	    vec4 color = vec4(Context::Setting_KarmaR, Context::Setting_KarmaG, Context::Setting_KarmaB, Context::Setting_KarmaA);

	    // Background
	    vec4 rect = vec4(Context::Setting_KarmaHistoryX-10, Context::Setting_KarmaHistoryY-10, Context::Setting_KarmaHistoryWidth + 20, Context::Setting_KarmaHistoryHeight + Context::Setting_KarmaHistoryHeight + 10);
	    Draw::FillRect(rect, blackTransparent, Context::Setting_KarmaRadius);

	    for (int i = 0; i < int(historyOrder.Length) && i < Context::Setting_KarmaHistoryMaxDisplay; i++) {
		wstring mapName = historyOrder[historyOrder.Length - 1 - i];
		string text = mapName + " : " + float(history[mapName]) + "%";
		vec2 textPos = vec2(Context::Setting_KarmaHistoryX, Context::Setting_KarmaHistoryY + i * Context::Setting_KarmaHistoryTextSize);
		Draw::DrawString(textPos, color, text, null, Context::Setting_KarmaHistoryTextSize);
	    }
	}
    }
}
