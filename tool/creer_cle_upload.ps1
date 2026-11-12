param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$')]
    [string]$ApplicationId,
    [string]$DossierSignature = (Join-Path $env:USERPROFILE '.triathlon/signature')
)
$ErrorActionPreference = 'Stop'
if ($ApplicationId.StartsWith('com.example.')) { throw 'Choisir l applicationId definitif avant de creer la cle.' }
$dossierCle = Join-Path $DossierSignature $ApplicationId
$fichierCle = Join-Path $dossierCle 'upload-keystore.p12'
$fichierSecret = Join-Path $dossierCle 'upload-password.clixml'
if ((Test-Path $fichierCle) -or (Test-Path $fichierSecret)) {
    throw 'Une signature existe deja : aucune cle ni aucun mot de passe ne sera remplace.'
}
$javaSignature = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/keytool.exe' } else {
    'C:/Program Files/Android/Android Studio/jbr/bin/keytool.exe'
}
if (-not (Test-Path $javaSignature)) { throw 'Configurer JAVA_HOME vers le JDK Android Studio.' }
$null = New-Item -ItemType Directory -Path $dossierCle -Force
$sidSignature = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$null = & icacls.exe $dossierCle /inheritance:r /grant:r ("*${sidSignature}:(OI)(CI)F") 'SYSTEM:(OI)(CI)F'
if ($LASTEXITCODE -ne 0) { throw 'Impossible de restreindre les droits du dossier de signature.' }
$octetsSignature = New-Object byte[] 32
$generateurSignature = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$generateurSignature.GetBytes($octetsSignature)
$generateurSignature.Dispose()
$motDePasseSignature = [Convert]::ToBase64String($octetsSignature)
$secretSignature = ConvertTo-SecureString $motDePasseSignature -AsPlainText -Force
# DPAPI Windows : fichier utilisable seulement par ce compte sur ce poste.
$secretSignature | Export-Clixml -LiteralPath $fichierSecret
$ancienSecretSignature = $env:TRIATHLON_STORE_PASSWORD
try {
    $env:TRIATHLON_STORE_PASSWORD = $motDePasseSignature
    & $javaSignature -genkeypair -keystore $fichierCle -storetype PKCS12 -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=$ApplicationId Upload" -storepass:env TRIATHLON_STORE_PASSWORD -keypass:env TRIATHLON_STORE_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'La creation de la cle a echoue. Conserver les fichiers pour diagnostic ; ne pas ecraser une cle existante.' }
    Write-Output 'Cle upload creee hors du depot ; mot de passe chiffre par DPAPI. Aucun secret affiche.'
    Write-Output 'Avant publication : sauvegarder le keystore ET son mot de passe dans un coffre chiffre portable. DPAPI seul ne permet pas une restauration sur un autre poste.'
} finally {
    $env:TRIATHLON_STORE_PASSWORD = $ancienSecretSignature
    $motDePasseSignature = $null
    [Array]::Clear($octetsSignature,0,$octetsSignature.Length)
}
