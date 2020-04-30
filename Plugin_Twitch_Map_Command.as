#name "Twitch commands"
#author "Monkeypac"
#category "Twitch"

#include "Settings.as"
#include "TwitchChat.as"
#include "Map.as"
#include "Command.as"
#include "MapKarma.as"

// Void callbacks for twitch
class ChatCallbacks : Twitch::ICallbacks
{
    void OnMessage(IRC::Message@ msg)
    {
	if (Context::Setting_MapKarma) {
	    MapKarma::OnMessage(msg.m_params[1], msg.m_prefix.m_user);
	}
    }

    void OnUserNotice(IRC::Message@ msg)
    {}
}

void InitTwitch() {
    print("Connecting to Twitch chat...");

    auto callbacks = ChatCallbacks();
    if (!Twitch::Connect(callbacks)) {
	return;
    }

    print("Connected to Twitch chat!");

    Twitch::Login(
	Context::Setting_TwitchToken,
	Context::Setting_TwitchNickname,
	Context::Setting_TwitchChannel
    );
}

// Main functions
void Main()
{
    Context::Init();
    InitTwitch();

    while (true) {
	if (changedMap()) {
	    Context::g_last_challenge_id = GetSetCurrentMapID();
	    Context::g_last_challenge_name = GetMapName(GetCurrentMap());
	    if (Context::Setting_AutoUpdate) {
		startnew(Command::Run);
	    }
	    if (Context::Setting_MapKarma) {
		startnew(MapKarma::SaveAndLoadVotes);
	    }
	}
	if (Context::Setting_MapKarma) {
	    if (leftMap()) {
		startnew(MapKarma::SaveVotes());
		Context::g_last_challenge_id = "";
		Context::g_last_challenge_name = "";
	    }

	    if (onMap()) {
		Twitch::Update();
	    }
	}

	yield();
    }
}

void RenderMenu()
{
    Command::renderMenu();

    if (Context::Setting_MapKarma) {
	MapKarma::renderMenu();
    }
}

void RenderInterface()
{
    if (Context::Setting_MapKarma) {
	MapKarma::renderInterface();
    }
}

void Render() {
    if (Context::Setting_MapKarma) {
	MapKarma::render();
    }
}


