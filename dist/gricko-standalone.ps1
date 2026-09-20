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

<#
    Gricko SS Tool - Core Configuration & Signature Definitions
#>

$Global:ToolName = "Gricko SS Tool"
$Global:ToolVersion = "2.3.0"
$Global:ScanStartTime = Get-Date
$Global:Findings = [System.Collections.Generic.List[PSCustomObject]]::new()

$Global:ReportData = [ordered]@{
    Metadata = [ordered]@{
        ToolName        = $Global:ToolName
        Version         = $Global:ToolVersion
        ScanTimestamp   = $Global:ScanStartTime.ToString("o")
        HostName        = $env:COMPUTERNAME
        UserName        = "$env:USERDOMAIN\$env:USERNAME"
        OS              = (Get-CimInstance Win32_OperatingSystem).Caption
        OSVersion       = (Get-CimInstance Win32_OperatingSystem).Version
        Architecture    = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
        IsElevated      = $false
    }
    Scorecard = [ordered]@{
        Flags    = 0
        Warnings = 0
        Info     = 0
        Clean    = 0
    }
    LastPlayedInstance = [ordered]@{}
    CheatClients       = @()
    LegitClients       = @()
    JavaProcesses      = @()
    PrefetchTraces     = @()
    BAMTraces          = @()
    UserAssistTraces   = @()
    MuiCacheTraces     = @()
    ModFiles           = @()
    TempFiles          = @()
    AntiForensics      = @()
    USBDevices         = @()
}

# Comprehensive Minecraft Cheat & Ghost Client Signatures
$Global:CheatSignatures = @(
    # Ghost & Internal Injection Clients
    "prestige", "grimclient", "grim-client", "vape", "vapelite", "vapev4",
    "drip", "driplite", "dripsoft", "slinky", "slinkyloader", "raven", "ravenb", 
    "ravenweave", "weave-loader", "weave", "entropy", "whiteout", "yukon", 
    "sapphire", "spectral", "dreamclient", "itami", "lowkey", "skilled", "bape", 
    "kura", "karma", "breeze", "koid", "phantom", "dope", "haru",

    # Blatant, Anarchy & Utility Cheats
    "rise", "rise6", "augustus", "novoline", "tenacity", "liquidbounce", 
    "meteor", "wurst", "aristois", "inertial", "inertia", "sigma", "sigma5", 
    "futureclient", "future-client", "rusherhack", "rusher", "boze", "abyss", 
    "coffeeclient", "catwithsword", "doomsday", "fdpclient", "lime", "envy", 
    "pluto", "exhibition", "astolfo", "zeroday", "impact", "bleachhack", "ares", 
    "kamiblue", "lambda", "cleanerclient"
)

# Known Legitimate Launchers & Mod Loaders
$Global:LegitimateSignatures = @(
    "lunarclient", "lunar-client", "lunar", "badlion", "badlionclient", 
    "feather", "featherclient", "modrinth", "theseus", "prismlauncher", 
    "multimc", "salwyrn", "labymod", "batmod", "cheatbreaker", "minecraft", 
    "forge", "fabric", "neoforge", "quilt", "optifine"
)

# Suspicious keywords that match injection or loader evasion
$Global:SuspiciousSignatures = $Global:CheatSignatures


<#
    Gricko SS Tool - Terminal UI, Colors & Logging Engine
    Theme: Purple & Blue (Ocean Inspired)
#>

function Write-PurpleBorder {
    param([string]$Text = "")
    if ($NoColor) {
        Write-Host "================================================================================"
        if ($Text) { Write-Host "  $Text" }
        return
    }
    Write-Host " +----------------------------------------------------------------------------+" -ForegroundColor Magenta
    if ($Text) {
        Write-Host " |  " -NoNewline -ForegroundColor Magenta
        Write-Host $Text.PadRight(74) -NoNewline -ForegroundColor Cyan
        Write-Host "|" -ForegroundColor Magenta
        Write-Host " +----------------------------------------------------------------------------+" -ForegroundColor Magenta
    }
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    if ($NoColor) {
        Write-Host "--- $Title ---"
    } else {
        $padding = [math]::Max(2, (70 - $Title.Length))
        $divider = "=" * $padding
        Write-Host " [::] " -NoNewline -ForegroundColor Magenta
        Write-Host $Title.ToUpper() -NoNewline -ForegroundColor Cyan
        Write-Host " $divider" -ForegroundColor DarkMagenta
    }
}

function Write-Alert {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("OK", "INFO", "WARN", "FLAG")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [string]$Detail = ""
    )

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $tag = "[$Level]"
    $color = "White"

    switch ($Level) {
        "OK"   { $color = "Green";   $Global:ReportData.Scorecard.Clean++ }
        "INFO" { $color = "Cyan";    $Global:ReportData.Scorecard.Info++ }
        "WARN" { $color = "Yellow";  $Global:ReportData.Scorecard.Warnings++ }
        "FLAG" { $color = "Red";     $Global:ReportData.Scorecard.Flags++ }
    }

    $entry = [PSCustomObject]@{
        Timestamp = $timestamp
        Level     = $Level
        Message   = $Message
        Detail    = $Detail
    }
    $Global:Findings.Add($entry)

    if ($Global:GuiLoggerCallback) {
        try { & $Global:GuiLoggerCallback $entry } catch {}
    }

    if ($NoColor) {
        if ($Detail) {
            Write-Host "$timestamp $tag $Message - $Detail"
        } else {
            Write-Host "$timestamp $tag $Message"
        }
    } else {
        Write-Host " $timestamp " -NoNewline -ForegroundColor DarkGray
        Write-Host "$tag " -NoNewline -ForegroundColor $color
        Write-Host $Message -NoNewline -ForegroundColor White
        if ($Detail) {
            Write-Host " -> $Detail" -ForegroundColor DarkCyan
        } else {
            Write-Host ""
        }
    }
}

function Update-ScanStatus {
    param(
        [string]$StatusText,
        [double]$Percent = -1
    )
    if ($Global:GuiStatusCallback) {
        try { & $Global:GuiStatusCallback $StatusText $Percent } catch {}
    }
}


function Show-Banner {
    if (-not $NoColor) {
        Write-Host ""
        Write-Host " ==============================================================================" -ForegroundColor Magenta
        Write-Host "   ____ ____  ___ ____ _  ______     ____ ____   _____ ___   ___  _         " -ForegroundColor Cyan
        Write-Host "  / ___|  _ \|_ _/ ___| |/ / ___|   / ___/ ___| |_   _/ _ \ / _ \| |        " -ForegroundColor Cyan
        Write-Host " | |  _| |_) || | |   | ' / |  _    \___ \___ \   | || | | | | | | |        " -ForegroundColor Blue
        Write-Host " | |_| |  _ < | | |___| . \ |_| |    ___) |__) |  | || |_| | |_| | |___     " -ForegroundColor Blue
        Write-Host "  \____|_| \_\___\____|_|\_\____|   |____/____/   |_| \___/ \___/|_____|    " -ForegroundColor DarkCyan
        Write-Host "                                                                                " -ForegroundColor Magenta
        Write-Host "          [+] GRICKO SS TOOL | ADVANCED INSTANCE & FORENSIC SCANNER [+]         " -ForegroundColor Yellow
        Write-Host "                  Ocean-Inspired Purple/Blue Engine v$($Global:ToolVersion)          " -ForegroundColor DarkGray
        Write-Host " ==============================================================================" -ForegroundColor Magenta
        Write-Host ""
    } else {
        Write-Host "`n=== GRICKO SS TOOL (Minecraft Forensic Scanner v$($Global:ToolVersion)) ===`n"
    }
}


<#
    Gricko SS Tool - Self-Elevation & Privilege Escalation Handler
#>

function Assert-Elevation {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $Global:ReportData.Metadata.IsElevated = $isAdmin

    if (-not $isAdmin) {
        if ($NoElevation) {
            Write-Alert -Level "WARN" -Message "Running as Standard User (NoElevation specified)." -Detail "BAM, Prefetch, and low-level registry keys may be inaccessible."
            return
        }

        Write-Alert -Level "WARN" -Message "Administrator privileges required for low-level forensic artifacts (Prefetch, BAM, EventLogs)."
        Write-Alert -Level "INFO" -Message "Attempting automatic self-elevation..."

        $scriptPath = $PSCommandPath
        if (-not $scriptPath) {
            $scriptPath = $MyInvocation.MyCommand.Definition
        }

        if ($scriptPath -and (Test-Path $scriptPath)) {
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            if ($ExportJson) { $arguments += " -ExportJson" }
            if ($OutputPath) { $arguments += " -OutputPath `"$OutputPath`"" }
            if ($NoColor)    { $arguments += " -NoColor" }

            try {
                Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
                exit
            } catch {
                Write-Alert -Level "WARN" -Message "UAC Elevation was declined or failed." -Detail "Continuing scan in unprivileged mode."
            }
        } else {
            Write-Alert -Level "WARN" -Message "Script running from memory or stream. Cannot auto-elevate file." -Detail "Run PowerShell as Administrator for full forensic visibility."
        }
    } else {
        Write-Alert -Level "OK" -Message "Administrative elevation confirmed." -Detail "Full access to Prefetch, BAM, and low-level artifacts."
    }
}


<#
    Gricko SS Tool - Last Played Instance & Session Log Forensics
#>

function Scan-LastPlayedInstance {
    Write-SectionHeader "LAST PLAYED MINECRAFT INSTANCE & LOG FORENSICS"

    $instances = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 0. Active Running Java / Minecraft Process Check
    try {
        $javaProcesses = Get-CimInstance Win32_Process -Filter "Name = 'javaw.exe' or Name = 'java.exe'" -ErrorAction SilentlyContinue
        foreach ($proc in $javaProcesses) {
            $cmd = $proc.CommandLine
            if (-not $cmd) { continue }
            if ($cmd -match "minecraft" -or $cmd -match "lunar" -or $cmd -match "feather" -or $cmd -match "badlion" -or $cmd -match "forge" -or $cmd -match "fabric" -or $cmd -match "optifine" -or $cmd -match "net.minecraft") {
                $clientName = "Minecraft (Vanilla / Custom)"
                if ($cmd -match "(?i)feather") { $clientName = "Feather Client (Running)" }
                elseif ($cmd -match "(?i)lunar") { $clientName = "Lunar Client (Running)" }
                elseif ($cmd -match "(?i)badlion") { $clientName = "Badlion Client (Running)" }
                elseif ($cmd -match "(?i)theseus|modrinth") { $clientName = "Modrinth App (Running)" }
                elseif ($cmd -match "(?i)curseforge") { $clientName = "CurseForge (Running)" }
                elseif ($cmd -match "(?i)prism") { $clientName = "Prism Launcher (Running)" }
                elseif ($cmd -match "(?i)salwyrr") { $clientName = "Salwyrr Client (Running)" }
                elseif ($cmd -match "(?i)labymod") { $clientName = "LabyMod (Running)" }
                elseif ($cmd -match "(?i)fabric") { $clientName = "Fabric Loader (Running)" }
                elseif ($cmd -match "(?i)forge") { $clientName = "Forge Loader (Running)" }

                $gameDir = $null
                if ($cmd -match '--gameDir\s+"?([^"]+)"?') { $gameDir = $matches[1].Trim() }
                elseif ($cmd -match '-Dminecraft\.applet\.TargetDirectory="?([^"]+)"?') { $gameDir = $matches[1].Trim() }

                $logPath = if ($gameDir) { Join-Path $gameDir "logs\latest.log" } else { $null }

                $instances.Add([PSCustomObject]@{
                    Launcher   = $clientName
                    Profile    = "Active Running Game (PID $($proc.ProcessId))"
                    Version    = "Active Session"
                    Path       = if ($gameDir) { $gameDir } else { "Process PID $($proc.ProcessId)" }
                    LogFile    = $logPath
                    LastPlayed = (Get-Date)
                })
            }
        }
    } catch {}

    # 1. Modrinth Launcher (Theseus & Modrinth App) - Check first to prioritize modern multi-drive installations
    $modrinthProfileDirs = [System.Collections.Generic.List[string]]::new()
    
    $candidateModrinthDirs = @(
        (Join-Path $env:APPDATA "com.modrinth.theseus\profiles"),
        (Join-Path $env:APPDATA "ModrinthApp\profiles"),
        (Join-Path $env:LOCALAPPDATA "ModrinthApp\profiles"),
        "D:\Igre\ModrinthApp\profiles",
        "C:\Igre\ModrinthApp\profiles",
        "D:\ModrinthApp\profiles",
        "C:\ModrinthApp\profiles"
    )
    foreach ($cmd in $candidateModrinthDirs) {
        if ((Test-Path $cmd) -and ($cmd -notin $modrinthProfileDirs)) {
            $modrinthProfileDirs.Add($cmd)
        }
    }

    # Discover custom profile locations from Modrinth launcher session logs
    $modrinthLauncherLogs = Join-Path $env:APPDATA "ModrinthApp\launcher_logs"
    if (Test-Path $modrinthLauncherLogs) {
        $recentLogs = Get-ChildItem -Path $modrinthLauncherLogs -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        foreach ($rl in $recentLogs) {
            $logLines = Get-Content -Path $rl.FullName -Tail 200 -ErrorAction SilentlyContinue
            foreach ($lt in $logLines) {
                if ($lt -match 'path:\s*([A-Za-z]:\\[^"\r\n]+Modrinth[^\\]*\\profiles)') {
                    $matchedDir = $matches[1].Trim()
                    if ((Test-Path $matchedDir) -and ($matchedDir -notin $modrinthProfileDirs)) {
                        $modrinthProfileDirs.Add($matchedDir)
                    }
                }
            }
        }
    }

    # Scan all drive roots for ModrinthApp/profiles
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        $driveCandidates = @(
            (Join-Path $drive.Root "Igre\ModrinthApp\profiles"),
            (Join-Path $drive.Root "ModrinthApp\profiles"),
            (Join-Path $drive.Root "Games\ModrinthApp\profiles")
        )
        foreach ($dc in $driveCandidates) {
            if ((Test-Path $dc) -and ($dc -notin $modrinthProfileDirs)) {
                $modrinthProfileDirs.Add($dc)
            }
        }
    }

    foreach ($mProfilesRoot in $modrinthProfileDirs) {
        $subDirs = Get-ChildItem -Path $mProfilesRoot -Directory -ErrorAction SilentlyContinue
        foreach ($mDir in $subDirs) {
            $mLog = Join-Path $mDir.FullName "logs\latest.log"
            $mTime = if (Test-Path $mLog) { (Get-Item $mLog).LastWriteTime } else { $mDir.LastWriteTime }
            $instances.Add([PSCustomObject]@{
                Launcher   = "Modrinth App"
                Profile    = $mDir.Name
                Version    = "Modrinth Profile (Fabric)"
                Path       = $mDir.FullName
                LogFile    = if (Test-Path $mLog) { $mLog } else { $null }
                LastPlayed = $mTime
            })
        }
    }

    # 2. Feather Client
    $featherPaths = @(
        (Join-Path $env:APPDATA ".feather"),
        (Join-Path $env:USERPROFILE ".feather"),
        (Join-Path $env:LOCALAPPDATA ".feather")
    )
    foreach ($fPath in $featherPaths) {
        if (Test-Path $fPath) {
            $fLog = Join-Path $fPath "logs\latest.log"
            $fLastTime = if (Test-Path $fLog) { (Get-Item $fLog).LastWriteTime } else { (Get-Item $fPath).LastWriteTime }
            $instances.Add([PSCustomObject]@{
                Launcher   = "Feather Client"
                Profile    = "Feather Profile"
                Version    = "Feather Fabric/Forge"
                Path       = $fPath
                LogFile    = $fLog
                LastPlayed = $fLastTime
            })
            break
        }
    }

    # 3. Lunar Client
    $lunarPath = Join-Path $env:USERPROFILE ".lunarclient"
    if (Test-Path $lunarPath) {
        $lunarLog = Join-Path $lunarPath "offline\multiver\logs\latest.log"
        if (-not (Test-Path $lunarLog)) { $lunarLog = Join-Path $lunarPath "logs\launcher\renderer.log" }
        if (-not (Test-Path $lunarLog)) { $lunarLog = Join-Path $lunarPath "logs\launcher\main.log" }
        $lTime = if (Test-Path $lunarLog) { (Get-Item $lunarLog).LastWriteTime } else { (Get-Item $lunarPath).LastWriteTime }
        $instances.Add([PSCustomObject]@{
            Launcher   = "Lunar Client"
            Profile    = "Lunar MultiVer Profile"
            Version    = "Lunar Client"
            Path       = $lunarPath
            LogFile    = $lunarLog
            LastPlayed = $lTime
        })
    }

    # 4. Badlion Client
    $badlionPaths = @(
        (Join-Path $env:APPDATA "Badlion Client"),
        (Join-Path $env:APPDATA ".minecraft\badlion"),
        (Join-Path $env:LOCALAPPDATA "Badlion Client")
    )
    foreach ($blPath in $badlionPaths) {
        if (Test-Path $blPath) {
            $blLog = Join-Path $blPath "logs\latest.log"
            $blTime = if (Test-Path $blLog) { (Get-Item $blLog).LastWriteTime } else { (Get-Item $blPath).LastWriteTime }
            $instances.Add([PSCustomObject]@{
                Launcher   = "Badlion Client"
                Profile    = "Badlion Profile"
                Version    = "Badlion Client"
                Path       = $blPath
                LogFile    = $blLog
                LastPlayed = $blTime
            })
            break
        }
    }

    # 5. CurseForge
    $cursePaths = @(
        (Join-Path $env:USERPROFILE "curseforge\minecraft\Instances"),
        (Join-Path $env:USERPROFILE "Documents\curseforge\minecraft\Instances")
    )
    foreach ($cfRoot in $cursePaths) {
        if (Test-Path $cfRoot) {
            $cfDirs = Get-ChildItem -Path $cfRoot -Directory -ErrorAction SilentlyContinue
            foreach ($cfDir in $cfDirs) {
                $cfLog = Join-Path $cfDir.FullName "logs\latest.log"
                $cfTime = if (Test-Path $cfLog) { (Get-Item $cfLog).LastWriteTime } else { $cfDir.LastWriteTime }
                $instances.Add([PSCustomObject]@{
                    Launcher   = "CurseForge"
                    Profile    = $cfDir.Name
                    Version    = "CurseForge Instance"
                    Path       = $cfDir.FullName
                    LogFile    = $cfLog
                    LastPlayed = $cfTime
                })
            }
        }
    }

    # 6. Prism Launcher & MultiMC
    $prismPaths = @(
        (Join-Path $env:APPDATA "PrismLauncher\instances"),
        (Join-Path $env:APPDATA "MultiMC\instances"),
        (Join-Path $env:APPDATA "PolyMC\instances")
    )
    foreach ($pRoot in $prismPaths) {
        if (Test-Path $pRoot) {
            $pDirs = Get-ChildItem -Path $pRoot -Directory -ErrorAction SilentlyContinue
            foreach ($pDir in $pDirs) {
                $pLog = Join-Path $pDir.FullName ".minecraft\logs\latest.log"
                if (-not (Test-Path $pLog)) { $pLog = Join-Path $pDir.FullName "logs\latest.log" }
                $pTime = if (Test-Path $pLog) { (Get-Item $pLog).LastWriteTime } else { $pDir.LastWriteTime }
                $instances.Add([PSCustomObject]@{
                    Launcher   = "Prism / MultiMC"
                    Profile    = $pDir.Name
                    Version    = "Prism Instance"
                    Path       = $pDir.FullName
                    LogFile    = $pLog
                    LastPlayed = $pTime
                })
            }
        }
    }

    # 7. Salwyrr
    $salwyrrPaths = @(
        (Join-Path $env:APPDATA ".salwyrr"),
        (Join-Path $env:USERPROFILE ".salwyrr")
    )
    foreach ($sPath in $salwyrrPaths) {
        if (Test-Path $sPath) {
            $sLog = Join-Path $sPath "logs\latest.log"
            $sTime = if (Test-Path $sLog) { (Get-Item $sLog).LastWriteTime } else { (Get-Item $sPath).LastWriteTime }
            $instances.Add([PSCustomObject]@{
                Launcher   = "Salwyrr Client"
                Profile    = "Salwyrr Profile"
                Version    = "Salwyrr"
                Path       = $sPath
                LogFile    = $sLog
                LastPlayed = $sTime
            })
            break
        }
    }

    # 8. Standard .minecraft (Vanilla, Forge, Fabric)
    $dotMc = Join-Path $env:APPDATA ".minecraft"
    if (Test-Path $dotMc) {
        $lpJson = Join-Path $dotMc "launcher_profiles.json"
        $latestLog = Join-Path $dotMc "logs\latest.log"

        $lastUsedTime = $null
        $profileName = "Standard Profile"
        $versionId = "Vanilla / Forge / Fabric"

        if (Test-Path $lpJson) {
            try {
                $lp = Get-Content -Raw -Path $lpJson -ErrorAction SilentlyContinue | ConvertFrom-Json
                if ($lp.profiles) {
                    foreach ($prop in $lp.profiles.PSObject.Properties) {
                        $p = $prop.Value
                        if ($p.lastUsed) {
                            $t = [DateTime]::Parse($p.lastUsed)
                            if (-not $lastUsedTime -or $t -gt $lastUsedTime) {
                                $lastUsedTime = $t
                                $profileName = if ($p.name) { $p.name } else { $prop.Name }
                                $versionId = if ($p.lastVersionId) { $p.lastVersionId } else { "Custom" }
                            }
                        }
                    }
                }
            } catch {}
        }

        if (Test-Path $latestLog) {
            $logWriteTime = (Get-Item $latestLog).LastWriteTime
            if (-not $lastUsedTime -or $logWriteTime -gt $lastUsedTime) {
                $lastUsedTime = $logWriteTime
            }
        }

        if ($lastUsedTime) {
            $instances.Add([PSCustomObject]@{
                Launcher   = "Standard Minecraft (.minecraft)"
                Profile    = $profileName
                Version    = $versionId
                Path       = $dotMc
                LogFile    = $latestLog
                LastPlayed = $lastUsedTime
            })
        }
    }

    # Pick the most recently launched instance across all launchers and drives
    $sortedInstances = $instances | Sort-Object LastPlayed -Descending
    $lastPlayed = $sortedInstances | Select-Object -First 1

    if ($lastPlayed) {
        Write-Host ""
        Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host "  |  (*) LAST PLAYED INSTANCE IDENTIFIED (ACTIVE TARGET)                     |" -ForegroundColor Magenta
        Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host "  |  Launcher : " -NoNewline -ForegroundColor DarkMagenta
        Write-Host ($lastPlayed.Launcher).PadRight(58) -NoNewline -ForegroundColor Cyan
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  |  Profile  : " -NoNewline -ForegroundColor DarkMagenta
        Write-Host ($lastPlayed.Profile).PadRight(58) -NoNewline -ForegroundColor White
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  |  Version  : " -NoNewline -ForegroundColor DarkMagenta
        Write-Host ($lastPlayed.Version).PadRight(58) -NoNewline -ForegroundColor White
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  |  Last Run : " -NoNewline -ForegroundColor DarkMagenta
        Write-Host ($lastPlayed.LastPlayed.ToString("yyyy-MM-dd HH:mm:ss")).PadRight(58) -NoNewline -ForegroundColor Green
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  |  Path     : " -NoNewline -ForegroundColor DarkMagenta
        $truncPath = if ($lastPlayed.Path.Length -gt 58) { "..." + $lastPlayed.Path.Substring($lastPlayed.Path.Length - 55) } else { $lastPlayed.Path }
        Write-Host $truncPath.PadRight(58) -NoNewline -ForegroundColor DarkCyan
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host ""

        $connectedServers = [System.Collections.Generic.List[string]]::new()
        $logFileTarget = $lastPlayed.LogFile

        # Deep Inspection of Instance latest.log if present
        if ($logFileTarget -and (Test-Path $logFileTarget)) {
            $logItem = Get-Item $logFileTarget
            Write-Alert -Level "INFO" -Message "Analyzing session log file" -Detail "$logFileTarget (Size: $([math]::Round($logItem.Length / 1KB, 2)) KB)"

            if ($logItem.Length -eq 0) {
                Write-Alert -Level "FLAG" -Message "INSTANCE LOG WAS WIPED OR EMPTY (0 BYTES)!" -Detail "Strong indicator of log clearing right before screenshare."
            } else {
                $logLines = Get-Content -Path $logFileTarget -Tail 300 -ErrorAction SilentlyContinue
                $suspiciousLogHits = 0

                foreach ($line in $logLines) {
                    if ($line -match "Connecting to ([^,\s]+)") {
                        $server = $matches[1].Trim()
                        if ($server -notin $connectedServers) {
                            $connectedServers.Add($server)
                        }
                    } elseif ($line -match "(?i)Website:\s*([a-zA-Z0-9\.\-]+)") {
                        $server = $matches[1].Trim()
                        if ($server -notin $connectedServers) {
                            $connectedServers.Add($server)
                        }
                    } elseif ($line -match "(?i)\[CHAT\].*(minemen\.club|hypixel\.net|invadedlands\.net|pvptemple\.com|coldpvp\.com|bedless\.club|mcpvp\.club|syuu\.net|loyisa\.cn)") {
                        $server = $matches[1].Trim()
                        if ($server -notin $connectedServers) {
                            $connectedServers.Add($server)
                        }
                    }

                    foreach ($sig in $Global:SuspiciousSignatures) {
                        if ($line -match "(?i)\b$sig\b") {
                            $suspiciousLogHits++
                            Write-Alert -Level "FLAG" -Message "SUSPICIOUS STRING FOUND IN ACTIVE SESSION LOG!" -Detail "Line: $line"
                            break
                        }
                    }
                }

                if ($connectedServers.Count -gt 0) {
                    Write-Alert -Level "INFO" -Message "Connected servers identified in session" -Detail ($connectedServers -join ", ")
                }

                if ($suspiciousLogHits -eq 0) {
                    Write-Alert -Level "OK" -Message "No known cheat signatures found in latest.log."
                }
            }
        }

        $Global:ReportData.LastPlayedInstance = [ordered]@{
            Launcher         = $lastPlayed.Launcher
            LauncherName     = $lastPlayed.Launcher
            Profile          = $lastPlayed.Profile
            ProfileName      = $lastPlayed.Profile
            Version          = $lastPlayed.Version
            Path             = $lastPlayed.Path
            LogFile          = $lastPlayed.LogFile
            LastPlayed       = $lastPlayed.LastPlayed.ToString("yyyy-MM-dd HH:mm:ss")
            LastPlayedTime   = $lastPlayed.LastPlayed.ToString("yyyy-MM-dd HH:mm:ss")
            ConnectedServers = $connectedServers
        }
    } else {
        Write-Alert -Level "WARN" -Message "Could not detect any Minecraft launchers or instance profiles." -Detail "Minecraft may be installed on a non-standard drive or launched as portable."
    }
}


<#
    Gricko SS Tool - Java & Process Memory Forensic Scanner
#>

function Scan-JavaProcesses {
    Write-SectionHeader "PROCESS & MEMORY ANALYSIS (ACTIVE JVM / INJECTION)"
    
    $procQuery = "Name = 'javaw.exe' or Name = 'java.exe'"
    $processes = Get-CimInstance Win32_Process -Filter $procQuery

    if (-not $processes) {
        Write-Alert -Level "INFO" -Message "No active javaw.exe or java.exe processes found." -Detail "Screenshare may be conducted post-gameplay or client was terminated."
        return
    }

    foreach ($proc in $processes) {
        $cmdLine = $proc.CommandLine
        $pidNum = $proc.ProcessId
        $execPath = $proc.ExecutablePath
        $createTime = $proc.CreationDate

        $procInfo = [ordered]@{
            ProcessId       = $pidNum
            Name            = $proc.Name
            ExecutablePath  = $execPath
            CreationDate    = if ($createTime) { $createTime.ToString("o") } else { "N/A" }
            CommandLine     = $cmdLine
            JavaAgents      = @()
            SuspiciousFlags = @()
        }

        Write-Alert -Level "INFO" -Message "Detected active Java process" -Detail "PID: $pidNum | Name: $($proc.Name)"

        if (-not $cmdLine) {
            Write-Alert -Level "WARN" -Message "Process PID $pidNum CommandLine is empty or protected."
            $Global:ReportData.JavaProcesses += [PSCustomObject]$procInfo
            continue
        }

        # Check for Java Agents (-javaagent)
        $agentMatches = [regex]::Matches($cmdLine, '-javaagent:([^\s]+)')
        if ($agentMatches.Count -gt 0) {
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"', "'")
                $procInfo.JavaAgents += $agentPath

                $isKnownLegit = ($agentPath -like "*jetbrains*" -or $agentPath -like "*byte-buddy*" -or $agentPath -like "*fabric-loader*")
                $isSuspiciousKeyword = $false
                foreach ($sig in $Global:SuspiciousSignatures) {
                    if ($agentPath -like "*$sig*") {
                        $isSuspiciousKeyword = $true
                        break
                    }
                }

                if ($isSuspiciousKeyword) {
                    Write-Alert -Level "FLAG" -Message "SUSPICIOUS INJECTED JAVA AGENT DETECTED!" -Detail "PID: $pidNum | Agent: $agentPath"
                } elseif ($agentPath -like "*Temp*" -or $agentPath -like "*AppData\Local\Temp*" -or $agentPath -like "*Downloads*") {
                    if ($agentPath -like "*theseus.jar*") {
                        Write-Alert -Level "INFO" -Message "Legitimate Modrinth Launcher Agent loaded from Temp" -Detail $agentPath
                    } else {
                        Write-Alert -Level "FLAG" -Message "JAVA AGENT LOADED FROM UNTRUSTED/TEMP DIRECTORY!" -Detail "PID: $pidNum | Path: $agentPath"
                    }
                } elseif (-not $isKnownLegit) {
                    Write-Alert -Level "WARN" -Message "Unverified Java Agent loaded on PID $pidNum" -Detail $agentPath
                } else {
                    Write-Alert -Level "INFO" -Message "Standard Java Agent loaded" -Detail $agentPath
                }
            }
        } else {
            Write-Alert -Level "OK" -Message "No active -javaagent flags detected on PID $pidNum."
        }

        # Check for abnormal JVM parameters
        if ($cmdLine -like "*-noverify*") {
            Write-Alert -Level "WARN" -Message "Abnormal JVM flag '-noverify' found." -Detail "Disables bytecode verification; commonly used by runtime injectors."
            $procInfo.SuspiciousFlags += "-noverify"
        }
        if ($cmdLine -like "*-Xbootclasspath*") {
            Write-Alert -Level "WARN" -Message "Custom boot classpath manipulation detected (-Xbootclasspath)." -Detail "PID: $pidNum"
            $procInfo.SuspiciousFlags += "-Xbootclasspath"
        }

        # Keyword match against entire command line
        foreach ($sig in $Global:SuspiciousSignatures) {
            if ($cmdLine -match "(?i)\b$sig\b") {
                Write-Alert -Level "FLAG" -Message "SUSPICIOUS KEYWORD IN RUNNING JVM COMMAND LINE!" -Detail "PID: $pidNum | Signature: '$sig'"
                $procInfo.SuspiciousFlags += "Signature: $sig"
            }
        }

        $Global:ReportData.JavaProcesses += [PSCustomObject]$procInfo
    }
}


<#
    Gricko SS Tool - Prefetch Trace & Execution History Scanner
#>

function Scan-PrefetchTraces {
    param([int]$Hours = $HoursPrefetch)
    Write-SectionHeader "EXECUTION TRACES: PREFETCH (PAST $Hours HOURS)"

    $prefetchDir = "C:\Windows\Prefetch"
    if (-not (Test-Path $prefetchDir)) {
        Write-Alert -Level "WARN" -Message "Prefetch directory '$prefetchDir' not found or inaccessible." -Detail "Elevation required."
        return
    }

    $timeCutoff = (Get-Date).AddHours(-$Hours)
    $pfFiles = Get-ChildItem -Path $prefetchDir -Filter "*.pf" | Where-Object { $_.LastWriteTime -ge $timeCutoff } | Sort-Object LastWriteTime -Descending

    if (-not $pfFiles) {
        Write-Alert -Level "WARN" -Message "No Prefetch files modified within the last $Hours hours." -Detail "Prefetch may be disabled, cleared, or system recently booted."
        return
    }

    Write-Alert -Level "INFO" -Message "Analyzed $($pfFiles.Count) recent Prefetch execution records."

    $flaggedCount = 0
    foreach ($file in $pfFiles) {
        $rawName = $file.BaseName
        $execName = ($rawName -replace '-[A-F0-9]{8}$', '')

        $isMatch = $false
        $matchedSig = ""

        foreach ($sig in $Global:SuspiciousSignatures) {
            if ($execName -match "(?i)$sig") {
                $isMatch = $true
                $matchedSig = $sig
                break
            }
        }

        $entry = [PSCustomObject]@{
            File           = $file.Name
            Executable     = $execName
            LastExecution  = $file.LastWriteTime.ToString("o")
            Size           = $file.Length
            SignatureMatch = $matchedSig
            Flagged        = $isMatch
        }
        $Global:ReportData.PrefetchTraces += $entry

        if ($isMatch) {
            $flaggedCount++
            Write-Alert -Level "FLAG" -Message "SUSPICIOUS EXECUTABLE IN PREFETCH!" -Detail "$($file.Name) (Last Executed: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
        } elseif ($execName -in @("FSUTIL", "CMD", "POWERSHELL", "REGEDIT", "TASKKILL", "VSSADMIN")) {
            Write-Alert -Level "INFO" -Message "System utility execution in Prefetch" -Detail "$($file.Name) at $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
    }

    if ($flaggedCount -eq 0) {
        Write-Alert -Level "OK" -Message "No known cheat or cleaner signatures identified in recent Prefetch files."
    }
}


<#
    Gricko SS Tool - BAM/DAM Kernel Timestamps & UserAssist ROT13 Registry Scanner
#>

function Convert-Rot13 {
    param([string]$InputText)
    if ([string]::IsNullOrEmpty($InputText)) { return "" }
    $chars = $InputText.ToCharArray()
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $c = [int]$chars[$i]
        if ($c -ge 65 -and $c -le 90) {
            $chars[$i] = [char](65 + (($c - 65 + 13) % 26))
        } elseif ($c -ge 97 -and $c -le 122) {
            $chars[$i] = [char](97 + (($c - 97 + 13) % 26))
        }
    }
    return -join $chars
}

function Scan-BAMRegistry {
    param([int]$Hours = $HoursBAM)
    Write-SectionHeader "EXECUTION TRACES: BAM / DAM REGISTRY (PAST $Hours HOURS)"

    $bamBases = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings",
        "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings",
        "HKLM:\SYSTEM\CurrentControlSet\Services\dam\UserSettings"
    )

    $bamRoot = $null
    foreach ($path in $bamBases) {
        if (Test-Path $path) {
            $bamRoot = $path
            break
        }
    }

    if (-not $bamRoot) {
        Write-Alert -Level "WARN" -Message "BAM/DAM registry path not accessible." -Detail "Requires Administrator elevation."
        return
    }

    $timeCutoff = (Get-Date).AddHours(-$Hours)
    $subKeys = Get-ChildItem -Path $bamRoot -ErrorAction SilentlyContinue
    $totalFound = 0
    $flaggedCount = 0

    foreach ($key in $subKeys) {
        $sid = $key.PSChildName
        $prop = Get-ItemProperty -Path $key.PSPath

        foreach ($p in $prop.PSObject.Properties) {
            if ($p.Name -like "*\*" -and $p.Value -is [byte[]]) {
                $rawPath = $p.Name
                $bytes = $p.Value

                $execDate = $null

                if ($bytes.Length -ge 8) {
                    try {
                        $ft1 = [BitConverter]::ToInt64($bytes, 0)
                        if ($ft1 -gt 0) {
                            $d1 = [DateTime]::FromFileTime($ft1)
                            if ($d1.Year -ge 2020 -and $d1.Year -le 2035) {
                                $execDate = $d1
                            }
                        }
                    } catch {}
                }

                if (-not $execDate -and $bytes.Length -ge 16) {
                    try {
                        $ft2 = [BitConverter]::ToInt64($bytes, 8)
                        if ($ft2 -gt 0) {
                            $d2 = [DateTime]::FromFileTime($ft2)
                            if ($d2.Year -ge 2020 -and $d2.Year -le 2035) {
                                $execDate = $d2
                            }
                        }
                    } catch {}
                }

                if ($execDate -and $execDate -ge $timeCutoff) {
                    $totalFound++
                    $isMatch = $false
                    $matchedSig = ""

                    foreach ($sig in $Global:SuspiciousSignatures) {
                        if ($rawPath -match "(?i)$sig") {
                            $isMatch = $true
                            $matchedSig = $sig
                            break
                        }
                    }

                    $entry = [PSCustomObject]@{
                        SID            = $sid
                        BinaryPath     = $rawPath
                        LastExecution  = $execDate.ToString("o")
                        SignatureMatch = $matchedSig
                        Flagged        = $isMatch
                    }
                    $Global:ReportData.BAMTraces += $entry

                    if ($isMatch) {
                        $flaggedCount++
                        Write-Alert -Level "FLAG" -Message "BAM RECORD MATCHES CHEAT SIGNATURE!" -Detail "$rawPath (Executed: $($execDate.ToString('yyyy-MM-dd HH:mm:ss')))"
                    } elseif ($rawPath -like "*\AppData\Local\Temp\*" -or $rawPath -like "*\Downloads\*") {
                        if ($rawPath -like "*.exe" -or $rawPath -like "*.jar") {
                            Write-Alert -Level "WARN" -Message "Executable run from Temp/Downloads recorded in BAM" -Detail "$rawPath ($($execDate.ToString('yyyy-MM-dd HH:mm:ss')))"
                        }
                    }
                }
            }
        }
    }

    if ($totalFound -gt 0) {
        Write-Alert -Level "INFO" -Message "Identified $totalFound recent execution events across user accounts via BAM."
    } else {
        Write-Alert -Level "INFO" -Message "No BAM entries found within the last $Hours hours."
    }

    if ($flaggedCount -eq 0) {
        Write-Alert -Level "OK" -Message "No known cheat signatures detected in active BAM records."
    }
}

function Scan-UserAssist {
    Write-SectionHeader "EXECUTION TRACES: USERASSIST (ROT13 DECODED)"

    $uaBasePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
    if (-not (Test-Path $uaBasePath)) {
        Write-Alert -Level "INFO" -Message "UserAssist registry key not found."
        return
    }

    $guidKeys = Get-ChildItem -Path $uaBasePath
    $totalFound = 0
    $flaggedCount = 0

    foreach ($gKey in $guidKeys) {
        $countPath = Join-Path $gKey.PSPath "Count"
        if (Test-Path $countPath) {
            $props = (Get-ItemProperty -Path $countPath).PSObject.Properties
            foreach ($p in $props) {
                if ($p.Value -is [byte[]] -and $p.Value.Length -ge 68) {
                    $decodedName = Convert-Rot13 -InputText $p.Name
                    $bytes = $p.Value

                    $runCount = [BitConverter]::ToInt32($bytes, 4)
                    $execDate = $null

                    try {
                        $ft = [BitConverter]::ToInt64($bytes, 60)
                        if ($ft -gt 0) {
                            $d = [DateTime]::FromFileTime($ft)
                            if ($d.Year -ge 2020 -and $d.Year -le 2035) {
                                $execDate = $d
                            }
                        }
                    } catch {}

                    if ($decodedName -like "*.exe" -or $decodedName -like "*.jar" -or $decodedName -like "*.lnk") {
                        $totalFound++
                        $isMatch = $false
                        $matchedSig = ""

                        foreach ($sig in $Global:SuspiciousSignatures) {
                            if ($decodedName -match "(?i)$sig") {
                                $isMatch = $true
                                $matchedSig = $sig
                                break
                            }
                        }

                        $entry = [PSCustomObject]@{
                            GUID          = $gKey.PSChildName
                            DecodedPath   = $decodedName
                            RunCount      = $runCount
                            LastExecution = if ($execDate) { $execDate.ToString("o") } else { "N/A" }
                            SignatureMatch= $matchedSig
                            Flagged       = $isMatch
                        }
                        $Global:ReportData.UserAssistTraces += $entry

                        if ($isMatch) {
                            $flaggedCount++
                            Write-Alert -Level "FLAG" -Message "USERASSIST MATCH FOR KNOWN CHEAT SIGNATURE!" -Detail "$decodedName (Runs: $runCount | Last: $(if ($execDate){$execDate.ToString('yyyy-MM-dd HH:mm:ss')}else{'N/A'}))"
                        }
                    }
                }
            }
        }
    }

    if ($totalFound -gt 0) {
        Write-Alert -Level "INFO" -Message "Decoded $totalFound application execution traces from UserAssist."
    }
    if ($flaggedCount -eq 0) {
        Write-Alert -Level "OK" -Message "No known cheat signatures present in UserAssist history."
    }
}


<#
    Gricko SS Tool - File System, Mods, Temp Drops & Anti-Forensics Scanner
#>

function Scan-FileSystem {
    param([int]$Hours = $HoursFiles)
    Write-SectionHeader "FILE SYSTEM, TEMP & ANTI-FORENSICS SCANS"

    $timeCutoff = (Get-Date).AddHours(-$Hours)

    # 1. Minecraft Mods Directory Scan
    $mcModsPath = Join-Path $env:APPDATA ".minecraft\mods"
    if (Test-Path $mcModsPath) {
        $mods = Get-ChildItem -Path $mcModsPath -File
        Write-Alert -Level "INFO" -Message "Found Minecraft mods directory" -Detail "Path: $mcModsPath ($($mods.Count) files)"

        $modFlags = 0
        foreach ($mod in $mods) {
            $isRecent = ($mod.LastWriteTime -ge $timeCutoff)
            $isSusName = $false
            $matchedSig = ""

            foreach ($sig in $Global:SuspiciousSignatures) {
                if ($mod.Name -match "(?i)$sig") {
                    $isSusName = $true
                    $matchedSig = $sig
                    break
                }
            }

            $isAbnormalExt = ($mod.Extension -notin @(".jar", ".litemod", ".disabled"))

            $entry = [PSCustomObject]@{
                FileName      = $mod.Name
                FullPath      = $mod.FullName
                SizeKB        = [math]::Round($mod.Length / 1KB, 2)
                LastWriteTime = $mod.LastWriteTime.ToString("o")
                Recent        = $isRecent
                Flagged       = ($isSusName -or $isAbnormalExt)
                Reason        = if ($isSusName) { "Signature: $matchedSig" } elseif ($isAbnormalExt) { "Abnormal Extension: $($mod.Extension)" } else { "Clean" }
            }
            $Global:ReportData.ModFiles += $entry

            if ($isSusName) {
                $modFlags++
                Write-Alert -Level "FLAG" -Message "CHEAT MOD DETECTED IN MODS DIRECTORY!" -Detail "$($mod.Name) (Matches: $matchedSig)"
            } elseif ($isAbnormalExt) {
                $modFlags++
                Write-Alert -Level "FLAG" -Message "ABNORMAL FILE DETECTED IN MODS DIRECTORY!" -Detail "$($mod.Name) (Extension: $($mod.Extension))"
            } elseif ($isRecent) {
                Write-Alert -Level "WARN" -Message "Mod file recently modified (within $Hours hours)" -Detail "$($mod.Name) at $($mod.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            }
        }

        if ($modFlags -eq 0) {
            Write-Alert -Level "OK" -Message "No known cheat clients or abnormal files detected in .minecraft\mods."
        }
    } else {
        Write-Alert -Level "INFO" -Message "No standard .minecraft\mods directory found at $mcModsPath."
    }

    # 2. Temp Directories Inspection
    $tempPaths = @($env:TEMP, "$env:LOCALAPPDATA\Temp") | Select-Object -Unique
    $tempFilesFound = 0
    $tempFlags = 0

    foreach ($tPath in $tempPaths) {
        if (Test-Path $tPath) {
            $recentTemp = Get-ChildItem -Path $tPath -File -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -ge $timeCutoff -and ($_.Extension -in @(".jar", ".dll", ".exe", ".class")) }

            foreach ($tf in $recentTemp) {
                $tempFilesFound++
                $isSus = $false
                $matchedSig = ""

                foreach ($sig in $Global:SuspiciousSignatures) {
                    if ($tf.Name -match "(?i)$sig") {
                        $isSus = $true
                        $matchedSig = $sig
                        break
                    }
                }

                $entry = [PSCustomObject]@{
                    FileName      = $tf.Name
                    FullPath      = $tf.FullName
                    Extension     = $tf.Extension
                    SizeKB        = [math]::Round($tf.Length / 1KB, 2)
                    LastWriteTime = $tf.LastWriteTime.ToString("o")
                    Flagged       = $isSus
                }
                $Global:ReportData.TempFiles += $entry

                if ($isSus) {
                    $tempFlags++
                    Write-Alert -Level "FLAG" -Message "SUSPICIOUS PAYLOAD IN TEMP DIRECTORY!" -Detail "$($tf.FullName) (Signature: $matchedSig)"
                } elseif ($tf.Extension -eq ".jar" -or $tf.Extension -eq ".dll") {
                    Write-Alert -Level "WARN" -Message "Recently dropped executable/library in Temp" -Detail "$($tf.Name) at $($tf.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
                }
            }
        }
    }

    if ($tempFilesFound -eq 0) {
        Write-Alert -Level "OK" -Message "No recently created .jar or .dll binaries found in Temp."
    } elseif ($tempFlags -eq 0) {
        Write-Alert -Level "OK" -Message "No known cheat signatures in recent Temp drops."
    }

    # 3. Downloads Directory Inspection
    $dlPath = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path $dlPath) {
        $recentDownloads = Get-ChildItem -Path $dlPath -File |
            Where-Object { $_.LastWriteTime -ge $timeCutoff -and ($_.Extension -in @(".jar", ".exe", ".zip", ".rar", ".7z")) }

        foreach ($dl in $recentDownloads) {
            $isSus = $false
            $matchedSig = ""

            foreach ($sig in $Global:SuspiciousSignatures) {
                if ($dl.Name -match "(?i)$sig") {
                    $isSus = $true
                    $matchedSig = $sig
                    break
                }
            }

            $entry = [PSCustomObject]@{
                FileName      = $dl.Name
                FullPath      = $dl.FullName
                SizeKB        = [math]::Round($dl.Length / 1KB, 2)
                LastWriteTime = $dl.LastWriteTime.ToString("o")
                Flagged       = $isSus
            }
            $Global:ReportData.DownloadFiles += $entry

            if ($isSus) {
                Write-Alert -Level "FLAG" -Message "CHEAT UTILITY IN RECENT DOWNLOADS!" -Detail "$($dl.Name) (Matches: $matchedSig)"
            }
        }
    }

    # 4. Anti-Forensics & Log Tampering Checks
    $logClearCutoff = (Get-Date).AddHours(-72)
    $clearedEvents = @()

    try {
        $clearedEvents += Get-WinEvent -FilterHashtable @{LogName='Security'; Id=1102; StartTime=$logClearCutoff} -ErrorAction SilentlyContinue
    } catch {}
    try {
        $clearedEvents += Get-WinEvent -FilterHashtable @{LogName='System'; Id=104; StartTime=$logClearCutoff} -ErrorAction SilentlyContinue
    } catch {}

    if ($clearedEvents.Count -gt 0) {
        foreach ($ev in $clearedEvents) {
            Write-Alert -Level "FLAG" -Message "EVENT LOG PURGE DETECTED (ANTI-FORENSICS)!" -Detail "Log: $($ev.LogName) cleared at $($ev.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))"
            $Global:ReportData.AntiForensics += [PSCustomObject]@{
                Type        = "EventLogCleared"
                LogName     = $ev.LogName
                TimeCreated = $ev.TimeCreated.ToString("o")
                Id          = $ev.Id
            }
        }
    } else {
        Write-Alert -Level "OK" -Message "No Security or System event log clearances recorded in the last 72 hours."
    }

    # 5. Check USN Journal State
    try {
        $usnOutput = & fsutil usn queryjournal C: 2>&1
        $usnText = $usnOutput -join " "
        if ($usnText -like "*is not active*" -or $usnText -like "*Error:*") {
            Write-Alert -Level "FLAG" -Message "USN JOURNAL HAS BEEN DELETED OR DISABLED ON DRIVE C:!" -Detail "Critical anti-forensics indicator used to erase file deletion history."
            $Global:ReportData.AntiForensics += [PSCustomObject]@{
                Type    = "USNJournalDisabled"
                Message = $usnText
            }
        } else {
            Write-Alert -Level "OK" -Message "NTFS USN Change Journal is active and healthy on volume C:."
        }
    } catch {
        Write-Alert -Level "INFO" -Message "Could not query USN Journal status (requires admin privileges)."
    }

    # 6. Check Recycle Bin
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.Namespace(10)
        $rbCount = $recycleBin.Items().Count
        Write-Alert -Level "INFO" -Message "Recycle Bin item count: $rbCount"
        
        foreach ($item in $recycleBin.Items()) {
            if ($item.Name -like "*.jar" -or $item.Name -like "*.exe") {
                Write-Alert -Level "WARN" -Message "Executable or JAR located inside Recycle Bin" -Detail $item.Name
            }
        }
    } catch {}
}


<#
    Gricko SS Tool - Hardware & USB Storage Forensic Scanner
#>

function Scan-USBStorage {
    Write-SectionHeader "HARDWARE & STORAGE TRACES: USB STOR HISTORY"

    $usbStorPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (-not (Test-Path $usbStorPath)) {
        Write-Alert -Level "INFO" -Message "No USBSTOR registry key present or accessible."
        return
    }

    $devices = Get-ChildItem -Path $usbStorPath
    if (-not $devices) {
        Write-Alert -Level "OK" -Message "No USB storage devices recorded in registry history."
        return
    }

    Write-Alert -Level "INFO" -Message "Enumerated $($devices.Count) historical USB storage devices."

    foreach ($dev in $devices) {
        $devName = $dev.PSChildName
        $instances = Get-ChildItem -Path $dev.PSPath

        foreach ($inst in $instances) {
            $prop = Get-ItemProperty -Path $inst.PSPath
            $friendly = if ($prop.FriendlyName) { $prop.FriendlyName } else { "Generic USB Storage Device" }
            $service = $prop.Service

            $entry = [PSCustomObject]@{
                DeviceIdentifier = $devName
                InstanceId       = $inst.PSChildName
                FriendlyName     = $friendly
                Service          = $service
            }
            $Global:ReportData.USBDevices += $entry

            Write-Alert -Level "INFO" -Message "USB Storage Device in Registry" -Detail "$friendly ($devName)"
        }
    }

    # Query currently connected USB Disks
    try {
        $activeUSB = Get-CimInstance Win32_DiskDrive -Filter "InterfaceType = 'USB'"
        if ($activeUSB) {
            foreach ($usb in $activeUSB) {
                Write-Alert -Level "WARN" -Message "ACTIVE USB DRIVE CURRENTLY CONNECTED!" -Detail "$($usb.Model) (DeviceID: $($usb.DeviceID) | Size: $([math]::Round($usb.Size / 1GB, 2)) GB)"
            }
        } else {
            Write-Alert -Level "OK" -Message "No active/removable USB storage drives currently mounted."
        }
    } catch {}
}


<#
    Gricko SS Tool - Scorecard & JSON Report Exporter
#>

function Export-Report {
    param(
        [switch]$ExportJson,
        [string]$OutputPath
    )

    Write-Host ""
    Write-PurpleBorder "GRICKO SS TOOL FORENSIC SCORECARD"

    $flags = $Global:ReportData.Scorecard.Flags
    $warns = $Global:ReportData.Scorecard.Warnings
    $cleans = $Global:ReportData.Scorecard.Clean

    Write-Host "  CRITICAL FLAGS RAISED: " -NoNewline -ForegroundColor White
    if ($flags -gt 0) {
        Write-Host "$flags [ACTION REQUIRED - POTENTIAL CHEATING DETECTED]" -ForegroundColor Red
    } else {
        Write-Host "0 [CLEAN]" -ForegroundColor Green
    }

    Write-Host "  WARNINGS / ANOMALIES : " -NoNewline -ForegroundColor White
    if ($warns -gt 0) {
        Write-Host "$warns [STAFF REVIEW SUGGESTED]" -ForegroundColor Yellow
    } else {
        Write-Host "0" -ForegroundColor Green
    }

    Write-Host "  VERIFIED CLEAN CHECKS: " -NoNewline -ForegroundColor White
    Write-Host "$cleans" -ForegroundColor Green
    Write-Host ""

    if ($ExportJson -or $OutputPath) {
        $targetFile = $OutputPath
        if (-not $targetFile) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $targetFile = "Gricko_Report_${timestamp}.json"
        }

        try {
            $Global:ReportData | ConvertTo-Json -Depth 6 | Set-Content -Path $targetFile -Encoding UTF8
            Write-Alert -Level "OK" -Message "Complete forensic report exported to JSON" -Detail $targetFile
        } catch {
            Write-Alert -Level "WARN" -Message "Failed to export JSON report" -Detail $_.Exception.Message
        }
    }
}


<#
    Gricko SS Tool - Minimalist Ocean-Style Automated Screenshare GUI
    Compact Floating Window with Fishbone Logo, 2-Minute Deep Scan & Clean Results
#>

function Show-GrickoGui {
    param(
        [int]$HoursPrefetch = 168, # 7 days deep scan
        [int]$HoursFiles = 72,
        [int]$HoursBAM = 168
    )

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    $logoBase64 = "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"

    function Get-LogoSource {
        try {
            $bytes = [Convert]::FromBase64String($logoBase64)
            $ms = [System.IO.MemoryStream]::new($bytes)
            $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
            $bi.BeginInit()
            $bi.StreamSource = $ms
            $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bi.EndInit()
            $bi.Freeze()
            return $bi
        } catch {
            return $null
        }
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gricko SS Tool"
        Height="460" Width="580"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        ResizeMode="CanMinimize">

    <Window.Resources>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="5"/>
            <Setter Property="Background" Value="#101114"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="#101114">
                            <Track x:Name="PART_Track" IsDirectionReversed="true">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border Background="#3A3D4A" CornerRadius="2"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Name="RootBorder" CornerRadius="14" BorderThickness="1.2" BorderBrush="#252833">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                <GradientStop Color="#15161A" Offset="0.0"/>
                <GradientStop Color="#0E0F13" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.Background>

        <Grid Margin="18">
            <Grid.RowDefinitions>
                <RowDefinition Height="32"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="24"/>
            </Grid.RowDefinitions>

            <!-- TOP BAR: MINIMAL CONTROLS (NO EXTRA TEXT) -->
            <Grid Grid.Row="0" Name="TitleBarGrid" Background="Transparent">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button Name="BtnMin" Content="-" Width="30" Height="24" Background="#1A1C24" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand" Margin="0,0,5,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnClose" Content="X" Width="30" Height="24" Background="#1A1C24" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- BODY CONTENT -->
            <Grid Grid.Row="1">

                <!-- VIEW 1: HOME (SCAN LAUNCHER) -->
                <StackPanel Name="HomeView" Visibility="Visible" HorizontalAlignment="Center" VerticalAlignment="Center">
                    
                    <!-- Fishbone Transparent Logo -->
                    <Border Margin="0,0,0,16" HorizontalAlignment="Center">
                        <Image Name="LogoImgHome" Width="140" Height="70" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
                    </Border>

                    <!-- Scan Action Button -->
                    <Border CornerRadius="24" Background="#1E202B" BorderBrush="#323648" BorderThickness="1.2" HorizontalAlignment="Center" Margin="0,0,0,16">
                        <Button Name="BtnScan" Content="DEEP SCAN PC" Width="210" Height="46" FontSize="13" FontWeight="Bold" Foreground="#FFFFFF" Background="Transparent" BorderThickness="0" Cursor="Hand">
                            <Button.Style>
                                <Style TargetType="Button">
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="Button">
                                                <Border Name="btnBdr" Background="Transparent" CornerRadius="24">
                                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="btnBdr" Property="Background" Value="#2A2D3D"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </Button.Style>
                        </Button>
                    </Border>

                    <TextBlock Text="Comprehensive Minecraft Forensics &amp; Client Inspector" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- VIEW 2: PROGRESS (2-MINUTE DEEP SCAN) -->
                <StackPanel Name="ProgressView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="440">
                    <Image Name="LogoImgProgress" Width="110" Height="54" HorizontalAlignment="Center" Margin="0,0,0,14" RenderOptions.BitmapScalingMode="HighQuality"/>
                    
                    <TextBlock Text="DEEP SCANNING SYSTEM" Foreground="#F8FAFC" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                    <TextBlock Text="Thorough inspection of processes, prefetch, BAM, registry &amp; game instances..." Foreground="#64748B" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,20"/>

                    <!-- Progress Bar (Silver Neon) -->
                    <Border CornerRadius="8" Height="14" Background="#1B1D26" Margin="0,0,0,12" ClipToBounds="True">
                        <ProgressBar Name="ScanProgress" Height="14" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0">
                            <ProgressBar.Foreground>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#CBD5E1" Offset="0.0"/>
                                    <GradientStop Color="#FFFFFF" Offset="1.0"/>
                                </LinearGradientBrush>
                            </ProgressBar.Foreground>
                        </ProgressBar>
                    </Border>

                    <!-- Status Text -->
                    <TextBlock Name="TxtProgressStatus" Text="Initializing deep PC inspection... - 0%" Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- VIEW 3: CLEAN RESULTS SUMMARY (ONLY CLIENT & SUS MODS) -->
                <StackPanel Name="ResultsView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="460">
                    <Image Name="LogoImgResults" Width="110" Height="54" HorizontalAlignment="Center" Margin="0,0,0,8" RenderOptions.BitmapScalingMode="HighQuality"/>
                    
                    <TextBlock Name="TxtResultTitle" Text="Scan Complete" Foreground="#F8FAFC" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                    <TextBlock Name="TxtResultSubtitle" Text="System inspection finished" Foreground="#34D399" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,12"/>

                    <!-- Client & Last Instance Info Card -->
                    <Border Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,10" Margin="0,0,0,10">
                        <StackPanel>
                            <DockPanel Margin="0,0,0,4">
                                <TextBlock Text="ACTIVE / LAST PLAYED MINECRAFT CLIENT" Foreground="#94A3B8" FontSize="10.5" FontWeight="Bold"/>
                                <TextBlock Name="TxtResultTime" Text="N/A" Foreground="#38BDF8" FontSize="10.5" FontWeight="Bold" HorizontalAlignment="Right"/>
                            </DockPanel>
                            <TextBlock Name="TxtResultClient" Text="Client   : Detecting..." Foreground="#E2E8F0" FontSize="12" FontWeight="SemiBold" Margin="0,1"/>
                            <TextBlock Name="TxtResultProfile" Text="Profile  : Standard" Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtResultServer" Text="Server   : None" Foreground="#38BDF8" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Border>

                    <!-- Cheat Detection Result Box -->
                    <Border Name="DetectionBox" Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,8" Margin="0,0,0,14">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="TxtDetectionsBadge" Text="[OK] No Cheats or Suspicious Clients Detected" Foreground="#34D399" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtCheatList" Text="" Foreground="#F87171" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,3,0,0" Visibility="Collapsed"/>
                        </StackPanel>
                    </Border>

                    <!-- Action Buttons -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button Name="BtnDetails" Content="DETAILS" Width="120" Height="34" FontSize="12" FontWeight="Bold" Foreground="#FFFFFF" Background="#262A38" BorderBrush="#3B4259" BorderThickness="1" Cursor="Hand" Margin="0,0,10,0">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                        <Button Name="BtnRescan" Content="RE-SCAN" Width="100" Height="34" FontSize="12" FontWeight="Bold" Foreground="#94A3B8" Background="#161822" BorderThickness="0" Cursor="Hand">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                    </StackPanel>
                </StackPanel>

                <!-- VIEW 4: CLEAN DETAILS INSPECTOR (NO CODE, NO SPAM) -->
                <Grid Name="DetailsView" Visibility="Collapsed" Height="350" Margin="4,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,8">
                        <TextBlock Text="FORENSIC INSPECTION DETAILS" Foreground="#F8FAFC" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button Name="BtnBackFromDetails" Content="&lt;- Back" Background="Transparent" Foreground="#38BDF8" BorderThickness="0" FontSize="12" FontWeight="SemiBold" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>

                    <!-- Clean Categorized Details Log -->
                    <Border Grid.Row="1" Background="#0C0D11" CornerRadius="8" BorderBrush="#1C1E26" BorderThickness="1" Padding="12">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Name="DetailsContentPanel">
                                <!-- Populated dynamically with clean human-readable details -->
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <DockPanel Grid.Row="2" Margin="0,8,0,0">
                        <TextBlock Name="TxtSummaryStats" Text="Clean Forensics" Foreground="#64748B" FontSize="11" VerticalAlignment="Center"/>
                        <Button Name="BtnExportJson" Content="Export Full JSON" Height="26" Padding="12,0" Background="#1A1D27" Foreground="#C084FC" BorderThickness="0" FontSize="11" FontWeight="SemiBold" Cursor="Hand" HorizontalAlignment="Right">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="4"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                    </DockPanel>
                </Grid>

            </Grid>

            <!-- FOOTER WATERMARK -->
            <Grid Grid.Row="2">
                <TextBlock Text="powered by Gricko SS Tool" Foreground="#475569" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,4,2"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # UI Element Handles
    $rootBorder        = $window.FindName("RootBorder")
    $titleBarGrid      = $window.FindName("TitleBarGrid")
    $btnMin            = $window.FindName("BtnMin")
    $btnClose          = $window.FindName("BtnClose")

    $homeView          = $window.FindName("HomeView")
    $progressView      = $window.FindName("ProgressView")
    $resultsView       = $window.FindName("ResultsView")
    $detailsView       = $window.FindName("DetailsView")

    $logoImgHome       = $window.FindName("LogoImgHome")
    $logoImgProgress   = $window.FindName("LogoImgProgress")
    $logoImgResults    = $window.FindName("LogoImgResults")

    $btnScan           = $window.FindName("BtnScan")
    $btnRescan         = $window.FindName("BtnRescan")
    $btnDetails        = $window.FindName("BtnDetails")
    $btnBackFromDetails= $window.FindName("BtnBackFromDetails")
    $btnExportJson     = $window.FindName("BtnExportJson")

    $scanProgress      = $window.FindName("ScanProgress")
    $txtProgressStatus = $window.FindName("TxtProgressStatus")

    $txtResultTitle    = $window.FindName("TxtResultTitle")
    $txtResultSubtitle = $window.FindName("TxtResultSubtitle")
    $txtResultTime     = $window.FindName("TxtResultTime")
    $txtResultClient   = $window.FindName("TxtResultClient")
    $txtResultProfile  = $window.FindName("TxtResultProfile")
    $txtResultServer   = $window.FindName("TxtResultServer")

    $detectionBox      = $window.FindName("DetectionBox")
    $txtDetectionsBadge= $window.FindName("TxtDetectionsBadge")
    $txtCheatList      = $window.FindName("TxtCheatList")

    $detailsContentPanel = $window.FindName("DetailsContentPanel")
    $txtSummaryStats   = $window.FindName("TxtSummaryStats")

    # Set Transparent Logo on Image Controls
    $logoSrc = Get-LogoSource
    if ($logoSrc) {
        $logoImgHome.Source = $logoSrc
        $logoImgProgress.Source = $logoSrc
        $logoImgResults.Source = $logoSrc
    }

    # FREE WINDOW DRAGGING FROM ANYWHERE
    $dragAction = {
        param($sender, $e)
        if ($e.LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            $window.DragMove()
        }
    }
    $window.Add_MouseLeftButtonDown($dragAction)
    $rootBorder.Add_MouseLeftButtonDown($dragAction)
    $titleBarGrid.Add_MouseLeftButtonDown($dragAction)

    # Window Control Actions
    $btnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnClose.Add_Click({ $window.Close() })

    # Navigation Actions
    $btnDetails.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnBackFromDetails.Add_Click({
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnRescan.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $homeView.Visibility = [System.Windows.Visibility]::Visible
    })

    function Pump-WpfEvents {
        $frame = [System.Windows.Threading.DispatcherFrame]::new()
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [Action[object]]{ param($f) $f.Continue = $false },
            $frame
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }

    function Add-CleanSectionHeader {
        param([string]$Title)
        $tb = [System.Windows.Controls.TextBlock]::new()
        $tb.Text = $Title.ToUpper()
        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#818CF8")
        $tb.FontWeight = [System.Windows.FontWeights]::Bold
        $tb.FontSize = 11.5
        $tb.Margin = [System.Windows.Thickness]::new(0, 10, 0, 4)
        $detailsContentPanel.Children.Add($tb) | Out-Null
    }

    function Add-CleanRow {
        param(
            [string]$Label,
            [string]$Value,
            [string]$Color = "#E2E8F0"
        )
        $sp = [System.Windows.Controls.DockPanel]::new()
        $sp.Margin = [System.Windows.Thickness]::new(4, 2, 0, 2)

        $tbLbl = [System.Windows.Controls.TextBlock]::new()
        $tbLbl.Text = $Label
        $tbLbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
        $tbLbl.FontWeight = [System.Windows.FontWeights]::Bold
        $tbLbl.Width = 90
        $tbLbl.FontSize = 11.5
        [System.Windows.Controls.DockPanel]::SetDock($tbLbl, [System.Windows.Controls.Dock]::Left)
        $sp.Children.Add($tbLbl) | Out-Null

        $tbVal = [System.Windows.Controls.TextBlock]::new()
        $tbVal.Text = $Value
        $tbVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
        $tbVal.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $tbVal.FontSize = 11.5
        $sp.Children.Add($tbVal) | Out-Null

        $detailsContentPanel.Children.Add($sp) | Out-Null
    }

    # 2-Minute Deep Scan Runner
    $btnScan.Add_Click({
        $homeView.Visibility = [System.Windows.Visibility]::Collapsed
        $progressView.Visibility = [System.Windows.Visibility]::Visible
        $detailsContentPanel.Children.Clear()

        # Reset state
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $Global:ReportData.CheatClients = @()
        $Global:ReportData.LegitClients = @()

        # Step 1: Memory & Active Process Inspection (0% to 15% - ~18s)
        for ($pct = 1; $pct -le 15; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Scanning active memory & running processes... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-JavaProcesses
        Pump-WpfEvents

        # Step 2: Minecraft Instances, Versions & Logs (15% to 35% - ~24s)
        Scan-LastPlayedInstance
        for ($pct = 16; $pct -le 35; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Deep scanning Minecraft instances, versions & mods... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }

        # Step 3: Windows Prefetch & BAM Execution History (35% to 60% - ~30s)
        for ($pct = 36; $pct -le 60; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Scanning Windows Prefetch & BAM kernel timestamps... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-PrefetchTraces -Hours $HoursPrefetch
        Scan-BAMRegistry -Hours $HoursBAM
        Pump-WpfEvents

        # Step 4: UserAssist & MuiCache Application History (60% to 80% - ~24s)
        for ($pct = 61; $pct -le 80; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Auditing UserAssist ROT13 & execution traces... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-UserAssist
        Pump-WpfEvents

        # Step 5: File System, Temp drops & Anti-Forensics (80% to 95% - ~18s)
        for ($pct = 81; $pct -le 95; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Auditing file systems, temp drops & anti-forensics... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-FileSystem -Hours $HoursFiles
        Scan-USBStorage
        Pump-WpfEvents

        # Step 6: Finalizing & Compiling Report (95% to 100% - ~6s)
        for ($pct = 96; $pct -le 100; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Finalizing forensic report & scorecard... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }

        # Format Clean Results
        $inst = $Global:ReportData.LastPlayedInstance
        $timeStr = $null
        $launcherStr = $null
        $profileStr = "Standard Profile"
        $versionStr = ""

        if ($inst) {
            $timeStr = if ($inst.LastPlayedTime) { $inst.LastPlayedTime } elseif ($inst.LastPlayed) { $inst.LastPlayed } else { $null }
            $launcherStr = if ($inst.LauncherName) { $inst.LauncherName } elseif ($inst.Launcher) { $inst.Launcher } else { $null }
            $profileStr = if ($inst.ProfileName) { $inst.ProfileName } elseif ($inst.Profile) { $inst.Profile } else { "Standard Profile" }
            $versionStr = if ($inst.Version) { $inst.Version } else { "" }
        }

        # Fallback 1: Active running Java/Minecraft process
        if (-not $launcherStr -and $Global:ReportData.JavaProcesses -and $Global:ReportData.JavaProcesses.Count -gt 0) {
            $jp = $Global:ReportData.JavaProcesses[0]
            $launcherStr = "Active Java (PID $($jp.ProcessId))"
            $timeStr = "Running Right Now"
            $profileStr = "Active Game Session"
        }

        # Fallback 2: Check any prefetch/BAM traces
        if (-not $launcherStr) {
            $pfMatch = $Global:Findings | Where-Object { $_.Detail -like "*javaw.exe*" -or $_.Detail -like "*minecraft.exe*" -or $_.Detail -like "*lunar*" -or $_.Detail -like "*feather*" -or $_.Detail -like "*badlion*" } | Select-Object -First 1
            if ($pfMatch) {
                $launcherStr = "Minecraft (Prefetch / BAM Trace)"
                $timeStr = "Recent Execution Trace"
                $profileStr = "Historical Instance"
            }
        }

        if ($launcherStr) {
            $txtResultTime.Text = if ($timeStr) { "$timeStr" } else { "Active / Recent" }
            $txtResultClient.Text = "Client   : $launcherStr"
            $txtResultProfile.Text = if ($versionStr -and $versionStr -ne "Unknown") { "Profile  : $profileStr ($versionStr)" } else { "Profile  : $profileStr" }
            if ($inst -and $inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
                $txtResultServer.Text = "Server   : $($inst.ConnectedServers -join ', ')"
            } else {
                $txtResultServer.Text = "Server   : Singleplayer / Unrecorded"
            }
        } else {
            $txtResultTime.Text = "No Instance Found"
            $txtResultClient.Text = "Client   : No Minecraft installation detected"
            $txtResultProfile.Text = "Profile  : N/A"
            $txtResultServer.Text = "Server   : N/A"
        }

        # Filter actual cheat detections (Prestige, Grim, Vape, Drip, Slinky, Raven, etc.)
        $actualCheats = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($f in $Global:Findings) {
            if ($f.Level -eq "FLAG") {
                $msg = "$($f.Message) $($f.Detail)"
                if ($msg -like "*essential*" -or $msg -like "*theseus*" -or $msg -like "*imgui*" -or $msg -like "*jna*" -or $msg -like "*LOG WAS WIPED*") {
                    continue
                }

                $fileName = ""
                $filePath = ""
                $actionTime = ""

                if ($f.Detail -match "([^|\r\n]+)\s*\(Executed:\s*([^)]+)\)\s*\|\s*(.*)") {
                    $fileName = $matches[1].Trim()
                    $actionTime = $matches[2].Trim()
                    $filePath = $matches[3].Trim()
                } elseif ($f.Detail -match "([^|\r\n]+)\s*\(Last Executed:\s*([^)]+)\)") {
                    $fileName = $matches[1].Trim()
                    $actionTime = $matches[2].Trim()
                } elseif ($f.Detail -match "([^(\r\n]+)\s*\(Matches:\s*([^)]+)\)") {
                    $fileName = $matches[1].Trim()
                } else {
                    $fileName = $f.Detail
                }

                # Clean up filename
                if ($fileName -match '([^\\]+\.exe)') {
                    $fileName = $matches[1].Trim()
                }

                $actualCheats.Add([PSCustomObject]@{
                    File   = $fileName
                    Path   = $filePath
                    Time   = $actionTime
                    Reason = $f.Message
                })
            }
        }

        # Build Clean Details List (No codes, no bible, just human summary)
        $detailsContentPanel.Children.Clear()

        Add-CleanSectionHeader "MINECRAFT INSTANCE & SESSION"
        Add-CleanRow "Client"   $launcherStr "#38BDF8"
        Add-CleanRow "Profile"  $profileStr "#E2E8F0"
        Add-CleanRow "Played"   $timeStr "#34D399"
        if ($txtResultServer.Text -ne "Server   : None" -and $txtResultServer.Text -ne "Server   : N/A") {
            $srvText = if ($inst -and $inst.ConnectedServers) { $inst.ConnectedServers -join ", " } else { "Singleplayer" }
            Add-CleanRow "Server"   $srvText "#38BDF8"
        }

        Add-CleanSectionHeader "FLAGGED CHEAT & SUSPICIOUS FILES"
        if ($actualCheats.Count -gt 0) {
            $shownFiles = @()
            foreach ($c in $actualCheats) {
                if ($c.File -notin $shownFiles) {
                    $shownFiles += $c.File
                    Add-CleanRow "File"     $c.File "#EF4444"
                    if ($c.Path) { Add-CleanRow "Location" $c.Path "#94A3B8" }
                    if ($c.Time) { Add-CleanRow "Activity" "Executed $c.Time" "#FBBF24" }
                }
            }
        } else {
            Add-CleanRow "Status" "Clean: No cheat files or blacklisted loaders detected on this PC." "#34D399"
        }

        # Main Screen Cheat Badge
        if ($actualCheats.Count -gt 0) {
            $txtResultTitle.Text = "Cheats Detected"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $txtResultSubtitle.Text = "$($actualCheats.Count) suspicious or cheat client artifacts found"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
            $txtDetectionsBadge.Text = "[!] SUSPICIOUS CLIENT / CHEATS DETECTED"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $detectionBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#991B1B")

            $uniqueFiles = $actualCheats | ForEach-Object { $_.File } | Select-Object -Unique
            $txtCheatList.Text = "Flagged: " + ($uniqueFiles -join ", ")
            $txtCheatList.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $txtResultTitle.Text = "Scan Complete"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
            $txtResultSubtitle.Text = "All deep forensic tests concluded"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtDetectionsBadge.Text = "[OK] No Cheats or Suspicious Clients Detected"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $detectionBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#065F46")
            $txtCheatList.Visibility = [System.Windows.Visibility]::Collapsed
        }

        $txtSummaryStats.Text = "$($actualCheats.Count) Cheats Flagged | Full 2-Minute PC Deep Scan Finished"

        # Show Results View
        $progressView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
        Pump-WpfEvents
    })

    # Export JSON Handler
    $btnExportJson.Add_Click({
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $filename = "Gricko_SS_Report_${timestamp}.json"
        $savePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), $filename)
        try {
            $Global:ReportData | ConvertTo-Json -Depth 6 | Set-Content -Path $savePath -Encoding UTF8
            [System.Windows.MessageBox]::Show("Forensic report exported to Desktop:`n$savePath", "Gricko SS Tool", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            $msg = $_.Exception.Message
            [System.Windows.MessageBox]::Show("Failed to export report: $msg", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    $window.ShowDialog() | Out-Null
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
