# tm-twitch-map-command
A simple Trackmania command for setting a !map in the Twitch chat.

Also, this now has a MapKarma feature to use from Twitch chat.

I used https://openplanet.nl/files/22 for this project.

Note that we using this, your game might crash at some point if there are cases I didn't encounter already. Be prepared to that. Disable the plugin when going for a competition if you're afraid of crashes.

/!\ This does not work for Turbo

# Install

- Install Openplanet: https://openplanet.nl/tutorials/installation
- Copy the files to C:/Users/[Username]/Openplanet4/Scripts/
- Open Maniaplanet
- Open Openplanet toolbar (F3 default)
- Click on Openplanet > Settings > Twitch commands
- Go to https://twitchapps.com/tmi/ .
- Paste the text you get in the field `Twitch Token`.
- Set the `Twitch channel` field.
- Reload the script using Scripts > Reload scripts.
- DO NOT TOUCH SETTINGS BELOW "Twitch channel" WITHOUT READING THIS WHOLE FILE.

# Twitch command !map

The idea is to be able to easily set a "!map" command on a twitch chat using Nightbot.

Beware, if you're not on a map, nothing will happen ! :)

- Run Maniaplanet
- Open Openplanet toolbar
- Click on Scripts > Twitch > Manually update command
==> Done

If you enabled the `Auto update` setting in Openplanet > Settings > Twitch commands, you don't need to click on the `Manually update command` button.

You can call the command in your chat from the game using: Scripts > Twitch > Call command in chat.

You'll get an in game notification when the command is being updated. If your Twitch connection failed (mostly due to a token problem), you'll get the notification anyway.

# Map Karma

The idea is to be able to have the chat vote for the current map you are playing.

This is based on the same system that most MapKarma systems on TM servers.

Anyone in chat can vote using the following:
| message | value |
|---------|-------|
| --      | 0     |
| -       | 25    |
| -+      | 50    |
| +-      | 50    |
| +       | 75    |
| ++      | 100   |

Each person from the chat can vote once per map.

If they vote a second time, it updates their vote.

The karma for each map will be saved on your disk (in a non human readable format) when you leave a map.

The karma for a map you enter will be loaded from disk. (if it doesn't have a karma, then you just won't have karma yet).

## Setup

### Enabling MapKarma

For enabling MapKarma, you have two main actions to do:

1. Go to Openplanet >Settings >Twitch commands and check the `Map karma` button

2. Go to Openplanet >Settings >Twitch commands and fill in the `Map-karma path` field with a valid path ending with a `/`
- Ensure the directory exists
- Ensure you can write in that directory without super user permissions
- Do not forget the `/`
- Path should look like `D:/mapkarma/` or `C:/Users/mysuperusername/Documents/mapkarma/`

### Using the MapKarma

Once the Setting is enabled, you have access to the map karma features.

Go to Scripts > Twitch. You now have new buttons.

#### Show map karma

This is the most important of all. By clicking on this, you allow the display of an ingame window showing a slider bar with the current karma. Note that this window will stay displayed even when you close Openplanet's menu.

But what you should see immediately is an Openplanet window with many slider bars.

The first one is the current value of the karma. It's just informative, you don't have to touch this.

The reset karma button is here to fully reset all votes on a map when you want.


Then, the interesting ones:

You have X, Y, Width, Height. Theses are ultra useful.

You can play with it and see what happens but be sure to set Width and height to something larger than 0 otherwise you won't see anything.

X and Y are for the placement on the screen.

The window you are now seeing is the one that'll stay even after you close Openplanet's menu. BUT for it to stay on screen, you have to leave the menu with the settings opened.

So: Click on Scripts > Twitch > Show map karma, edit the settings, press F3.

If you want to stop displaying the in-game window, juste press F3, close the "Show map karma" window and you're good.

Then there are other settings you can play with like the radius of the border, the text size, the color of the text, ...

#### Show map karma history

When you click this, you get a new window. In there you will be able to see all the past maps you played this session and their associated karma.

This also unlocks a new section in the "Show map karma" window which will allow you to display an in-game window just like the mapkarma but for the history.

Closing this window disabled the in-game window.

#### Save karma to file

This allows you to force save the karma of the current map to file.

#### Load karma from file

This allows you to force load the karma of the current map from file.

# Troubleshouting

- I can't get Openplanet's menu to open
  - Remove the plugin files and retry
  - Refer to Openplanet's troubleshouting section or see on their discord.

- The notification "!map updated" pops up but I don't get a message in my Twitch chat
  - Check your channel settings is in lowercase and without typo
  - Go to your twitch settings at https://www.twitch.tv/settings/connections and Disconnect the "Twitch Chat OAuth Token Generator" then restart the install from the Twitch token part (go to https://twitchapps.com/tmi/)

- Game crashes when I leave a map or when I press the Save karma button
  - Check that the Karma path you have set is valid, that the directory exists, that the path ends with a `/`
