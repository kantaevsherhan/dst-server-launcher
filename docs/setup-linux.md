# Linux x64: Debian, Ubuntu, Mint, Manjaro, Fedora

## Linux Server over SSH

Download the standalone installer on the target x86_64 host:

```bash
curl -fL https://github.com/kantaevsherhan/dst-server-launcher/releases/download/v0.2.1/install-dst-server.sh -o install-dst-server.sh
bash install-dst-server.sh --deps
# Install the printed dependencies as needed, then run as your regular user:
bash install-dst-server.sh
```

For an existing world, transfer its complete stopped cluster privately, including cluster_token.txt and both shard folders. Start each shard in a separate terminal or tmux session, substituting your own cluster path:

```bash
bash install-dst-server.sh --start-shard "$HOME/.klei/DoNotStarveTogether/MyCluster" Master
bash install-dst-server.sh --start-shard "$HOME/.klei/DoNotStarveTogether/MyCluster" Caves
```

The script uses anonymous SteamCMD and defaults to `$HOME/games/dst-dedicated`. It runs over SSH without a desktop environment.

## Desktop routes


**Steam Client**: install your distribution's official Steam package, enable the Library → Tools filter and install
Dedicated Server 343050. The launcher opens the same Steam URI as Windows. It detects standard `~/.steam/steam`
and `~/.local/share/Steam` libraries; choose a custom folder if needed. Sandboxed Flatpak libraries may require
manual directory selection and host filesystem access. Do not run the launcher as root.

**SteamCMD**: the installation screen identifies `/etc/os-release`, offers distro selection, copyable dependency
commands, a per-user official Valve SteamCMD downloader, and an exportable install.sh. The generated script never
executes sudo: prerequisite commands are comments and must be run separately by the user. SteamCMD then runs
`+force_install_dir <quoted absolute path> +login anonymous +app_update 343050 validate +quit`.
On a Linux desktop, select **Install here with SteamCMD** to start the installation.

| Distribution | Dependency instructions offered |
|---|---|
| Ubuntu 22.04+ | dpkg i386; apt lib32gcc-s1 lib32stdc++6 libcurl4:i386 curl ca-certificates tar |
| Linux Mint 21+ | Same Ubuntu-family instructions |
| Debian 12+ | Same Debian-family instructions; ensure i386 repositories are enabled |
| Manjaro x64 | Enable multilib, pacman lib32-gcc-libs lib32-libcurl curl tar gzip |
| Fedora x64 | dnf glibc.i686 libstdc++.i686 libcurl.i686 curl tar gzip |

Package names/repository availability may vary by distribution release. The exported script runs `ldd` on the official
server binary so missing shared libraries can be identified; the output must be reviewed. SteamCMD's 32-bit bootstrap
and the x64 DST server have different library requirements. Missing packages must be installed through the distro's
own package manager. Do not copy random shared libraries from blogs.

SteamCMD archive source: `https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz`.
Existing SteamCMD is used when available; otherwise it lives in `~/.local/share/dst-launcher/steamcmd`.
The selected server directory can contain spaces or Cyrillic: shell arguments are strictly quoted.

Launcher archive: built on Ubuntu 22.04, glibc ≥2.35, GTK 3 required. It is a native x64 tar.gz, not an AppImage.
On other Linux systems install the equivalents of GTK 3, libstdc++ and X11. Wayland behavior depends on the
desktop's compatibility layer/window-manager support. Source builds are available if the binary baseline is unsuitable.

Build tools: clang, cmake, ninja, pkg-config, GTK3 development files, lzma, X11 and Xi headers. Use your distro's
package names, then `flutter build linux --release`. Only Windows and Linux platform runners are included.

Background: GUI can stay minimized. No systemd units, linger or automatic startup is installed in v0.1.
The server exits when its GUI parent dies; no persistence through logoff or reboot is promised.

References: [Valve SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD),
[Klei command-line reference](https://support.klei.com/hc/en-us/articles/360029556192-Dedicated-Server-Command-Line-Options-Guide),
[Ubuntu SteamCMD package](https://packages.ubuntu.com/search?keywords=steamcmd),
[Debian SteamCMD package](https://packages.debian.org/search?keywords=steamcmd),
[Arch Steam troubleshooting](https://wiki.archlinux.org/title/Steam),
[Fedora Steam guidance](https://docs.fedoraproject.org/en-US/gaming/proton/).

Building on Ubuntu is covered by CI; live game behavior on all five distro families remains a manual verification task.
