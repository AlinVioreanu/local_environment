# Build Process Documentation

## Overview
The build system combines individual PowerShell modules into a single distributable script while maintaining code organization during development.

## Folder Structure Purpose

### Development Structure (`src/`)
```
src/
├── modules/              # Individual modules for organized development
│   ├── Core.psm1        # Logging, error handling (MUST BE FIRST)
│   ├── Prerequisites.psm1 # System validation
│   ├── UserInput.psm1   # User input and validation  
│   ├── Installation.psm1 # Software installation (Git, Docker, Java)
│   ├── Environment.psm1 # Docker environment setup
│   └── Application.psm1 # Application deployment (Solr, Apache, API)
├── Build.ps1           # Combines modules into single script
└── Main.ps1            # Development version using modules
```

### Distribution Structure (`dist/`)
```
dist/
├── PeviitorSetup.ps1   # Single combined script (auto-generated)
├── VERIFICATION.md     # SHA256 hash and verification info
└── README.md          # Distribution information
```

## Build Process Steps

### 1. Module Order (Critical)
Modules are combined in specific order:
1. **Core.psm1** - Must be first (contains logging functions used by others)
2. **Prerequisites.psm1** - System validation
3. **UserInput.psm1** - User interaction
4. **Installation.psm1** - Software installation
5. **Environment.psm1** - Environment setup  
6. **Application.psm1** - Application deployment

### 2. Build Script Operation
```powershell
# Run from src/ directory
.\Build.ps1

# Or with verbose output
.\Build.ps1 -Verbose
```

**What Build.ps1 does:**
1. **Reads each module** in correct order
2. **Removes module-specific code** (Export-ModuleMember, etc.)
3. **Combines into single script** with proper headers
4. **Adds main execution flow** that calls functions in sequence
5. **Generates SHA256 hash** for integrity verification
6. **Creates VERIFICATION.md** with hash and build info
7. **Outputs to dist/PeviitorSetup.ps1**

### 3. Generated Script Structure
```powershell
# Combined script contains:
#Requires -Version 5.1
# [Script headers and documentation]
# [Global variables]
# [Module: Core - logging functions]
# [Module: Prerequisites - validation functions]  
# [Module: UserInput - input functions]
# [Module: Installation - install functions]
# [Module: Environment - environment functions]
# [Module: Application - application functions]
# [Main execution flow - calls functions in order]
# [Error handling]
```

## Development Workflow

### Phase 1: Module Development
1. **Work on individual modules** in `src/modules/`
2. **Test each module independently**
3. **Use `src/Main.ps1`** for development testing

### Phase 2: Build and Test
1. **Run `src/Build.ps1`** to generate combined script
2. **Test `dist/PeviitorSetup.ps1`** on clean system
3. **Verify hash matches** `dist/VERIFICATION.md`

### Phase 3: Distribution
1. **Commit both source and built files** to repository
2. **Create GitHub release** with `dist/PeviitorSetup.ps1`
3. **Include hash verification** in release notes

## Module Development Guidelines

### Function Naming Convention
- **Public functions:** Use verb-noun pattern (Get-SolrCredentials, Install-Docker)
- **Private functions:** Use module prefix (Core-WriteLog, Prerequisites-CheckAdmin)

### Error Handling
- **All modules must use** Core module logging functions
- **Throw exceptions** for fatal errors
- **Use Write-Log** with appropriate levels (INFO, WARN, ERROR, SUCCESS)

### Dependencies
- **Core module:** No dependencies (provides logging for others)
- **Other modules:** Can use Core module functions
- **Avoid cross-dependencies** between non-Core modules

### Module Template
```powershell
<#
.SYNOPSIS
    Module Name - Brief Description
.DESCRIPTION
    Detailed description of module purpose and functionality
#>

# Module-specific functions
function Public-Function {
    param()
    
    # Use Core module logging
    Write-Log "Function started" "INFO"
    
    try {
        # Function implementation
        Write-Log "Function completed successfully" "SUCCESS"
    } catch {
        Write-Log "Function failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Private helper functions (if needed)
function Private-Helper {
    # Helper implementation
}
```

## Testing Strategy

### Module Testing
- **Test each module individually** before building
- **Use `src/Main.ps1`** to import and test modules
- **Verify logging output** is consistent

### Integration Testing  
- **Test built script** (`dist/PeviitorSetup.ps1`) on clean systems
- **Verify all functions work** in combined form
- **Check error handling** works properly

### Distribution Testing
- **Verify hash** matches expected value
- **Test download and execution** process
- **Validate on different Windows versions**

## Version Management

### Build Versioning
- **Update version** in `Build.ps1` for releases
- **Include version** in generated script headers
- **Track build date** and module count

### Git Workflow
```bash
# Development cycle
git add src/modules/ModuleName.psm1
git commit -m "Update ModuleName module"

# Build and test
.\src\Build.ps1
# Test dist/PeviitorSetup.ps1

# Commit built version
git add dist/
git commit -m "Build v1.0.1 - Updated ModuleName"
git push origin main

# Create release
git tag v1.0.1
git push origin v1.0.1
```

## Troubleshooting

### Common Build Issues
- **Module not found:** Check file exists in `src/modules/`
- **Function conflicts:** Ensure unique function names across modules
- **Order issues:** Verify Core module is first, dependencies are correct

### Runtime Issues
- **Function not found:** Module may not have been included in build
- **Logging errors:** Core module may not be properly included
- **Execution order:** Check main execution flow calls functions correctly

## Security Considerations

### Hash Verification
- **Always generate** SHA256 hash for distribution
- **Include hash** in VERIFICATION.md and release notes
- **Users should verify** hash before execution

### Code Signing (Future)
- **Consider code signing** certificate for production releases
- **Update build process** to sign generated script
- **Include signing verification** in documentation
