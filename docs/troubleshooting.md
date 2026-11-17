# Troubleshooting

- **Steam not detected:** install/open official Steam, then Check again. Select a server root manually for custom libraries.
- **Game found but no server:** 322330 is the game. Install Dedicated Server 343050 under Steam Tools.
- **No server binary:** select the folder containing `bin64/dontstarve_dedicated_server_nullrenderer_x64[.exe]`.
- **Klei token missing/invalid:** obtain your own token from Klei. Token existence can be checked locally; validity is known
  only from real server/Klei interaction. Review console, not a simulated success state.
- **Stuck at Starting:** actual readiness signals have not arrived. After 90s status becomes Needs attention. Inspect logs for
  mod download progress, token errors, missing libraries or shard linkage. Do not start a duplicate.
- **Shutdown timeout:** the game may not accept stdin in this environment. Inspect console. Forced kill is a separate explicit
  confirmation and can lose unsaved progress. Never treat a requested shutdown as completed until the process exits.
- **Existing PID detected:** stdin of an external process cannot be reattached. Stop that exact server through the OS/its console,
  then restart the launcher. No arbitrary PID is killed based on a stale registry alone.
- **Workshop unavailable / rate-limited:** retain the input and retry later. Check the item in Steam. Private/deleted items and
  non-DST metadata are rejected. Collection import is limited to 100 direct children; nested collections are not supported.
- **Mod changes on a running server:** stop both shards before editing. Server files download through DST at startup.
- **Ports busy:** stop the other process or use a new profile range; a running server is expected to occupy its own ports.
- **Friends cannot join:** try the game's server list first. Local free UDP is not internet reachability. Check firewall/router,
  public IPv4 and CGNAT with the ISP. No claim is made that port-forwarding solves every carrier network.
- **Linux shared library missing:** review ldd output; install matching distro packages and architecture. Don't run as root.
- **Write permission / disk error:** choose a user-writable storage folder and check free space. Staging folders are kept after
  failure for inspection; do not delete existing worlds to retry.
- **Backup restore failed:** original data is kept until final rename. Look for .before_restore_* or .restore_* beside the cluster.
- **Manual mod Lua edits disappeared:** modoverrides is generated from GUI on start. Keep your own copies and reconcile first.
