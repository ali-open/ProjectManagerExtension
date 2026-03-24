# Create a self-signed certificate for signing the MSIX package

param(
    [string]$CertificatePassword = "YourPasswordHere",
    [string]$PublisherName = "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
)

$ErrorActionPreference = "Stop"

Write-Host "Creating self-signed certificate for MSIX signing..." -ForegroundColor Cyan

# Create Output directory if it doesn't exist
$outputDir = Join-Path $PSScriptRoot "Output"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$certPath = Join-Path $outputDir "ProjectManagerExtension.pfx"
$cerPath = Join-Path $outputDir "ProjectManagerExtension.cer"

# Create certificate
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject $PublisherName `
    -KeyUsage DigitalSignature `
    -FriendlyName "Project Manager Extension" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

$thumbprint = $cert.Thumbprint
Write-Host "Certificate created with thumbprint: $thumbprint" -ForegroundColor Green

# Export to PFX (for signing)
$pwd = ConvertTo-SecureString -String $CertificatePassword -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$thumbprint" -FilePath $certPath -Password $pwd | Out-Null
Write-Host "PFX exported to: $certPath" -ForegroundColor Green

# Export to CER (for team members to install)
Export-Certificate -Cert "Cert:\CurrentUser\My\$thumbprint" -FilePath $cerPath | Out-Null
Write-Host "CER exported to: $cerPath" -ForegroundColor Green

Write-Host "
✓ Certificate created successfully!" -ForegroundColor Green
Write-Host "
Distribute the CER file to team members for installation" -ForegroundColor Yellow
