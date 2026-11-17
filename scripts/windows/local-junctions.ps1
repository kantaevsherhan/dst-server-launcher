# Only needed on developer workstations where symlink creation is unavailable.
# No registry/security settings are changed. Not needed for packaged users.
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$plugins = Get-Content (Join-Path $root '.flutter-plugins-dependencies') -Raw | ConvertFrom-Json
foreach ($platform in @('windows','linux')) {
  $links = Join-Path $root "$platform\flutter\ephemeral\.plugin_symlinks"
  New-Item -ItemType Directory -Path $links -Force | Out-Null
  foreach ($plugin in $plugins.plugins.$platform) {
    $link = Join-Path $links $plugin.name
    if (!(Test-Path -LiteralPath $link)) { New-Item -ItemType Junction -Path $link -Target $plugin.path | Out-Null }
  }
}
