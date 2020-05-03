namespace Command {

    // MX Socket
    Net::Socket@ sock;

    void Run() {
	auto currentMap = GetCurrentMap();
	if (currentMap !is null) {
	    run(currentMap);

	    if (MapKarma::g_chatVoteEnabled) {
		MapKarma::LoadVotes();
	    }
	}
    }

    void run(CGameCtnChallenge@ currentMap) {
	if (Context::Setting_CommandName == "") {
	    Context::Setting_CommandName = "!map";
	}

	string message = "!commands edit " + Context::Setting_CommandName + " " + GetMapName(currentMap);

	if (Context::Setting_DisplayAuthorName) {
	    message = message + " by " + GetAuthor(currentMap);
	}

	if (Context::Setting_DisplayAuthorTime) {
	    message = message + " in " + GetAuthorTime(currentMap);
	}

	message = message + ".";

	if (Context::Setting_DisplayMXLink) {
	    message = message + GetMapMXLinkMessage(currentMap);
	}

	if (Context::Setting_SendToTwitch) {
	    Twitch::SendMessage(message);
	}

	print(message);
	Context::g_last_challenge_id = GetMapID(currentMap);
	Context::g_last_challenge_name = GetMapName(currentMap);
	UI::ShowNotification("Twitch command " + Context::Setting_CommandName + " updated", 5000);
    }

    void renderMenu() {
	if (UI::MenuItem("Manually update command")) {
	    startnew(Run);
	}

	if (UI::MenuItem("Call command in chat")) {
	    if (Context::Setting_SendToTwitch) {
		Twitch::SendMessage(Context::Setting_CommandName);
	    }
	    print(Context::Setting_CommandName);
	}
    }

    // Retrieve the map ID from MX and format the url
    // If the map has been updated on MX, it won't be found
    string GetMapMXLinkMessage(CGameCtnChallenge@ challenge) {
	Json::Value payload = GetMXPayload(GetMapID(challenge));
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
	if (sock is null) {
	    @sock = Net::Socket();

	    if (!sock.Connect("api.mania-exchange.com", 80)) {
		print("Couldn't initiate socket connection.");
		return Json::Value();
	    }

	    print(Time::Now + " Connecting to host...");

	    while (!sock.CanWrite()) {
		sleep(500);
		print("can't write");
	    }
	}

	if (sock is null) {
	    print("not available !");
	    return Json::Value();
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
		sleep(500);
		continue;
	    }

	    // There's buffered data! Try to get a line from the buffer.
	    string line;
	    if (!sock.ReadLine(line)) {
		// We couldn't get a line at this point in time, so we'll wait a
		// bit longer.
		sleep(500);
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
		sleep(500);
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

    void Disconnect() {
	if (sock is null) {
	    return;
	}

	sock.Close();
	@sock = null;
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
}
