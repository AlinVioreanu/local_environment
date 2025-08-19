<#
.SYNOPSIS
    User Input Module - Credential Collection and Validation
.DESCRIPTION
    Handles user interaction for:
    - Solr username/password collection
    - Password policy validation
    - User confirmation prompts
    - Input sanitization
#>

# ============================================================================
# USER INPUT FUNCTIONS
# ============================================================================

function Get-SolrCredentials {
    Write-ProgressLog "Collecting Solr credentials" 2
    
    Write-Host "`n=================================================================" -ForegroundColor Cyan
    Write-Host "================= LOCAL ENVIRONMENT INSTALLER =================" -ForegroundColor Cyan
    Write-Host "====================== PEVIITOR.RO ============================" -ForegroundColor Cyan  
    Write-Host "=================================================================" -ForegroundColor Cyan
    
    # Get username with validation
    do {
        $global:SolrUser = Read-Host "`nEnter the Solr username (minimum 3 characters)"
        if ([string]::IsNullOrWhiteSpace($global:SolrUser) -or $global:SolrUser.Length -lt 3) {
            Write-Host "Username must be at least 3 characters long. Please try again." -ForegroundColor Yellow
        }
    } while ([string]::IsNullOrWhiteSpace($global:SolrUser) -or $global:SolrUser.Length -lt 3)
    
    Write-Log "Solr username collected: $($global:SolrUser)" "DEBUG"
    
    # Password validation function
    function Test-PasswordPolicy {
        param([string]$Password)
        
        # Primary rule: length >= 15
        if ($Password.Length -ge 15) {
            return @{ IsValid = $true; Message = "Password meets length requirement (15+ characters)" }
        }
        
        # Alternative rule: complex password with minimum 8 characters
        if ($Password.Length -lt 8) {
            return @{ IsValid = $false; Message = "Password must be at least 8 characters long" }
        }
        
        $hasLower = $Password -cmatch '[a-z]'
        $hasUpper = $Password -cmatch '[A-Z]'
        $hasDigit = $Password -match '\d'
        $hasSpecial = $Password -match '[!@#$%^&*_\-\[\]()]'
        
        $complexity = @($hasLower, $hasUpper, $hasDigit, $hasSpecial) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
        
        if ($complexity -ge 3) {
            return @{ IsValid = $true; Message = "Password meets complexity requirements" }
        }
        
        return @{ IsValid = $false; Message = "Password must contain at least 3 of: lowercase, uppercase, digit, special character" }
    }
    
    # Get password with enhanced validation
    do {
        $securePassword = Read-Host "Enter the Solr password" -AsSecureString
        $global:SolrPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        
        $validation = Test-PasswordPolicy $global:SolrPassword
        if ($validation.IsValid) {
            Write-Host $validation.Message -ForegroundColor Green
            Write-Log "Password validation successful: $($validation.Message)" "DEBUG"
            break
        } else {
            Write-Host $validation.Message -ForegroundColor Yellow
            Write-Host "Password requirements: 15+ characters OR 8+ characters with 3 of: lowercase, uppercase, digit, special character (!@#`$%^&*_-[]())" -ForegroundColor Gray
            Write-Log "Password validation failed: $($validation.Message)" "DEBUG"
        }
    } while ($true)
    
    Write-Host "`n================================================================="
    Write-Host "===================== CREDENTIALS CONFIRMED ==================="
    Write-Host "================================================================="
    Write-Host "Username: $($global:SolrUser)" -ForegroundColor Green
    Write-Host "Password: $('*' * $global:SolrPassword.Length)" -ForegroundColor Green
    Write-Host "================================================================="
}