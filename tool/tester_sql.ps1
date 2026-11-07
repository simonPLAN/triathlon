$ErrorActionPreference = 'Stop'
$racineTests = Split-Path $PSScriptRoot -Parent
$outilsTests = Join-Path $racineTests '.outils-locaux'
$runtimeTests = Join-Path $outilsTests 'deno.exe'
if (-not (Test-Path $runtimeTests)) {
    $null = New-Item -ItemType Directory -Path $outilsTests -Force
    $archiveTests = Join-Path $outilsTests 'deno.zip'
    Invoke-WebRequest 'https://github.com/denoland/deno/releases/download/v2.5.6/deno-x86_64-pc-windows-msvc.zip' -OutFile $archiveTests
    Expand-Archive $archiveTests -DestinationPath $outilsTests -Force
}
$ancienCacheTests = $env:DENO_DIR
try {
    $env:DENO_DIR = Join-Path $outilsTests 'cache'
    Push-Location $racineTests
    try {
        & $runtimeTests test --allow-read --allow-env --allow-sys supabase/tests supabase/functions/supprimer-compte/handler_test.ts
        if ($LASTEXITCODE -ne 0) { throw 'Echec des tests serveur.' }
    } finally { Pop-Location }
} finally { $env:DENO_DIR = $ancienCacheTests }
