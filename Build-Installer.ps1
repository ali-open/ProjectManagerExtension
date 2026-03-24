# Build and Package PowerToys Command Palette Extension
# This script builds the MSIX package for distribution

param(
    [ValidateSet("x64", "ARM64")]
    [string]$Platform = "x64",

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "Building Project Manager Extension for PowerToys..." -ForegroundColor Cyan
Write-Host "Platform: $Platform" -ForegroundColor Gray
Write-Host "Configuration: $Configuration" -ForegroundColor Gray

# Set paths
$projectRoot = $PSScriptRoot
$projectFile = Join-Path $projectRoot "ProjectManagerExtension\ProjectManagerExtension.csproj"
$outputPath = Join-Path $projectRoot "Output"
$packagePath = Join-Path $projectRoot "ProjectManagerExtension\AppPackages"

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

# Step 1: Restore NuGet packages
Write-Host "
[1/3] Restoring NuGet packages..." -ForegroundColor Yellow
& $msbuild $projectFile /t:Restore /p:Configuration=$Configuration /p:Platform=$Platform /nologo /v:minimal

if ($LASTEXITCODE -ne 0) {
    Write-Error "Restore failed"
    exit 1
}

# Step 2: Build and package MSIX
Write-Host "
[2/3] Building and packaging MSIX..." -ForegroundColor Yellow
& $msbuild $projectFile `
    /p:Configuration=$Configuration `
    /p:Platform=$Platform `
    /p:AppxBundle=Never `
    /p:UapAppxPackageBuildMode=SideloadOnly `
    /p:AppxPackageSigningEnabled=false `
    /p:GenerateAppxPackageOnBuild=true `
    /nologo `
    /v:minimal

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Step 3: Copy to Output folder
Write-Host "
[3/3] Copying package to Output folder..." -ForegroundColor Yellow
$msixFile = Get-ChildItem -Path $packagePath -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($msixFile) {
    $destinationFile = Join-Path $outputPath "ProjectManagerExtension_$Platform.msix"
    Copy-Item $msixFile.FullName -Destination $destinationFile -Force

    Write-Host "
✓ Success!" -ForegroundColor Green
    Write-Host "MSIX package created at:" -ForegroundColor Cyan
    Write-Host $destinationFile -ForegroundColor White
    Write-Host "
To sign the package, run:" -ForegroundColor Yellow
    Write-Host "  .\Sign-Package.ps1 -PackagePath '$destinationFile'" -ForegroundColor Gray
} else {
    Write-Host "
⚠ Warning: Could not find generated MSIX package!" -ForegroundColor Yellow
    Write-Host "Expected location: $packagePath" -ForegroundColor Gray
    Write-Host "
Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure EnableMsixTooling is enabled in the .csproj" -ForegroundColor Gray
    Write-Host "2. Check that Microsoft.Windows.SDK.BuildTools.MSIX package is installed" -ForegroundColor Gray
    Write-Host "3. Try building with Visual Studio to verify MSIX generation works" -ForegroundColor Gray
    exit 1
}
