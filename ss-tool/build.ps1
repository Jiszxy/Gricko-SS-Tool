param()

$baseDir = $PSScriptRoot
$distDir = Join-Path $baseDir 'dist'
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$targetFile = Join-Path $distDir 'gricko-standalone.ps1'
Write-Host '[*] Building Gricko SS Tool standalone distribution...' -ForegroundColor Cyan

$moduleList = @(
    'src\core\Config.ps1',
    'src\core\Logger.ps1',
    'src\core\Elevator.ps1',
    'src\modules\InstanceScanner.ps1',
    'src\modules\ProcessScanner.ps1',
    'src\modules\PrefetchScanner.ps1',
    'src\modules\RegistryScanner.ps1',
    'src\modules\FileSystemScanner.ps1',
    'src\modules\HardwareScanner.ps1',
    'src\modules\ReportExporter.ps1'
)

$bundleContent = [System.Text.StringBuilder]::new()

$header = @'
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

'@

$bundleContent.AppendLine($header) | Out-Null

foreach ($mod in $moduleList) {
    $fullPath = Join-Path $baseDir $mod
    if (Test-Path $fullPath) {
        Write-Host "  -> $mod" -ForegroundColor DarkCyan
        $content = Get-Content -Path $fullPath -Raw
        $bundleContent.AppendLine($content.Trim()) | Out-Null
        $bundleContent.AppendLine("`n") | Out-Null
    } else {
        Write-Host "  [!] Missing module: $fullPath" -ForegroundColor Red
    }
}

$entrypoint = @'
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
'@

$bundleContent.AppendLine($entrypoint) | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($targetFile, $bundleContent.ToString(), $utf8NoBom)
Write-Host "[OK] Built standalone distribution (UTF-8 No BOM) -> $targetFile" -ForegroundColor Green

