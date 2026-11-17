#define AppName "DST Server Launcher"
[Setup]
AppId={{2A7434B9-33AA-47EC-B1E3-3FAE783A5660}
AppName={#AppName}
AppVersion=0.1.0
AppPublisher=DST Server Launcher contributors
DefaultDirName={localappdata}\Programs\DST Server Launcher
DefaultGroupName={#AppName}
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=dst-server-launcher-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\dst_server_launcher.exe
LicenseFile=..\..\LICENSE
[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; Flags: unchecked
[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\dst_server_launcher.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\dst_server_launcher.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\dst_server_launcher.exe"; Description: "Open DST Server Launcher"; Flags: nowait postinstall skipifsilent
