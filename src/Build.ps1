<#
.SYNOPSIS
    Build Script with Semantic Versioning
.DESCRIPTION
    Builds the installer with proper version management
.PARAMETER Version
    Override version (otherwise uses git tag or default)
#>

param(
    [string]$OutputPath = "..\dist\PeviitorSetup.ps1",
    [string]$Version = $null,
    [switch]$Verbose
)

# ============================================================================
# VERSION MANAGEMENT
# ============================================================================

function Get-ProjectVersion {
    param([string]$OverrideVersion)
    
    # If version is provided, use it
    if ($OverrideVersion) {
        return $OverrideVersion
    }
    
    # Try to get version from git tag
    try {
        $gitTag = git describe --tags --exact-match 2>$null
        if ($gitTag -match '^v?(\d+\.\d+\.\d+)') {
            return $matches[1]
        }
    } catch {
        # Git tag not available
    }
    
    # Try to get latest tag and increment
    try {
        $latestTag = git describe --tags --abbrev=0 2>$null
        if ($latestTag -match '^v?(\d+)\.(\d+)\.(\d+)') {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            $patch = [int]$matches[3]
            
            # Get commit count since last tag
            $commitCount = git rev-list --count "$latestTag..HEAD" 2>$null
            if ($commitCount -and [int]$commitCount -gt 0) {
                # Increment patch version for development builds
                $patch++
                return "$major.$minor.$patch-dev.$commitCount"
            }
            
            return "$major.$minor.$patch"
        }
    } catch {
        # No git tags available
    }
    
    # Default version for initial development
    return "0.1.0-dev"
}

function Get-BuildMetadata {
    $metadata = @{
        Version = Get-ProjectVersion $Version
        BuildDate = Get-Date
        GitCommit = ""
        GitBranch = ""
        BuildNumber = $env:GITHUB_RUN_NUMBER ?? "local"
    }
    
    # Get Git information if available
    try {
        $metadata.GitCommit = (git rev-parse --short HEAD 2>$null) ?? "unknown"
        $metadata.GitBranch = (git branch --show-current 2>$null) ?? "unknown"
    } catch {
        # Git not available
    }
    
    return $metadata
}

# ============================================================================
# BUILD PROCESS
# ============================================================================

$BuildInfo = Get-BuildMetadata

$ModuleOrder = @(
    "Core.psm1",
    "Prerequisites.psm1", 
    "UserInput.psm1",
    "Installation.psm1",
    "Environment.psm1",
    "Application.psm1"
)

Write-Host "=== PEVIITOR.RO BUILD SYSTEM ===" -ForegroundColor Cyan
Write-Host "Version: $($BuildInfo.Version)" -ForegroundColor Green
Write-Host "Build Date: $($BuildInfo.BuildDate)" -ForegroundColor Gray
Write-Host "Git Commit: $($BuildInfo.GitCommit)" -ForegroundColor Gray
Write-Host "Git Branch: $($BuildInfo.GitBranch)" -ForegroundColor Gray
Write-Host "Build Number: $($BuildInfo.BuildNumber)" -ForegroundColor Gray
Write-Host "Modules: $($ModuleOrder.Count)" -ForegroundColor Gray

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

# Build the combined script with version info
$combinedScript = @"
#Requires -Version 5.1

<#
.SYNOPSIS
    Peviitor.ro Local Development Environment Installer
.DESCRIPTION
    Complete setup script for peviitor.ro local development environment
.NOTES
    Version: $($BuildInfo.Version)
    Build Date: $($BuildInfo.BuildDate)
    Git Commit: $($BuildInfo.GitCommit)
    Build Number: $($BuildInfo.BuildNumber)
.LINK
    https://github.com/AlinVioreanu/local_environment
#>

# ============================================================================
# SCRIPT METADATA
# ============================================================================
`$ScriptVersion = "$($BuildInfo.Version)"
`$ScriptBuildDate = "$($BuildInfo.BuildDate)"
`$ScriptGitCommit = "$($BuildInfo.GitCommit)"
`$ScriptBuildNumber = "$($BuildInfo.BuildNumber)"

Write-Host "Peviitor.ro Installer v`$ScriptVersion" -ForegroundColor Cyan
Write-Host "Build: `$ScriptBuildNumber | Commit: `$ScriptGitCommit" -ForegroundColor Gray

param(
    [switch]`$SkipBrowser,
    [switch]`$Verbose,
    [switch]`$ShowVersion
)

if (`$ShowVersion) {
    Write-Host "Version: `$ScriptVersion"
    Write-Host "Build Date: `$ScriptBuildDate"
    Write-Host "Git Commit: `$ScriptGitCommit"
    Write-Host "Build Number: `$ScriptBuildNumber"
    exit 0
}

# Set strict mode and error handling
Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"
`$ProgressPreference = "Continue"

# Global variables
`$LogFile = "`$PSScriptRoot\peviitor-setup-`$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
`$StartTime = Get-Date
`$TotalSteps = 16
`$CurrentStep = 0
`$SolrUser = ""
`$SolrPassword = ""

"@

# Process modules (same as before)
foreach ($moduleName in $ModuleOrder) {
    $modulePath = ".\modules\$moduleName"
    
    if (Test-Path $modulePath) {
        Write-Host "Processing module: $moduleName" -ForegroundColor Green
        
        $moduleDisplayName = $moduleName -replace '\.psm1$', ''
        $combinedScript += "`n`n# ============================================================================`n"
        $combinedScript += "# MODULE: $moduleDisplayName`n"
        $combinedScript += "# ============================================================================`n`n"
        
        $moduleContent = Get-Content $modulePath -Raw -Encoding UTF8
        $moduleContent = $moduleContent -replace 'Export-ModuleMember[^\r\n]*[\r\n]*', ''
        $moduleContent = $moduleContent -replace '#Requires[^\r\n]*[\r\n]*', ''
        
        $combinedScript += $moduleContent
        
        if ($Verbose) {
            $lines = ($moduleContent -split "`n").Count
            Write-Host "  Added $lines lines from $moduleName" -ForegroundColor Gray
        }
    } else {
        Write-Warning "Module not found: $modulePath"
    }
}

# Add main execution flow with version logging
$combinedScript += @"

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

try {
    Write-Log "=== PEVIITOR.RO SETUP STARTED ===" "INFO"
    Write-Log "Installer Version: `$ScriptVersion" "INFO"
    Write-Log "Build Date: `$ScriptBuildDate" "INFO"
    Write-Log "Git Commit: `$ScriptGitCommit" "INFO"
    Write-Log "PowerShell Version: `$(`$PSVersionTable.PSVersion)" "INFO"
    Write-Log "OS: `$([Environment]::OSVersion.VersionString)" "INFO"
    Write-Log "User: `$env:USERNAME" "INFO"
    
    # Execute setup steps
    Test-Prerequisites
    Get-SolrCredentials
    Install-Git
    Install-Docker
    Initialize-Environment
    Deploy-Frontend
    Configure-API
    Deploy-ApacheContainer
    Deploy-SolrContainer
    Configure-SolrCores
    Configure-SolrAuthentication
    Configure-SolrUsers
    Install-JavaAndJMeter
    Test-Services
    Launch-Browser
    Show-CompletionSummary
    
    Write-Log "Setup completed successfully (v`$ScriptVersion)" "SUCCESS"
    Cleanup-OnSuccess
    
} catch {
    Write-ErrorLog "Script Execution" "Setup failed in version `$ScriptVersion" `$_
    Write-Host "`n❌ SETUP FAILED (Version: `$ScriptVersion)" -ForegroundColor Red
    exit 1
}
"@

# Write output with proper line endings
try {
    $combinedScript = $combinedScript -replace "`r`n", "`n" -replace "`n", "`r`n"
    Set-Content -Path $OutputPath -Value $combinedScript -Encoding UTF8
    
    # Generate hash
    $hash = Get-FileHash $OutputPath -Algorithm SHA256
    
    # Create enhanced verification file
    $verificationPath = Join-Path (Split-Path $OutputPath -Parent) "VERIFICATION.md"
    $verificationContent = @"
# PeviitorSetup.ps1 Verification

## Build Information
- **Version:** $($BuildInfo.Version)
- **Build Date:** $($BuildInfo.BuildDate)
- **Git Commit:** $($BuildInfo.GitCommit)
- **Git Branch:** $($BuildInfo.GitBranch)
- **Build Number:** $($BuildInfo.BuildNumber)

## File Information
- **File:** PeviitorSetup.ps1
- **Size:** $([math]::Round((Get-Item $OutputPath).Length / 1KB, 2)) KB
- **Lines:** $(($combinedScript -split "`n").Count)
- **SHA256:** $($hash.Hash)

## Verification
``````powershell
# Verify file integrity
Get-FileHash "PeviitorSetup.ps1" -Algorithm SHA256
# Expected: $($hash.Hash)

# Check version
.\PeviitorSetup.ps1 -ShowVersion
``````

## Modules Included
$($ModuleOrder | ForEach-Object { "- $_" } | Out-String)

## Usage
``````powershell
# Standard installation
.\PeviitorSetup.ps1

# Skip browser launch
.\PeviitorSetup.ps1 -SkipBrowser

# Verbose output
.\PeviitorSetup.ps1 -Verbose

# Show version info
.\PeviitorSetup.ps1 -ShowVersion
``````
"@
    
    Set-Content -Path $verificationPath -Value $verificationContent -Encoding UTF8
    
    # Build summary
    Write-Host "`n=== BUILD COMPLETED ===" -ForegroundColor Green
    Write-Host "Version: $($BuildInfo.Version)" -ForegroundColor Cyan
    Write-Host "Output: $OutputPath" -ForegroundColor White
    Write-Host "Hash: $($hash.Hash.Substring(0,16))..." -ForegroundColor Yellow
    Write-Host "Size: $([math]::Round((Get-Item $OutputPath).Length / 1KB, 2)) KB" -ForegroundColor White
    Write-Host "`n🚀 Ready for distribution!" -ForegroundColor Green
    
} catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
}
