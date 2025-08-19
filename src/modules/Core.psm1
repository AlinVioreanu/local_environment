<#
.SYNOPSIS
    Core Module - Logging, Error Handling, Progress Tracking
.DESCRIPTION
    Contains all logging functions, error handling, and progress tracking utilities
    Used by all other modules for consistent logging and error reporting
#>

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file if it exists
    if ($global:LogFile -and $global:LogFile -ne "") {
        Add-Content -Path $global:LogFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    
    # Console output with colors
    switch ($Level) {
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { if ($global:Verbose) { Write-Host $logEntry -ForegroundColor Gray } }
        default   { Write-Host $logEntry -ForegroundColor White }
    }
}

function Write-ErrorLog {
    param(
        [string]$Step,
        [string]$ErrorMessage,
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    
    Write-Log "=== ERROR IN STEP: $Step ===" "ERROR"
    Write-Log "Error Message: $ErrorMessage" "ERROR"
    
    if ($ErrorRecord) {
        Write-Log "Exception Type: $($ErrorRecord.Exception.GetType().FullName)" "ERROR"
        Write-Log "Exception Details: $($ErrorRecord.Exception.Message)" "ERROR"
        Write-Log "Stack Trace: $($ErrorRecord.ScriptStackTrace)" "ERROR"
    }
    
    # System information for debugging
    Write-Log "=== SYSTEM INFORMATION ===" "ERROR"
    Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)" "ERROR"
    Write-Log "OS: $([Environment]::OSVersion.VersionString)" "ERROR"
    Write-Log "Username: $($env:USERNAME)" "ERROR"
    Write-Log "Current Directory: $(Get-Location)" "ERROR"
}

function Write-ProgressLog {
    param(
        [string]$Activity,
        [int]$Step
    )
    
    $global:CurrentStep = $Step
    $percent = [math]::Round(($Step / $global:TotalSteps) * 100)
    Write-Progress -Activity "Peviitor.ro Setup" -Status $Activity -PercentComplete $percent
    Write-Log "STEP $Step/$($global:TotalSteps) ($percent%): $Activity" "INFO"
}

function Cleanup-OnSuccess {
    Write-Log "Setup completed successfully!" "SUCCESS"
    
    # Show log file location even on success (for feedback)
    if ($global:LogFile -and (Test-Path $global:LogFile)) {
        Write-Host "`n📄 Installation log saved to:" -ForegroundColor Green
        Write-Host "$global:LogFile" -ForegroundColor Gray
        Write-Host "💡 Keep this file for troubleshooting if needed" -ForegroundColor Cyan
        
        # Ask if user wants to open log
        $openLog = Read-Host "`nOpen installation log in Notepad? (y/n)"
        if ($openLog -eq 'y' -or $openLog -eq 'Y') {
            try {
                Start-Process notepad.exe $global:LogFile
            } catch {
                Write-Host "Could not open Notepad automatically" -ForegroundColor Yellow
            }
        }
    }
}

function Show-ErrorLocation {
    Write-Host "`n❌ Setup failed. Error log saved to:" -ForegroundColor Red
    Write-Host $global:LogFile -ForegroundColor Yellow
    Write-Host "`n📋 TROUBLESHOOTING:" -ForegroundColor Cyan
    Write-Host "1. Send the log file above to support for assistance" -ForegroundColor White
    Write-Host "2. The log contains detailed error information" -ForegroundColor White
    Write-Host "3. No sensitive passwords are stored in the log" -ForegroundColor White
    
    # Try to open the log file automatically
    try {
        if (Test-Path $global:LogFile) {
            Write-Host "`n🗒️  Opening log file in Notepad..." -ForegroundColor Cyan
            Start-Process notepad.exe $global:LogFile -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "`n📝 You can open the log file manually with:" -ForegroundColor Gray
        Write-Host "notepad `"$global:LogFile`"" -ForegroundColor Gray
    }
}