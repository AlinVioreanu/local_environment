<#
.SYNOPSIS
    Build Script - Combines all modules into single distributable script
.DESCRIPTION
    Development utility that:
    - Reads all module files in correct order
    - Combines them into one script
    - Generates SHA256 hash for verification
    - Creates distribution package in dist/ folder
.EXAMPLE
    .\Build.ps1
    Builds PeviitorSetup.ps1 in ../dist/ folder
#>

param(
    [string]$OutputPath = "..\dist\PeviitorSetup.ps1",
    [switch]$Verbose
)

# Configuration
$ModuleOrder = @(
    "Core.psm1",           # Must be first (logging functions)
    "Prerequisites.psm1",  # Second (validation)
    "UserInput.psm1",      # Third (user interaction)
    "Installation.psm1",   # Fourth (software installation)
    "Environment.psm1",    # Fifth (environment setup)
    "Application.psm1"     # Last (application deployment)
)

$BuildInfo = @{
    BuildDate = Get-Date
    Version = "1.0.0"
    Modules = $ModuleOrder.Count
}

Write-Host "=== PEVIITOR.RO BUILD SCRIPT ===" -ForegroundColor Cyan
Write-Host "Building single script from modules..." -ForegroundColor White
Write-Host "Build Date: $($BuildInfo.BuildDate)" -ForegroundColor Gray
Write-Host "Modules to combine: $($BuildInfo.Modules)" -ForegroundColor Gray

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

# Start building the combined script
$combinedScript = @"
#Requires -Version 5.1
