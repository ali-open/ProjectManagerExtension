# Build Multi-Architecture MSIX Bundle
# This script builds both x64 and ARM64 packages and bundles them together

param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "Building Multi-Architecture MSIX Bundle..." -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Gray

# Set paths
$projectRoot = $PSScriptRoot
$projectFile = Join-Path $projectRoot "ProjectManagerExtension\ProjectManagerExtension.csproj"
$outputPath = Join-Path $projectRoot "Output"

# Create output directory
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Find MSBuild
$msbuild = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
    -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe `
    -prerelease | Select-Object -First 1

if (!$msbuild) {
    Write-Error "MSBuild not found. Please install Visual Studio 2022 or Build Tools."
    exit 1
}

Write-Host "Using MSBuild: $msbuild" -ForegroundColor Gray

# Build both architectures
$platforms = @("x64", "ARM64")
$msixFiles = @()

foreach ($platform in $platforms) {
    Write-Host "
[Building $platform]" -ForegroundColor Yellow

    # Restore
    Write-Host "  Restoring packages..." -ForegroundColor Gray
    & $msbuild $projectFile /t:Restore /p:Configuration=$Configuration /p:Platform=$platform /nologo /v:q

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Restore failed for $platform"
        exit 1
    }

    # Build
    Write-Host "  Building and packaging..." -ForegroundColor Gray
    & $msbuild $projectFile `
        /p:Configuration=$Configuration `
        /p:Platform=$platform `
        /p:AppxBundle=Never `
        /p:UapAppxPackageBuildMode=SideloadOnly `
        /p:AppxPackageSigningEnabled=false `
        /p:GenerateAppxPackageOnBuild=true `
        /nologo `
        /v:q

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed for $platform"
        exit 1
    }

    Write-Host "  ✓ $platform package created" -ForegroundColor Green
}

# Find MakeAppx.exe for bundling
Write-Host "
[Creating Bundle]" -ForegroundColor Yellow
$makeappx = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\makeappx.exe" |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (!$makeappx) {
    Write-Error "makeappx.exe not found. Install Windows SDK."
    exit 1
}

# Collect MSIX files
$packagePath = Join-Path $projectRoot "ProjectManagerExtension\AppPackages"
$x64Msix = Get-ChildItem -Path $packagePath -Filter "*_x64.msix" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$arm64Msix = Get-ChildItem -Path $packagePath -Filter "*_ARM64.msix" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (!$x64Msix -or !$arm64Msix) {
    Write-Error "Could not find both architecture packages"
    exit 1
}

# Create temporary directory for bundling
$tempBundleDir = Join-Path $outputPath "TempBundle"
if (Test-Path $tempBundleDir) {
    Remove-Item $tempBundleDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempBundleDir | Out-Null

# Copy packages to temp directory
Copy-Item $x64Msix.FullName -Destination $tempBundleDir
Copy-Item $arm64Msix.FullName -Destination $tempBundleDir

# Create bundle
$bundleFile = Join-Path $outputPath "ProjectManagerExtension.msixbundle"
Write-Host "Creating bundle: $bundleFile" -ForegroundColor Gray
& $makeappx.FullName bundle /d $tempBundleDir /p $bundleFile /o

if ($LASTEXITCODE -eq 0) {
    # Cleanup
    Remove-Item $tempBundleDir -Recurse -Force

    Write-Host "
✓ Success!" -ForegroundColor Green
    Write-Host "MSIX Bundle created at:" -ForegroundColor Cyan
    Write-Host $bundleFile -ForegroundColor White
    Write-Host "
To sign the bundle, run:" -ForegroundColor Yellow
    Write-Host "  .\Sign-Package.ps1 -PackagePath '$bundleFile'" -ForegroundColor Gray
    Write-Host "
This bundle contains both x64 and ARM64 packages." -ForegroundColor Cyan
    Write-Host "Windows will automatically install the correct architecture." -ForegroundColor Cyan
} else {
    # Cleanup on failure
    if (Test-Path $tempBundleDir) {
        Remove-Item $tempBundleDir -Recurse -Force
    }
    Write-Error "Bundle creation failed"
    exit 1
}
