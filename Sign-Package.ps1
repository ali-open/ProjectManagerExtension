# Sign the MSIX package with a certificate

param(
    [Parameter(Mandatory=$true)]
    [string]$PackagePath,

    [string]$CertificatePath = (Join-Path $PSScriptRoot "Output\ProjectManagerExtension.pfx"),

    [string]$Password = "YourPasswordHere"
)

$ErrorActionPreference = "Stop"

Write-Host "Signing MSIX package..." -ForegroundColor Cyan

if (!(Test-Path $PackagePath)) {
    Write-Error "Package not found: $PackagePath"
    exit 1
}

if (!(Test-Path $CertificatePath)) {
    Write-Error "Certificate not found. Run .\Create-Certificate.ps1 first"
    exit 1
}

# Find signtool.exe
$signtool = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe" |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (!$signtool) {
    Write-Error "signtool.exe not found. Install Windows SDK."
    exit 1
}

& $signtool.FullName sign /fd SHA256 /a /f $CertificatePath /p $Password $PackagePath

if ($LASTEXITCODE -eq 0) {
    Write-Host "
✓ Package signed successfully!" -ForegroundColor Green
}
