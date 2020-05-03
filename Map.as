CGameCtnChallenge@ GetCurrentMap()
{
    return Context::g_app.RootMap;
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

string GetLastMapID() {
    if (Context::g_last_challenge_id == "") {
	auto currentMap = GetCurrentMap();

	if (currentMap is null) {
	    return "";
	}

	return currentMap.EdChallengeId;
    }

    return Context::g_last_challenge_id;
}

string GetLastMapName() {
    if (Context::g_last_challenge_name == "") {
	auto currentMap = GetCurrentMap();

	if (currentMap is null) {
	    return "";
	}

	return GetMapName(currentMap);
    }

    return Context::g_last_challenge_name;
}

string GetMapID(CGameCtnChallenge@ currentMap) {
    return currentMap.EdChallengeId;
}

string GetCurrentMapID() {
    auto currentMap = GetCurrentMap();

    if (currentMap is null) {
	return "";
    }

    return currentMap.EdChallengeId;
}

void SetLastMap(CGameCtnChallenge@ challenge) {
    if (challenge is null) {
	Context::g_last_challenge_id = "";
	Context::g_last_challenge_name = "";
	return;
    }

    Context::g_last_challenge_id = GetMapID(challenge);
    Context::g_last_challenge_name = GetMapName(challenge);
}

bool changedMap() {
    auto currentMap = GetCurrentMap();

    return currentMap !is null && currentMap.EdChallengeId != Context::g_last_challenge_id;
}

bool leftMap() {
    return GetCurrentMap() is null && Context::g_last_challenge_id != "";
}

bool onMap() {
    return GetCurrentMap() !is null;
}
