$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..\..')
try {
  flutter pub get
  if ($LASTEXITCODE) { throw 'pub get failed' }
  flutter analyze
  if ($LASTEXITCODE) { throw 'Analysis failed' }
  flutter test
  if ($LASTEXITCODE) { throw 'Tests failed' }
  flutter build windows --release
  if ($LASTEXITCODE) { throw 'Build failed' }
  New-Item -ItemType Directory -Path dist -Force | Out-Null
  Copy-Item README.md,LICENSE,THIRD_PARTY_NOTICES.md build\windows\x64\runner\Release
  Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath dist\dst-server-launcher-windows-x64.zip -Force
} finally { Pop-Location }
