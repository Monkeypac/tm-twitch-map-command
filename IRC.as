namespace IRC
{
	class Prefix
	{
		string m_origin;
		string m_user;
		string m_host;

		Prefix(const string &in prefix)
		{
			auto match = Regex::Match(prefix, """:([^!@]+)(![^@]+)?(@.+)?""");
			m_origin = match[1];
			m_user = match[2].SubStr(1);
			m_host = match[3].SubStr(1);
		}
	}

	class Message
	{
		dictionary m_tags;
		Prefix@ m_prefix;

		string m_command;
		array<string> m_params;

		Message(string line)
		{
			auto matchTags = Regex::Search(line, """^(@[^ ]+) """);
			if (matchTags.Length != 0) {
				auto matchAllTags = Regex::SearchAll(matchTags[1], """([a-zA-Z0-9\-]+)=?([^;]*)""");
				for (uint i = 0; i < matchAllTags.Length; i++) {
					auto matchTag = matchAllTags[i];
					m_tags.Set(matchTag[1], matchTag[2]);
				}
				line = LineSub(line, matchTags[0]);
			}

			auto matchPrefix = Regex::Search(line, """^(:[^ ]+) """);
			if (matchPrefix.Length != 0) {
				@m_prefix = Prefix(matchPrefix[1]);
				line = LineSub(line, matchPrefix[0]);
			}

			auto matchCommand = Regex::Search(line, """^([^ $]+|[0-9]{3}) ?""");
			m_command = matchCommand[1];

			line = LineSub(line, matchCommand[0]);

			while (line.Length > 0) {
				if (line.StartsWith(":")) {
					m_params.InsertLast(line.SubStr(1));
					break;
				}

				int spaceIndex = line.IndexOf(" ");
				if (spaceIndex == -1) {
					m_params.InsertLast(line);
					break;
				}

				m_params.InsertLast(line.SubStr(0, spaceIndex));
				line = line.SubStr(spaceIndex + 1);
			}
		}

		string LineSub(const string &in line, const string &in match)
		{
			//TODO: There is some bug that doesn't let us do this:
			//        line = line.SubStr(matchTags[0].Length);
			//      Because .Length seems to be called on an invalid object?
			return line.SubStr(match.Length);
		}
	}
}
