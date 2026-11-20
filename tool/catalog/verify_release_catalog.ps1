# Historical parameter names: PublicBinary is the disabled control. Since the
# default is now enabled, build that control with an explicit false define.
param(
    [string]$PublicBinary = 'build/catalog_release_verification/public/arm64-v8a/app.so',
    [string]$PrivateBinary = 'build/catalog_release_verification/private/arm64-v8a/app.so'
)

$ErrorActionPreference = 'Stop'
$catalogSnapshot = Get-Content -LiteralPath 'docs/catalog/c2/catalog_real_v2.review.json' -Raw -Encoding UTF8 | ConvertFrom-Json

function Find-CatalogIdentifiers([string]$BinaryPath) {
    $binaryBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $BinaryPath).Path)
    # Dart stores ASCII and two-byte strings. The private binary is the positive
    # control: absence in public is accepted only if every ID is found in private.
    $utf8Text = [System.Text.Encoding]::UTF8.GetString($binaryBytes)
    $utf16Text = [System.Text.Encoding]::Unicode.GetString($binaryBytes)
    return @($catalogSnapshot.balls | Where-Object {
        $utf8Text.Contains($_.id) -or $utf16Text.Contains($_.id)
    } | ForEach-Object { $_.id })
}

$publicIdentifiers = @(Find-CatalogIdentifiers $PublicBinary)
$privateIdentifiers = @(Find-CatalogIdentifiers $PrivateBinary)
if ($publicIdentifiers.Count -ne 0 -or $privateIdentifiers.Count -ne 28) {
    throw "Unexpected release data: public=$($publicIdentifiers.Count), private=$($privateIdentifiers.Count)"
}

[ordered]@{
    publicModelsFound = $publicIdentifiers.Count
    privateModelsFound = $privateIdentifiers.Count
    publicBinarySha256 = (Get-FileHash -LiteralPath $PublicBinary -Algorithm SHA256).Hash
    privateBinarySha256 = (Get-FileHash -LiteralPath $PrivateBinary -Algorithm SHA256).Hash
    architecture = 'android-arm64'
    apkGenerated = $false
} | ConvertTo-Json
