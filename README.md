# AHIT-APRandomizer
AHIT Archipelago implementation. Currently only intended to work on DLC 2.2.

# How to install
You will need the Steam release of A Hat in Time.
  
1. Open the Steam console by pasting this into your browser's URL bar: `steam://open/console`

2. In the Steam console, enter the following command: `download_depot 253230 253232 7770543545116491859`. Wait for the console to say the download is finished.

3. Once the download finishes, go to `steamapps/content/app_253230` in Steam's program folder.

4. There should be a folder named `depot_253232`. Rename it to `HatinTime_AP` and move it to your `steamapps/common` folder.

5. In the `HatinTime_AP` folder, navigate to `Binaries/Win64` and create a new file: `steam_appid.txt`. In this new text file, input the number 253230 on the first line.

6. Create a shortcut of `HatinTimeGame.exe` from that folder and move it to wherever you'd like. You will use this shortcut to open the Archipelago-compatible version of A Hat in Time.

7. Download a release of the mod. Go to `HatinTime_AP/HatinTimeGame/Mods` (if the Mods folder doesn't exist, create it) and move the `APRandomizer` folder into it.

8. Start up the game using your new shortcut. Go to the game's settings and make sure "Enable Developer Console" is checked.

When you create a new save file, you should be prompted to enter your slot name, password, and AP server address:port after loading into the Spaceship.

# Console Commands
Console commands will not work on the titlescreen. You must be in-game to use them.

`ap_set_connection_info <IP> <port>`
Change the IP and port that the client will connect to on this save file. The IP *MUST* be in double quotes!

`ap_show_connection_info`
Shows the current IP and port that the client will connect to on this save file.

`ap_say <message>`
Sends a chat message to the server. Using commands like !release should also work, though you should use !hint in a text client, because the game is unfortunately not able to print hint messages. (at least not yet)

`ap_deathlink`
Toggle Death Link.

`ap_connect`
Forces the client to attempt a connection to the server. You shouldn't have to use this, but you can try it if the client won't connect for some reason.

# FAQ/Common Issues
**I followed all of the instructions correctly, but when I launch the game the mod doesn't work. What gives?**  
Sometimes after installing the mod, it will disable itself in the mod menu in-game for an unknown reason. To fix this, go into the Mods menu in-game (rocket icon), click on the Archipelago icon and make sure the mod is enabled. If the mod isn't in the menu, try making sure you followed the instructions correctly or let me know in the Archipelago Discord thread for A Hat in Time if you can't get the mod to work.


**Why does the game disconnect when I enter a loading screen?**  
The script that connects to the Archipelago server has to reinitialize on every map transition. This is an issue with the game's engine that can't be worked around.


**When I complete a relic combo, the relics disappear from the relic stand once I load into the Spaceship again. Why?**  
This is intended behaviour. The reason for it being that if this weren't the case, you would potentially be able to lock yourself out of a seed by placing relics in an order that the logic did not expect you to. The Time Rift will still be unlocked.


**Will other mods that I have cause issues or conflicts with the Archipelago mod?**  
Not that I know of in particular. However, any of your newer (2021 and later) workshop mods may not load due to their package version being newer. That said, most mods shouldn't cause problems (again, from what I know).


**Why is there a lack of options for adjusting the amount of Time Pieces in the pool?**  
The reason for this is mostly because the game enforces a hard-limit on the amount of Time Pieces you can have based on the DLC you have installed. Without any DLC, the limit is 40. With Seal the Deal, the limit is increased by 6, and with Nyakuza Metro, the limit is increased by 10, for a grand total of 56. There is an option to shuffle extra Time Pieces into the pool based on DLC options being enabled (MaxExtraTimePieces), but going above these limits is not possible. As for there being no option to lower the amount of Time Pieces in the pool below 40, I personally don't see any purpose in going below 40. If you want to change how long it takes to unlock chapters, there are plenty of options to customize how chapter costs are calculated.
