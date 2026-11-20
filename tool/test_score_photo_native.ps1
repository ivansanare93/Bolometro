param(
  [Parameter(Mandatory=$true)][string]$ImagePath,
  [Parameter(Mandatory=$true)][ValidatePattern('^emulator-[0-9]+$')][string]$EmulatorSerial,
  [Parameter(Mandatory=$true)][string]$LayoutConfig
)
# This helper is deliberately restricted to an emulator: never a physical phone.
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fixture = Join-Path $repoRoot 'integration_test/support/score_photo_private_input.dart'
$original = [System.IO.File]::ReadAllBytes($fixture)
$photo = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $ImagePath).Path)
$encoded = [Convert]::ToBase64String($photo)
$fixtureSource = "const scorePhotoTestBase64 = '$encoded';"
$testExit = 1
Push-Location $repoRoot
try {
  [System.IO.File]::WriteAllText($fixture, $fixtureSource, [System.Text.UTF8Encoding]::new($false))
  & flutter test integration_test/score_photo_native_test.dart -d $EmulatorSerial --no-pub "--dart-define-from-file=$LayoutConfig" --reporter expanded
  $testExit = $LASTEXITCODE
}
finally {
  # Do not retain private image bytes in source files after the local test.
  [System.IO.File]::WriteAllBytes($fixture, $original)
  Pop-Location
}
exit $testExit