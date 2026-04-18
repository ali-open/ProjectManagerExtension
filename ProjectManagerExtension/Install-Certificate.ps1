# Run this script as Administrator to install the certificate
$certPath = Join-Path $PSScriptRoot "ProjectManagerExtension_TemporaryKey.pfx"
$certPassword = ConvertTo-SecureString -String "TempPassword123" -Force -AsPlainText

# Import the certificate to the Trusted Root store
Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root -Password $certPassword

Write-Host "Certificate installed successfully to Trusted Root store!" -ForegroundColor Green
Write-Host "You can now install the MSIX package." -ForegroundColor Yellow
