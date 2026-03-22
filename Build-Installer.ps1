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
$packagePath = Join-Path $projectRoot "ProjectManagerExtension\bin\$Platform\$Configuration\net9.0-windows10.0.26100.0\win-$($Platform.ToLower())\AppPackages"

# Create output directory
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Step 1: Restore NuGet packages
Write-Host "
[1/4] Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore $projectFile

# Step 2: Build the project
Write-Host "
[2/4] Building project..." -ForegroundColor Yellow
dotnet build $projectFile `
    -c $Configuration `
    -p:Platform=$Platform `
    -p:AppxBundle=Never `
    -p:UapAppxPackageBuildMode=SideloadOnly

# Step 3: Create MSIX package
Write-Host "
[3/4] Creating MSIX package..." -ForegroundColor Yellow
dotnet publish $projectFile `
    -c $Configuration `
    -p:Platform=$Platform `
    -p:GenerateAppxPackageOnBuild=true `
    -p:AppxPackageSigningEnabled=false

# Step 4: Copy to Output folder
Write-Host "
[4/4] Copying package to Output folder..." -ForegroundColor Yellow
$msixFile = Get-ChildItem -Path $packagePath -Filter "*.msix" -Recurse | Select-Object -First 1

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
    Write-Error "Could not find generated MSIX package!"
}
