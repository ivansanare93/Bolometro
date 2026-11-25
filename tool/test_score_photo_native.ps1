param(
  [Parameter(Mandatory=$true)][string]$ImagePath,
  [Parameter(Mandatory=$true)][ValidatePattern('^emulator-[0-9]+$')][string]$EmulatorSerial,
  [Parameter(Mandatory=$true)][string]$LayoutConfig,
  [string]$ReferenceFile
)
# This helper is deliberately restricted to an emulator: never a physical phone.
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fixture = Join-Path $repoRoot 'integration_test/support/score_photo_private_input.dart'
$original = [System.IO.File]::ReadAllBytes($fixture)
$photo = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $ImagePath).Path)
$inputHash = (Get-FileHash -LiteralPath $ImagePath -Algorithm SHA256).Hash.ToLowerInvariant()
$reference = $null
if ($ReferenceFile) {
  $reference = Get-Content -LiteralPath $ReferenceFile -Raw | ConvertFrom-Json
  if ($reference.image_sha256 -ne $inputHash -or $reference.id -notmatch '^[a-zA-Z0-9_-]+$') {
    throw 'Reference/image identity mismatch or invalid reference ID'
  }
}
$encoded = [Convert]::ToBase64String($photo)
$fixtureSource = "const scorePhotoTestBase64 = '$encoded';"
$testExit = 1
Push-Location $repoRoot
try {
  [System.IO.File]::WriteAllText($fixture, $fixtureSource, [System.Text.UTF8Encoding]::new($false))
  New-Item -ItemType Directory -Path (Join-Path $repoRoot 'build') -Force | Out-Null
  $nativeLog = Join-Path $repoRoot 'build/score_photo_native_evaluation.log'
  $testArguments = @('test', 'integration_test/score_photo_native_test.dart', '-d', $EmulatorSerial,
    '--no-pub', "--dart-define-from-file=$LayoutConfig", "--dart-define=SCORE_PHOTO_INPUT_SHA256=$inputHash", '--reporter', 'expanded')
  if ($reference) { $testArguments += "--dart-define=SCORE_PHOTO_REFERENCE_ID=$($reference.id)" }
  & flutter @testArguments | Tee-Object -FilePath $nativeLog
  $testExit = $LASTEXITCODE
  if ($reference -and $testExit -eq 0) {
    $reports = @(Select-String -LiteralPath $nativeLog -Pattern 'PHOTO_OCR_PROPOSAL:(\{.*\})')
    if ($reports.Count -ne 1) { throw 'Expected one completed native proposal report' }
    $proposal = $reports[0].Matches[0].Groups[1].Value | ConvertFrom-Json
    $mode = if ($proposal.preprocessing -eq 'perspective') { 'perspective' } else { 'original' }
    $predictionPath = Join-Path $repoRoot "build/score_photo_$($inputHash.Substring(0,12))_$mode.prediction.json"
    [IO.File]::WriteAllText($predictionPath, ($proposal | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    Write-Output "Prediction saved: $predictionPath"
  }
}
finally {
  # Do not retain private image bytes in source files after the local test.
  [System.IO.File]::WriteAllBytes($fixture, $original)
  Pop-Location
}
exit $testExit