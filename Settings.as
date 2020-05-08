namespace Context {
    // Global Variables
    CGameManiaPlanet@ g_app;
    string g_last_challenge_id;
    string g_last_challenge_name;

    void Init() {
	@g_app = cast<CGameManiaPlanet>(GetApp());
	g_last_challenge_id = "";
    }

    // Settings
    // For backward compat reasons, keep the names as Setting_

    [Setting name="Auto update" description="If enabled, the command will be automatically updated when entering a map."]
    bool Setting_AutoUpdate = false;

    [Setting name="Display author name" description="If enabled, the command will contain the author login."]
    bool Setting_DisplayAuthorName = true;

    [Setting name="Display author time" description="If enabled, the command will contain the author time MM:SS.mm"]
    bool Setting_DisplayAuthorTime = true;

    [Setting name="Display MX link (if available)" description="If enabled, the command will be filled with the mania-exchange link of the map."]
    bool Setting_DisplayMXLink = true;

    [Setting name="Command name" description="Name of the command to update."]
    string Setting_CommandName = "!map";

    [Setting password name="Twitch token" description="Go to https://twitchapps.com/tmi/ and paste the result here."]
    string Setting_TwitchToken = "";

    [Setting name="Twitch channel" description="If your Twitch name is 'qwerty', your twitch channel should be '#qwerty'."]
    string Setting_TwitchChannel = "#channel";

    [Setting name="Map karma" description="If enabled, the chat will be able to vote for map karma."]
    bool Setting_MapKarma = false;

    // Karma
    [Setting name="Map-karma path"]
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
    // Karma history
    [Setting name="NOT HERE: Karma History X"]
    float Setting_KarmaHistoryX;

    [Setting name="NOT HERE: Karma History Y"]
    float Setting_KarmaHistoryY;

    [Setting name="NOT HERE: Karma History Width"]
    float Setting_KarmaHistoryWidth;

    [Setting name="NOT HERE: Karma History Height"]
    float Setting_KarmaHistoryHeight;

    [Setting name="NOT HERE: Karma History Text Size"]
    float Setting_KarmaHistoryTextSize;

    [Setting name="NOT HERE: Karma History Max Display"]
    int Setting_KarmaHistoryMaxDisplay = 15;

    // Debug
    [Setting name="DEBUG: Send to twitch" description="If disabled, the command won't be udpated, just printed in the logs."]
    bool Setting_SendToTwitch = true;
}
