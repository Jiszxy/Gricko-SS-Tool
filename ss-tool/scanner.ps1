<#
.SYNOPSIS
    Gricko SS Tool - Modular Loader & Orchestrator
    Ocean-Inspired Purple & Blue Minecraft Forensic Scanner

.DESCRIPTION
    Entrypoint for Gricko SS Tool. Automatically resolves and dot-sources
    modular components from src/core/ and src/modules/ when running locally,
    or falls back to dist/gricko-standalone.ps1 for single-file portable execution.

.PARAMETER ExportJson
    Exports the complete forensic report to a timestamped JSON file.

.PARAMETER OutputPath
    Custom path for the exported JSON file.

.PARAMETER NoElevation
    Bypasses the automatic UAC administrator self-elevation prompt.

.PARAMETER NoColor
    Disables ANSI/host color output for plain text redirection.

.PARAMETER HoursPrefetch
    Time window in hours for Prefetch traces (Default: 48).

.PARAMETER HoursFiles
    Time window in hours for file system modifications (Default: 24).

.PARAMETER HoursBAM
    Time window in hours for BAM registry traces (Default: 72).

.EXAMPLE
    .\scanner.ps1
    Runs the full modular forensic scan.

.EXAMPLE
    .\scanner.ps1 -ExportJson
    Runs the scan and exports a structured JSON report.
#>

[CmdletBinding()]
param(
    [switch]$ExportJson,
    [string]$OutputPath,
    [switch]$NoElevation,
    [switch]$NoColor,
    [int]$HoursPrefetch = 48,
    [int]$HoursFiles = 24,
    [int]$HoursBAM = 72
)

$baseDir = $PSScriptRoot
$srcCore = Join-Path $baseDir "src\core"
$srcMods = Join-Path $baseDir "src\modules"

if ((Test-Path $srcCore) -and (Test-Path $srcMods)) {
    # --------------------------------------------------------------------------
    # MODULAR DEV MODE: Dot-source local modules
    # --------------------------------------------------------------------------
    $loadOrder = @(
        "src\core\Config.ps1",
        "src\core\Logger.ps1",
        "src\core\Elevator.ps1",
        "src\modules\InstanceScanner.ps1",
        "src\modules\ProcessScanner.ps1",
        "src\modules\PrefetchScanner.ps1",
        "src\modules\RegistryScanner.ps1",
        "src\modules\FileSystemScanner.ps1",
        "src\modules\HardwareScanner.ps1",
        "src\modules\ReportExporter.ps1"
    )

    foreach ($file in $loadOrder) {
        $modPath = Join-Path $baseDir $file
        if (Test-Path $modPath) {
            . $modPath
        } else {
            Write-Error "Could not locate required module: $modPath"
            exit 1
        }
    }
} else {
    # --------------------------------------------------------------------------
    # STANDALONE / PORTABLE MODE: Check dist or embedded
    # --------------------------------------------------------------------------
    $standalone = Join-Path $baseDir "dist\gricko-standalone.ps1"
    if (Test-Path $standalone) {
        & $standalone @PSBoundParameters
        exit
    } else {
        Write-Host "[!] Modular components not found. Ensure src/ directory is present." -ForegroundColor Red
        exit 1
    }
}

# ==============================================================================
# MAIN SCAN ORCHESTRATOR
# ==============================================================================
function Start-ForensicScan {
    Show-Banner
    Assert-Elevation
    Scan-LastPlayedInstance
    Scan-JavaProcesses
    Scan-PrefetchTraces -Hours $HoursPrefetch
    Scan-BAMRegistry -Hours $HoursBAM
    Scan-UserAssist
    Scan-FileSystem -Hours $HoursFiles
    Scan-USBStorage
    Export-Report -ExportJson:$ExportJson -OutputPath $OutputPath
}

Start-ForensicScan
