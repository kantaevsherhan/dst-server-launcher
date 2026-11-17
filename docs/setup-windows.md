# Windows 10/11 x64

1. Install the official [Steam client](https://store.steampowered.com/about/).
2. Library → filter Tools → **Don't Starve Together Dedicated Server** (343050).
   The launcher button opens `steam://install/343050`; Steam controls the actual download.
3. Check again in the launcher. Detection reads HKCU SteamPath, standard installation roots,
   libraryfolders.vdf, appmanifest_343050.acf and the x64 server executable.
   For a custom location choose the root containing `bin64`.
4. Create the profile and provide your own Klei token. Normal operation needs no administrator rights.
5. Allow the configured UDP ports in firewall only after reviewing the rule's app/profile scope.
   External router/NAT configuration is independent from local bind checks.

Default managed world location is the OS application-support directory plus `Klei/DoNotStarveTogether/<id>`.
The launcher passes its absolute storage root explicitly; it does not assume OneDrive or a localized Documents path.
You can choose another root for new worlds. Token permissions are restricted to the current user using icacls.

Update/check files: stop both shards; Steam properties → Installed Files → Verify integrity / Updates.
Steam does not receive credentials from this application. Current game, Workshop and server files remain Valve/Klei managed.

Development: Flutter 3.47.7, Visual Studio 2022 Build Tools with C++ desktop workload, CMake and Windows SDK.
Use Developer Mode/symlink permissions as you normally configure your development machine, or the optional local
junction script (no global setting changes). This is not needed by end users of the portable/installer build.
