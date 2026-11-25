# Run against the newly built executable on a disposable Windows CI desktop.
param([Parameter(Mandatory=$true)][string]$Executable)
$ErrorActionPreference='Stop'
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WindowProbe {
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr w, IntPtr l);
}
"@
$exe=(Resolve-Path -LiteralPath $Executable).Path
$running=Get-Process -Name dst_server_launcher -ErrorAction SilentlyContinue
if ($running) { throw 'This test requires a desktop without a running launcher.' }
$launcher=Start-Process -FilePath $exe -PassThru -WindowStyle Hidden
try {
    $until=[DateTime]::UtcNow.AddSeconds(45)
    do {
        Start-Sleep -Milliseconds 250
        $launcher.Refresh()
        $hwnd=$launcher.MainWindowHandle
        if ($launcher.HasExited) { throw 'The launcher exited on startup.' }
    } until (($hwnd -ne [IntPtr]::Zero -and [WindowProbe]::IsWindowVisible($hwnd)) -or [DateTime]::UtcNow -gt $until)
    if ($hwnd -eq [IntPtr]::Zero -or ![WindowProbe]::IsWindowVisible($hwnd)) { throw 'No visible launcher window.' }
    # Allow the first Flutter frame to register the tray menu and close handler.
    Start-Sleep -Seconds 3
    if (![WindowProbe]::PostMessage($hwnd,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)) { throw 'Could not send WM_CLOSE.' }
    $until=[DateTime]::UtcNow.AddSeconds(12)
    while ([WindowProbe]::IsWindowVisible($hwnd) -and [DateTime]::UtcNow -lt $until) { Start-Sleep -Milliseconds 100 }
    if ($launcher.HasExited -or [WindowProbe]::IsWindowVisible($hwnd)) { throw 'Window did not hide while the launcher remained running.' }
    $shortcut=Start-Process -FilePath $exe -PassThru -WindowStyle Hidden
    if (!$shortcut.WaitForExit(10000)) {
        $shortcut.Kill()
        throw 'The second launch opened a separate process.'
    }
    $until=[DateTime]::UtcNow.AddSeconds(10)
    while (![WindowProbe]::IsWindowVisible($hwnd) -and [DateTime]::UtcNow -lt $until) { Start-Sleep -Milliseconds 100 }
    if ($launcher.HasExited -or ![WindowProbe]::IsWindowVisible($hwnd)) { throw 'The shortcut did not restore the same launcher window.' }
    'Closing hid the window. A second launch restored the original process.'
} finally {
    if (!$launcher.HasExited) { $launcher.Kill(); $launcher.WaitForExit() }
}
