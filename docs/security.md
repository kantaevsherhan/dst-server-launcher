# Security model

The local user owns the profiles and processes. No remote control port, login form, telemetry or application cloud exists.
Klei token is never in profile JSON, CLI args, diagnostic exports or config previews. It is stored only in the game's
`cluster_token.txt`. Windows uses icacls to remove inherited permissions and grant the current user; Linux uses mode 0600.
An ACL failure stops configuration creation. The game necessarily reads this file; it is not encrypted at rest by DST.

Profile JSON contains server password and shard key and receives the same private-file permissions. These are excluded
from diagnostic JSON. Drafts retain ordinary wizard fields only: token/password must be re-entered after leaving setup.
The process log pipeline masks known token/password/key values before rendering/persisting. Diagnostics intentionally omit
all logs, names and paths rather than trying to guess every possible secret. Do not publish raw game logs without review.

INI values reject newline/control injection. Cluster IDs are generated and path-safe. Workshop IDs are bounded numeric
values and validated as consumer app 322330 through Valve API. Lua keys are generated from an explicit supported enum,
not arbitrary UI input. No user-authored Lua or shell is executed by the launcher.
OS processes take argument arrays and explicit working directories. Linux shell exports use single-quote escaping;
sudo/firewall/service changes are never executed automatically.

ZIP restore rejects absolute paths, traversal, drive/ADS colon paths and symbolic links; limits compressed and expanded
archive sizes; requires launcher metadata and cluster.ini. Stop both shards before backup and restore. Archives exclude
cluster_token and redact standard password/key values. User-added files can contain arbitrary private data; review before sharing.
Restore preserves current network/identity config and token and keeps a dated safety copy of the original directory.

This is an unsigned open-source desktop build. It does not distribute Valve/Klei game files. Workshop covers remain
remote content with fallbacks. Application support directory and profile backups should stay in user-controlled storage.
