# Architecture and product boundaries

Single local OS user, no cloud account or backend. The user's filesystem is the authority.
Top jobs: create a world without editing INI/Lua; start/stop Master+Caves; keep saves safe.

Routes: `/` profiles/onboarding; `/create` nine-step wizard; `/install` dependency detection;
`/workshop` per-profile mod configuration; `/server/:id` status/world/mods/players/console/network/files/backups;
`/settings` locale/theme/new-world storage/diagnostics. Every view has an honest empty/error state.

`domain/` validated profile/mod models and system interfaces.
`data/` filesystem/ZIP, INI+Lua generation, Valve metadata, Steam libraries, processes, UDP.
`app/` Provider ChangeNotifier, router, theme, ARB localization delegate.
`features/` forms and views. OS operations are awaited outside render methods, except bounded read previews.

ServerProfile is serializable, with a schema-versioned registry. It owns immutable identity, absolute paths,
world generation parameters, per-profile port block and shard key. Klei token is not in JSON.
Runtime states, PIDs, readiness timers and bounded console history live in ProcessSupervisor, not profiles.
Process transitions: stopped → starting → running (log marker) → stopping → stopped; nonzero unexpected exit → crashed;
unconfirmed readiness/external existing PID → needs attention. No synthetic player counts or external connectivity.

The wizard produces a new UUID-like safe cluster ID, independent of the display name. Configuration is staged
then renamed as a directory. Profile registry uses a recoverable `.previous` journal. Existing clusters are never
overwritten during creation. Import copies a stopped cluster; saves/world overrides are preserved, new ports
and identity are assigned, source directory remains unchanged. Workshop settings imported from external Lua
are not evaluated; imported modoverrides files and their custom options remain manually managed and are never overwritten by the launcher. Ensure the corresponding server installation has the required Workshop downloads configured before launching.

Processes use `Process.start(executable, args, workingDirectory: bin64, runInShell: false)` and official
`-persistent_storage_root`, `-conf_dir`, `-cluster`, `-shard`, `-console`, `-monitor_parent_process` flags.
Stdin exposes only c_save / c_shutdown(true). PID journal recovery checks command line identity before blocking
a duplicate; it never kills an arbitrary recovered PID or pretends stdin was reattached.

Valve API requests have connect/receive timeouts. Collections expand to ≤100 checked 322330 items. Search by
name remains in Steam. Download configuration and per-shard enablement are separate. Existing Steam mods setup
entries are preserved; removed launcher entries may remain downloaded but are no longer enabled on the shard.

Backup mutators are only exposed for stopped profiles. Restore validates the ZIP, shows file paths, creates a safety
snapshot, stages the replacement, keeps current token/identity/ports and renames with rollback. The previous cluster
directory remains beside the restored cluster for manual recovery. This tool does not coordinate with independently
started external server processes; stop such processes before import/backup/restore.

No cloud API, Docker, DRM files, sudo execution, permanent service, hidden autostart or UPnP is included.
Events: ChangeNotifier delivers profile/install/process/log changes. No telemetry is sent.
