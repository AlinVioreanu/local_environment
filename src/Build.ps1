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

<#
.SYNOPSIS
    Peviitor.ro Local Development Environment Installer
.DESCRIPTION
    Complete setup script for peviitor.ro local development environment including:
    - Prerequisites validation and system checks
    - Docker containers (Apache, Solr)
    - Frontend build deployment
    - API configuration
    - Search engine setup with authentication
    - JMeter installation and data migration
.NOTES
    Auto-generated from modules on $($BuildInfo.BuildDate)
    Source modules: $($BuildInfo.Modules)
    Build version: $($BuildInfo.Version)
.LINK
    https://github.com/AlinVioreanu/local_environment
#>

# ============================================================================
# COMBINED SCRIPT - AUTO-GENERATED FROM MODULES
# Build Date: $($BuildInfo.BuildDate)
# Build Version: $($BuildInfo.Version)
# Modules Combined: $($BuildInfo.Modules)
# ============================================================================

param(
    [switch]`$SkipBrowser,
    [switch]`$Verbose
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"
`$ProgressPreference = "Continue"

# Global variables for the combined script
`$LogFile = "`$PSScriptRoot\peviitor-setup-`$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
`$StartTime = Get-Date
`$TotalSteps = 16
`$CurrentStep = 0
`$SolrUser = ""
`$SolrPassword = ""

"@

# Process each module in order
foreach ($moduleName in $ModuleOrder) {
    $modulePath = ".\modules\$moduleName"
    
    if (Test-Path $modulePath) {
        Write-Host "Processing module: $moduleName" -ForegroundColor Green
        
        # Add module header
        $moduleDisplayName = $moduleName -replace '\.psm1$', ''
        $combinedScript += "`n`n# ============================================================================`n"
        $combinedScript += "# MODULE: $moduleDisplayName`n"
        $combinedScript += "# Source: $moduleName`n"
        $combinedScript += "# ============================================================================`n`n"
        
        # Read and process module content
        $moduleContent = Get-Content $modulePath -Raw -Encoding UTF8
        
        # Remove module-specific exports and headers that aren't needed in combined script
        $moduleContent = $moduleContent -replace 'Export-ModuleMember[^\r\n]*[\r\n]*', ''
        $moduleContent = $moduleContent -replace '#Requires[^\r\n]*[\r\n]*', ''
        
        # Add processed content
        $combinedScript += $moduleContent
        
        if ($Verbose) {
            $lines = ($moduleContent -split "`n").Count
            Write-Host "  Added $lines lines from $moduleName" -ForegroundColor Gray
        }
    } else {
        Write-Warning "Module not found: $modulePath"
        Write-Host "  Skipping $moduleName" -ForegroundColor Yellow
    }
}

# Add the main execution flow
$combinedScript += @"

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

try {
    # Initialize logging
    Write-Log "=== PEVIITOR.RO SETUP STARTED ===" "INFO"
    Write-Log "Build Version: $($BuildInfo.Version)" "INFO"
    Write-Log "Build Date: $($BuildInfo.BuildDate)" "INFO"
    Write-Log "PowerShell Version: `$(`$PSVersionTable.PSVersion)" "INFO"
    Write-Log "OS: `$([Environment]::OSVersion.VersionString)" "INFO"
    Write-Log "User: `$env:USERNAME" "INFO"
    Write-Log "Script Location: `$PSScriptRoot" "INFO"
    
    # Execute all setup steps in order
    Test-Prerequisites          # Step 1: System validation
    Get-SolrCredentials        # Step 2: User input
    Install-Git                # Step 3: Git installation
    Install-Docker             # Step 4: Docker installation  
    Initialize-Environment     # Step 5: Environment setup
    Deploy-Frontend            # Step 6: Frontend deployment
    Configure-API              # Step 7: API configuration
    Deploy-ApacheContainer     # Step 8: Apache container
    Deploy-SolrContainer       # Step 9: Solr container
    Configure-SolrCores        # Step 10: Solr cores
    Configure-SolrAuthentication # Step 11: Solr auth
    Configure-SolrUsers        # Step 12: Solr users
    Install-JavaAndJMeter      # Step 13: Java/JMeter
    Test-Services              # Step 14: Service verification
    Launch-Browser             # Step 15: Browser launch
    Show-CompletionSummary     # Step 16: Completion
    
    # Success cleanup
    Write-Log "Setup completed successfully" "SUCCESS"
    Cleanup-OnSuccess
    
} catch {
    # Error handling
    Write-Progress -Activity "Peviitor.ro Setup" -Completed
    Write-ErrorLog "Script Execution" "Unhandled error occurred" `$_
    
    Write-Host "`n❌ SETUP FAILED" -ForegroundColor Red
    Write-Host "Error log saved to: `$LogFile" -ForegroundColor Yellow
    Write-Host "Please send this log file for support assistance." -ForegroundColor Cyan
    
    Write-Host "`nTROUBLESHOOTING STEPS:" -ForegroundColor Yellow
    Write-Host "1. Check if Docker Desktop is running" -ForegroundColor Gray
    Write-Host "2. Ensure you have administrator privileges" -ForegroundColor Gray  
    Write-Host "3. Check internet connectivity" -ForegroundColor Gray
    Write-Host "4. Try running the script again" -ForegroundColor Gray
    Write-Host "5. If problems persist, send the log file for support" -ForegroundColor Gray
    
    Read-Host "`nPress Enter to exit"
    exit 1
}
"@

# Write the combined script to output file
try {
    # Ensure Windows line endings (CRLF) for consistency
    $combinedScript = $combinedScript -replace "`r`n", "`n" -replace "`n", "`r`n"
    
    Set-Content -Path $OutputPath -Value $combinedScript -Encoding UTF8
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "Output file: $OutputPath" -ForegroundColor White
    
    # Generate verification hash
    $hash = Get-FileHash $OutputPath -Algorithm SHA256
    Write-Host "SHA256 Hash: $($hash.Hash)" -ForegroundColor Yellow
    
    # Create verification documentation
    $verificationPath = Join-Path (Split-Path $OutputPath -Parent) "VERIFICATION.md"
    $verificationContent = @"
# PeviitorSetup.ps1 Verification

**File:** PeviitorSetup.ps1  
**Build Date:** $($BuildInfo.BuildDate)  
**Build Version:** $($BuildInfo.Version)  
**Modules Combined:** $($BuildInfo.Modules)  
**SHA256 Hash:** $($hash.Hash)

## Verify Download Integrity:

``````powershell
Get-FileHash "PeviitorSetup.ps1" -Algorithm SHA256
# Expected: $($hash.Hash)
``````

## Build Information:
- **Source Modules:** $($ModuleOrder -join ', ')
- **Build Date:** $($BuildInfo.BuildDate)
- **Total Lines:** $(($combinedScript -split "`n").Count)

## Usage:
1. Verify the hash matches the expected value above
2. Right-click PeviitorSetup.ps1 → "Run with PowerShell"
3. Or run from PowerShell as Administrator: ``.\PeviitorSetup.ps1``
"@
    
    Set-Content -Path $verificationPath -Value $verificationContent -Encoding UTF8
    Write-Host "✅ Verification file created: $verificationPath" -ForegroundColor Green
    
    # Build summary
    $scriptLines = ($combinedScript -split "`n").Count
    $fileSize = [math]::Round((Get-Item $OutputPath).Length / 1KB, 2)
    
    Write-Host "`n=== BUILD SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Modules processed: $($BuildInfo.Modules)" -ForegroundColor White
    Write-Host "Total lines: $scriptLines" -ForegroundColor White  
    Write-Host "File size: ${fileSize} KB" -ForegroundColor White
    Write-Host "Build version: $($BuildInfo.Version)" -ForegroundColor White
    Write-Host "`nReady for distribution! 🚀" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to write output file: $($_.Exception.Message)"
    exit 1
}
