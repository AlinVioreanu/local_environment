<#
.SYNOPSIS
    Prerequisites Module - System Validation and Requirements Check
.DESCRIPTION
    Validates system requirements before installation:
    - Admin privileges check
    - PowerShell version validation
    - Windows version check
    - Disk space verification
    - Port availability
    - Internet connectivity
#>

# ============================================================================
# PREREQUISITES VALIDATION FUNCTIONS
# ============================================================================

function Test-Prerequisites {
    Write-ProgressLog "Validating system prerequisites" 1
    
    Write-Log "Starting prerequisites validation..." "INFO"
    
    # Check Administrator privileges
    Write-Log "Checking administrator privileges..." "INFO"
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Log "Administrator privileges required but not found" "ERROR"
        throw "This script must be run as Administrator"
    }
    Write-Log "Administrator privileges confirmed" "SUCCESS"
    
    # Check PowerShell version
    Write-Log "Checking PowerShell version..." "INFO"
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell version $($PSVersionTable.PSVersion) is insufficient" "ERROR"
        throw "PowerShell 5.1 or higher is required"
    }
    Write-Log "PowerShell version $($PSVersionTable.PSVersion) is acceptable" "SUCCESS"
    
    # Check Windows version
    Write-Log "Checking Windows version..." "INFO"
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Write-Log "Windows version $([Environment]::OSVersion.VersionString) is not supported" "ERROR"
        throw "Windows 10 or higher is required"
    }
    Write-Log "Windows version $([Environment]::OSVersion.VersionString) is supported" "SUCCESS"
    
    # Check disk space
    Write-Log "Checking available disk space..." "INFO"
    try {
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -lt 5) {
            Write-Log "Insufficient disk space: ${freeSpaceGB} GB free (minimum 5 GB required)" "ERROR"
            throw "Insufficient disk space"
        }
        Write-Log "Disk space check passed: ${freeSpaceGB} GB available" "SUCCESS"
    } catch {
        Write-Log "Could not check disk space, continuing..." "WARN"
    }
    
    # Check required ports
    Write-Log "Checking port availability..." "INFO"
    $requiredPorts = @(8081, 8983)
    $portsInUse = @()
    
    foreach ($port in $requiredPorts) {
        try {
            $tcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
            $tcpListener.Start()
            $tcpListener.Stop()
            Write-Log "Port $port is available" "DEBUG"
        } catch {
            $portsInUse += $port
            Write-Log "Port $port appears to be in use" "WARN"
        }
    }
    
    if ($portsInUse.Count -gt 0) {
        Write-Log "Some required ports may be in use: $(($portsInUse) -join ', ')" "WARN"
        Write-Log "Setup will continue, but these ports will need to be available" "WARN"
    } else {
        Write-Log "All required ports are available" "SUCCESS"
    }
    
    # Check internet connectivity
    Write-Log "Checking internet connectivity..." "INFO"
    try {
        $testConnection = Test-NetConnection -ComputerName github.com -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($testConnection) {
            Write-Log "Internet connectivity confirmed" "SUCCESS"
        } else {
            Write-Log "Cannot reach GitHub - internet connection may be limited" "WARN"
        }
    } catch {
        Write-Log "Internet connectivity test failed, but continuing..." "WARN"
    }
    
    Write-Log "Prerequisites validation completed successfully" "SUCCESS"
}