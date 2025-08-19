<#
.SYNOPSIS
    Build Script - PowerShell 5.1 Compatible Version
.DESCRIPTION
    Combines all modules into single distributable script
#>

param(
    [string]$OutputPath = "..\dist\PeviitorSetup.ps1",
    [string]$Version = "0.1.0",
    [switch]$Verbose
)

$BuildInfo = @{
    Version = $Version
    BuildDate = Get-Date
    Modules = 6
}

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
Write-Host "Modules: $($ModuleOrder.Count)" -ForegroundColor Gray

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

# Build the combined script
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
.LINK
    https://github.com/AlinVioreanu/local_environment
#>

Write-Host "Peviitor.ro Installer v$($BuildInfo.Version)" -ForegroundColor Cyan
Write-Host "Build Date: $($BuildInfo.BuildDate)" -ForegroundColor Gray

param(
    [switch]`$SkipBrowser,
    [switch]`$Verbose
)

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

# Process modules
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

# Add main execution flow
$combinedScript += @"

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

try {
    Write-Log "=== PEVIITOR.RO SETUP STARTED ===" "INFO"
    Write-Log "Installer Version: $($BuildInfo.Version)" "INFO"
    Write-Log "Build Date: $($BuildInfo.BuildDate)" "INFO"
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
    
    Write-Log "Setup completed successfully (v$($BuildInfo.Version))" "SUCCESS"
    Cleanup-OnSuccess
    
} catch {
    Write-ErrorLog "Script Execution" "Setup failed in version $($BuildInfo.Version)" `$_
    
    Write-Host "`n❌ SETUP FAILED (Version: $($BuildInfo.Version))" -ForegroundColor Red
    Write-Host "=================================================================" -ForegroundColor Red
    Show-ErrorLocation
    
    Write-Host "`n🔧 TROUBLESHOOTING STEPS:" -ForegroundColor Yellow
    Write-Host "1. Check if you're running as Administrator" -ForegroundColor Gray
    Write-Host "2. Ensure Docker Desktop is installed and running" -ForegroundColor Gray
    Write-Host "3. Check internet connectivity" -ForegroundColor Gray
    Write-Host "4. Send the log file above to support" -ForegroundColor Gray
    Write-Host "5. Try running the script again" -ForegroundColor Gray
    
    Write-Host "`n📧 Support: Include the log file when reporting issues" -ForegroundColor Cyan
    Read-Host "`nPress Enter to exit"
    exit 1
}
"@

# Write output
try {
    $combinedScript = $combinedScript -replace "`r`n", "`n" -replace "`n", "`r`n"
    Set-Content -Path $OutputPath -Value $combinedScript -Encoding UTF8
    
    # Generate hash
    $hash = Get-FileHash $OutputPath -Algorithm SHA256
    
    # Create verification file
    $verificationPath = Join-Path (Split-Path $OutputPath -Parent) "VERIFICATION.md"
    $verificationContent = @"
# PeviitorSetup.ps1 Verification

## Build Information
- **Version:** $($BuildInfo.Version)
- **Build Date:** $($BuildInfo.BuildDate)
- **Modules:** $($BuildInfo.Modules)

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
``````

## Usage
``````powershell
# Standard installation
.\PeviitorSetup.ps1

# Skip browser launch
.\PeviitorSetup.ps1 -SkipBrowser

# Verbose output
.\PeviitorSetup.ps1 -Verbose
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