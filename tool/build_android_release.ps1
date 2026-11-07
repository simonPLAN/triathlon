param(
    [ValidateSet('production','staging')][string]$Environnement = 'production',
    [Parameter(Mandatory=$true)][ValidateRange(1,2100000000)][int]$NumeroBuild,
    [string]$Configuration,
    [string]$DossierSignature = (Join-Path $env:USERPROFILE '.triathlon/signature')
)
$ErrorActionPreference = 'Stop'
$racineRelease = Split-Path $PSScriptRoot -Parent
if (-not $Configuration) { $Configuration = Join-Path $racineRelease "config/$Environnement.json" }
if (-not (Test-Path $Configuration)) { throw 'Copier le modele config correspondant, puis renseigner la configuration publique.' }
$configurationRelease = Get-Content -LiteralPath $Configuration -Raw | ConvertFrom-Json
$identiteRelease = @{}
foreach ($ligneRelease in [System.IO.File]::ReadAllLines((Join-Path $racineRelease 'android/application.properties'))) {
    if ($ligneRelease -match '^([^#=]+)=(.*)$') { $identiteRelease[$matches[1].Trim()] = $matches[2].Trim() }
}
if ($identiteRelease['identityConfirmed'] -ne 'true') { throw 'Confirmer le nom et l applicationId avant Release.' }
$nomAttendu = $identiteRelease['appName']
if ($Environnement -eq 'staging') { $nomAttendu += ' (test)' }
if ($configurationRelease.APP_ENV -ne $Environnement -or $configurationRelease.APP_NAME -ne $nomAttendu) {
    throw 'APP_ENV ou APP_NAME ne correspond pas a la variante.'
}
$nomsSignature = @('TRIATHLON_STORE_FILE','TRIATHLON_STORE_PASSWORD','TRIATHLON_KEY_ALIAS','TRIATHLON_KEY_PASSWORD')
$anciensParametres = @{}
foreach ($nomSignature in $nomsSignature) { $anciensParametres[$nomSignature] = [Environment]::GetEnvironmentVariable($nomSignature) }
$adresseSecret = [IntPtr]::Zero
try {
    # CI/coffre externe : si les quatre variables sont deja fournies, les conserver.
    $variablesCompletes = $true
    foreach ($nomSignature in $nomsSignature) {
        if (-not [Environment]::GetEnvironmentVariable($nomSignature)) { $variablesCompletes = $false }
    }
    if (-not $variablesCompletes) {
        $dossierCle = Join-Path $DossierSignature $identiteRelease['applicationId']
        $fichierSecret = Join-Path $dossierCle 'upload-password.clixml'
        $fichierCle = Join-Path $dossierCle 'upload-keystore.p12'
        if (-not (Test-Path $fichierSecret) -or -not (Test-Path $fichierCle)) {
            throw 'Cle upload absente : utiliser une cle existante ou creer une nouvelle signature pour une nouvelle application.'
        }
        $secretSignature = Import-Clixml -LiteralPath $fichierSecret
        $adresseSecret = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretSignature)
        $motDePasseSignature = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($adresseSecret)
        $env:TRIATHLON_STORE_FILE = $fichierCle
        $env:TRIATHLON_STORE_PASSWORD = $motDePasseSignature
        $env:TRIATHLON_KEY_ALIAS = 'upload'
        $env:TRIATHLON_KEY_PASSWORD = $motDePasseSignature
    }
    Push-Location $racineRelease
    try {
        & flutter build appbundle --release --flavor $Environnement "--build-number=$NumeroBuild" "--dart-define-from-file=$Configuration"
        if ($LASTEXITCODE -ne 0) { throw 'La generation du bundle Release a echoue.' }
    } finally { Pop-Location }
} finally {
    foreach ($nomSignature in $nomsSignature) {
        [Environment]::SetEnvironmentVariable($nomSignature,$anciensParametres[$nomSignature])
    }
    if ($adresseSecret -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($adresseSecret) }
    $motDePasseSignature = $null
}
