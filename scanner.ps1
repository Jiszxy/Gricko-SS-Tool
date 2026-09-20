[CmdletBinding()]
param(
    [switch]$Cli,
    [switch]$ExportJson,
    [string]$OutputPath,
    [switch]$NoElevation,
    [switch]$NoColor,
    [int]$HoursPrefetch = 48,
    [int]$HoursFiles = 24,
    [int]$HoursBAM = 72
)

$baseDir = $PSScriptRoot
$srcCore = Join-Path $baseDir 'src\core'
$srcMods = Join-Path $baseDir 'src\modules'

if ((Test-Path $srcCore) -and (Test-Path $srcMods)) {
    $loadOrder = @(
        'src\core\Config.ps1',
        'src\core\Logger.ps1',
        'src\core\Elevator.ps1',
        'src\modules\InstanceScanner.ps1',
        'src\modules\ProcessScanner.ps1',
        'src\modules\PrefetchScanner.ps1',
        'src\modules\RegistryScanner.ps1',
        'src\modules\FileSystemScanner.ps1',
        'src\modules\HardwareScanner.ps1',
        'src\modules\ReportExporter.ps1',
        'src\gui\MainWindow.ps1'
    )

    foreach ($file in $loadOrder) {
        $modPath = Join-Path $baseDir $file
        if (Test-Path $modPath) {
            . $modPath
        } elseif ($file -notlike "*gui*") {
            Write-Error "Missing module: $modPath"
            exit 1
        }
    }
} else {
    $standalone = Join-Path $baseDir 'dist\gricko-standalone.ps1'
    if (Test-Path $standalone) {
        & $standalone @PSBoundParameters
        exit
    } else {
        Write-Host '[!] Missing source components.' -ForegroundColor Red
        exit 1
    }
}

function Start-ForensicScan {
    if (-not $Cli -and (Get-Command Show-GrickoGui -ErrorAction SilentlyContinue)) {
        Assert-Elevation
        Show-GrickoGui -HoursPrefetch $HoursPrefetch -HoursFiles $HoursFiles -HoursBAM $HoursBAM
    } else {
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
}

Start-ForensicScan

