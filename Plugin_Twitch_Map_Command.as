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

    MapKarma::SetToSave(GetCurrentMap());

    while (true) {
	if (onMap()) {
	    Twitch::Update();
	    MapKarma::Update();
	}
	if (changedMap()) {
	    onSetCurChallenge(GetCurrentMap());
	}
	yield();
    }

    Twitch::Disconnect();
}

void onSetCurChallenge(CGameCtnChallenge@ challenge) {
    SetLastMap(challenge);

    if (challenge !is null) {
	print("New map");
	if (Context::Setting_AutoUpdate) {
	    startnew(Command::Run);
	}

	if (Context::Setting_MapKarma) {
	    startnew(MapKarma::SaveAndLoadVotes);
	}
    } else {
	print("Left map");
	if (Context::Setting_MapKarma) {
	    startnew(MapKarma::SaveVotes);
	}
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


bool OnMouseButton(bool down, int button, int x, int y)
{
    if (Context::Setting_MapKarma) {
	MapKarma::onMouseButton(down, button, x, y);
    }

    return true;
}

void OnMouseMove(int x, int y)
{
    if (Context::Setting_MapKarma) {
	MapKarma::onMouseMove(x, y);
    }
}
