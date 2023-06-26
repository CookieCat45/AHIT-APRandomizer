# AHIT-APRandomizer
AHIT Archipelago implementation. Currently only works on DLC 2.2.

This mod, at the moment, is entirely proof-of-concept. There will likely be many bugs, impossible seeds, generation errors, and other issues. Regardless, you can still set it up and play if you are curious or wish to help with beta-testing.

Currently, no DLC content is shuffled. Only the base game chapters (1-5) work.

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
