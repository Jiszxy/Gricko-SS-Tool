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
$Global:ToolVersion = "2.1.0"
$Global:ScanStartTime = Get-Date
$Global:Findings = [System.Collections.Generic.List[PSCustomObject]]::new()

$Global:ReportData = [ordered]@{
    Metadata = [ordered]@{
        ToolName        = $Global:ToolName
        Version         = $Global:ToolVersion
        Theme           = "Purple-Blue Aesthetic (Ocean Inspired)"
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
    JavaProcesses = @()
    PrefetchTraces = @()
    BAMTraces = @()
    UserAssistTraces = @()
    ModFiles = @()
    TempFiles = @()
    DownloadFiles = @()
    AntiForensics = @()
    USBDevices = @()
}

# Known Minecraft cheat clients, autoclickers, injection utilities, and cleansers
$Global:SuspiciousSignatures = @(
    # Ghost & Blatant Clients
    "vape", "raven", "bplus", "drip", "slinky", "koid", "itami", "mango", "breeze", 
    "dream", "haru", "dope", "entropy", "whiteout", "phantom", "novoline", "rise", 
    "tenacity", "augustus", "moon", "badpack", "liquidbounce", "aristois", "wurst", 
    "meteor", "inertial", "sigma", "flux", "pandora", "fdp", "zeroday", "impact", 
    "bleachhack", "ares", "sigma5", "futureclient", "rusherhack", "kamiblue", "lambda",
    "lambda-client", "exhibition", "astolfo", "cleanerclient", "skidclient",

    # Autoclickers & Macros
    "autoclicker", "auto-clicker", "fastclick", "speedclick", "op-autoclicker", 
    "gs-autoclicker", "maxclicker", "murgee", "forgeclicker", "ghostclicker", 
    "jitterclicker", "butterflyclicker", "tinytask", "speedautoclicker", "clicker",
    "macrokey", "rebind", "x-mouse", "xmouse", "autoclick",

    # Injection & Memory Inspection
    "processhacker", "cheatengine", "x64dbg", "x32dbg", "dnspy", "ilspy", 
    "bytecodeviewer", "recaf", "javadecompiler", "injector", "dllinject", 
    "extremeinjector", "nativeinjector", "systeminformer", "scylla", "ghidra",

    # Anti-Forensics & Cleaners
    "bleachbit", "ccleaner", "usndelete", "journalcleaner", "privazer", 
    "eraser", "sdelete", "cleanmem", "ddelete", "redact", "stringcleaner",
    "eventlogcleaner", "wevtutil"
)


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

    # 1. Standard .minecraft (Vanilla, Forge, Fabric, OptiFine)
    $dotMc = Join-Path $env:APPDATA ".minecraft"
    if (Test-Path $dotMc) {
        $lpJson = Join-Path $dotMc "launcher_profiles.json"
        $latestLog = Join-Path $dotMc "logs\latest.log"

        $lastUsedTime = $null
        $profileName = "Default / Vanilla"
        $versionId = "Unknown"

        if (Test-Path $lpJson) {
            try {
                $lp = Get-Content -Raw -Path $lpJson | ConvertFrom-Json
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

        if (-not $lastUsedTime -and (Test-Path $latestLog)) {
            $lastUsedTime = (Get-Item $latestLog).LastWriteTime
        }

        if ($lastUsedTime) {
            $instances.Add([PSCustomObject]@{
                Launcher      = "Standard .minecraft (Vanilla/Forge/Fabric)"
                Profile       = $profileName
                Version       = $versionId
                Path          = $dotMc
                LogFile       = $latestLog
                LastPlayed    = $lastUsedTime
            })
        }
    }

    # 2. Lunar Client
    $lunarPath = Join-Path $env:USERPROFILE ".lunarclient"
    if (Test-Path $lunarPath) {
        $lunarLog = Join-Path $lunarPath "offline\multiver\logs\latest.log"
        if (-not (Test-Path $lunarLog)) {
            $lunarLog = Join-Path $lunarPath "logs\launcher\renderer.log"
        }
        if (Test-Path $lunarLog) {
            $instances.Add([PSCustomObject]@{
                Launcher   = "Lunar Client"
                Profile    = "Lunar MultiVer Profile"
                Version    = "Lunar"
                Path       = $lunarPath
                LogFile    = $lunarLog
                LastPlayed = (Get-Item $lunarLog).LastWriteTime
            })
        }
    }

    # 3. Badlion Client
    $badlionPath = Join-Path $env:APPDATA "Badlion Client"
    if (-not (Test-Path $badlionPath)) { $badlionPath = Join-Path $env:APPDATA ".minecraft\badlion" }
    if (Test-Path $badlionPath) {
        $blLog = Join-Path $badlionPath "logs\latest.log"
        if (Test-Path $blLog) {
            $instances.Add([PSCustomObject]@{
                Launcher   = "Badlion Client"
                Profile    = "Badlion Standard"
                Version    = "Badlion"
                Path       = $badlionPath
                LogFile    = $blLog
                LastPlayed = (Get-Item $blLog).LastWriteTime
            })
        }
    }

    # 4. Feather Client
    $featherPath = Join-Path $env:APPDATA ".feather"
    if (Test-Path $featherPath) {
        $featherLog = Join-Path $featherPath "logs\latest.log"
        if (Test-Path $featherLog) {
            $instances.Add([PSCustomObject]@{
                Launcher   = "Feather Client"
                Profile    = "Feather Profile"
                Version    = "Feather"
                Path       = $featherPath
                LogFile    = $featherLog
                LastPlayed = (Get-Item $featherLog).LastWriteTime
            })
        }
    }

    # 5. Prism Launcher / MultiMC
    $prismPath = Join-Path $env:APPDATA "PrismLauncher\instances"
    if (Test-Path $prismPath) {
        $prismDirs = Get-ChildItem -Path $prismPath -Directory
        foreach ($pDir in $prismDirs) {
            $pLog = Join-Path $pDir.FullName ".minecraft\logs\latest.log"
            if (Test-Path $pLog) {
                $instances.Add([PSCustomObject]@{
                    Launcher   = "Prism Launcher"
                    Profile    = $pDir.Name
                    Version    = "Prism"
                    Path       = $pDir.FullName
                    LogFile    = $pLog
                    LastPlayed = (Get-Item $pLog).LastWriteTime
                })
            }
        }
    }

    # 6. Modrinth Launcher (Theseus)
    $theseusPath = Join-Path $env:APPDATA "com.modrinth.theseus\profiles"
    if (Test-Path $theseusPath) {
        $modrinthDirs = Get-ChildItem -Path $theseusPath -Directory
        foreach ($mDir in $modrinthDirs) {
            $mLog = Join-Path $mDir.FullName "logs\latest.log"
            if (Test-Path $mLog) {
                $instances.Add([PSCustomObject]@{
                    Launcher   = "Modrinth App (Theseus)"
                    Profile    = $mDir.Name
                    Version    = "Modrinth Profile"
                    Path       = $mDir.FullName
                    LogFile    = $mLog
                    LastPlayed = (Get-Item $mLog).LastWriteTime
                })
            }
        }
    }

    # Pick the most recently launched instance
    $sortedInstances = $instances | Sort-Object LastPlayed -Descending
    $lastPlayed = $sortedInstances | Select-Object -First 1

    if ($lastPlayed) {
        Write-Host ""
        Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host "  |  " -NoNewline -ForegroundColor Magenta
        Write-Host "(*) LAST PLAYED INSTANCE IDENTIFIED (ACTIVE TARGET)" -NoNewline -ForegroundColor Yellow
        Write-Host "                  |" -ForegroundColor Magenta
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

        $Global:ReportData.LastPlayedInstance = [ordered]@{
            Launcher   = $lastPlayed.Launcher
            Profile    = $lastPlayed.Profile
            Version    = $lastPlayed.Version
            Path       = $lastPlayed.Path
            LogFile    = $lastPlayed.LogFile
            LastPlayed = $lastPlayed.LastPlayed.ToString("o")
        }

        # Deep Inspection of Instance latest.log
        if (Test-Path $lastPlayed.LogFile) {
            $logItem = Get-Item $lastPlayed.LogFile
            Write-Alert -Level "INFO" -Message "Analyzing session log file" -Detail "$($lastPlayed.LogFile) (Size: $([math]::Round($logItem.Length / 1KB, 2)) KB)"

            if ($logItem.Length -eq 0) {
                Write-Alert -Level "FLAG" -Message "INSTANCE LOG WAS WIPED OR EMPTY (0 BYTES)!" -Detail "Strong indicator of log clearing right before screenshare."
            } else {
                $logLines = Get-Content -Path $lastPlayed.LogFile -Tail 300 -ErrorAction SilentlyContinue

                $suspiciousLogHits = 0
                $connectedServers = @()

                foreach ($line in $logLines) {
                    if ($line -match "Connecting to ([^,\s]+)") {
                        $server = $matches[1].Trim()
                        if ($server -notin $connectedServers) {
                            $connectedServers += $server
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
                    Write-Alert -Level "OK" -Message "No known cheat signatures or injection traces found in latest.log."
                }
            }
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
    Gricko SS Tool - Ocean-Inspired Forensic Desktop UI (WPF / XAML)
    Modern Dark Purple & Blue Aesthetic with Interactive Scan Controls
#>

function Show-GrickoGui {
    param(
        [int]$HoursPrefetch = 48,
        [int]$HoursFiles = 24,
        [int]$HoursBAM = 72
    )

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gricko SS Tool - Ocean Forensic Suite"
        Height="720" Width="1000"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        ResizeMode="CanMinimize">

    <Window.Resources>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="6"/>
            <Setter Property="Background" Value="#0F1123"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="#0A0B14">
                            <Track x:Name="PART_Track" IsDirectionReversed="true">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border Background="#3B3F63" CornerRadius="3"/>
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

    <Border CornerRadius="12" BorderThickness="1.5">
        <Border.BorderBrush>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#8B5CF6" Offset="0.0"/>
                <GradientStop Color="#3B82F6" Offset="0.5"/>
                <GradientStop Color="#06B6D4" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0.2,1">
                <GradientStop Color="#0D0E1A" Offset="0.0"/>
                <GradientStop Color="#07080F" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.Background>

        <Grid Margin="18">
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/>
                <RowDefinition Height="120"/>
                <RowDefinition Height="75"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="65"/>
            </Grid.RowDefinitions>

            <!-- TITLE BAR -->
            <Grid Grid.Row="0" Name="TitleBarGrid" Background="Transparent">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="*" Foreground="#A855F7" FontSize="18" FontWeight="Bold" Margin="0,0,10,0"/>
                    <TextBlock Text="GRICKO SS TOOL" Foreground="#F8FAFC" FontSize="17" FontWeight="Bold" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                    <Border Background="#1E1B4B" CornerRadius="4" Padding="6,2" Margin="12,0,0,0" VerticalAlignment="Center" BorderBrush="#4338CA" BorderThickness="1">
                        <TextBlock Text="OCEAN SUITE v2.2" Foreground="#38BDF8" FontSize="11" FontWeight="SemiBold"/>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="BtnMin" Content="_" Width="36" Height="28" Background="#131526" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand" Margin="0,0,6,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="5"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnClose" Content="X" Width="36" Height="28" Background="#1E1428" Foreground="#F43F5E" BorderThickness="0" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="5"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- TARGET & SYSTEM CARDS -->
            <Grid Grid.Row="1" Margin="0,8,0,8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="14"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Target Instance Card -->
                <Border Grid.Column="0" Background="#101222" CornerRadius="8" BorderBrush="#252847" BorderThickness="1" Padding="14,10">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <DockPanel Grid.Row="0" Margin="0,0,0,6">
                            <TextBlock Text="TARGET MINECRAFT INSTANCE" Foreground="#A78BFA" FontSize="11" FontWeight="Bold"/>
                            <Border Name="TargetStatusBadge" Background="#064E3B" CornerRadius="4" Padding="6,1" HorizontalAlignment="Right">
                                <TextBlock Name="TargetStatusText" Text="ANALYZING..." Foreground="#34D399" FontSize="10" FontWeight="Bold"/>
                            </Border>
                        </DockPanel>
                        <StackPanel Grid.Row="1" VerticalAlignment="Center">
                            <TextBlock Name="TxtLauncher" Text="Launcher : Detecting..." Foreground="#E2E8F0" FontSize="12" Margin="0,1"/>
                            <TextBlock Name="TxtProfile" Text="Profile  : Detecting..." Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtLastPlayed" Text="Last Run : Detecting..." Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtServer" Text="Server   : None detected" Foreground="#38BDF8" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- System & Elevation Card -->
                <Border Grid.Column="2" Background="#101222" CornerRadius="8" BorderBrush="#252847" BorderThickness="1" Padding="14,10">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <DockPanel Grid.Row="0" Margin="0,0,0,6">
                            <TextBlock Text="SYSTEM &amp; INTEGRITY STATUS" Foreground="#60A5FA" FontSize="11" FontWeight="Bold"/>
                            <Border Name="AdminBadge" Background="#1E1B4B" CornerRadius="4" Padding="6,1" HorizontalAlignment="Right">
                                <TextBlock Name="TxtAdmin" Text="CHECKING..." Foreground="#38BDF8" FontSize="10" FontWeight="Bold"/>
                            </Border>
                        </DockPanel>
                        <StackPanel Grid.Row="1" VerticalAlignment="Center">
                            <TextBlock Name="TxtHost" Text="Hostname : Detecting..." Foreground="#E2E8F0" FontSize="12" Margin="0,1"/>
                            <TextBlock Name="TxtUser" Text="User     : Detecting..." Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtEngine" Text="Engine   : Gricko Forensic Core v2.2.0" Foreground="#A78BFA" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtScanState" Text="Status   : Ready for inspection" Foreground="#34D399" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </Grid>

            <!-- SCAN CONTROL ACTION AREA -->
            <Border Grid.Row="2" Background="#101222" CornerRadius="8" BorderBrush="#252847" BorderThickness="1" Padding="14,10" Margin="0,0,0,8">
                <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="220"/>
                        <ColumnDefinition Width="16"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Button Name="BtnScan" Content="START SCAN" Height="44" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" Cursor="Hand">
                        <Button.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                <GradientStop Color="#7C3AED" Offset="0.0"/>
                                <GradientStop Color="#2563EB" Offset="1.0"/>
                            </LinearGradientBrush>
                        </Button.Background>
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>

                    <StackPanel Grid.Column="2" VerticalAlignment="Center">
                        <DockPanel Margin="0,0,0,6">
                            <TextBlock Name="TxtProgressStatus" Text="Ready to scan. Click 'START SCAN' to begin forensic analysis." Foreground="#94A3B8" FontSize="11"/>
                            <TextBlock Name="TxtPercent" Text="0%" Foreground="#38BDF8" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right"/>
                        </DockPanel>
                        <ProgressBar Name="ScanProgress" Height="8" Minimum="0" Maximum="100" Value="0" Background="#0A0B14" BorderThickness="0">
                            <ProgressBar.Foreground>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#8B5CF6" Offset="0.0"/>
                                    <GradientStop Color="#38BDF8" Offset="1.0"/>
                                </LinearGradientBrush>
                            </ProgressBar.Foreground>
                        </ProgressBar>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- LIVE ACTIVITY LOG CONSOLE -->
            <Border Grid.Row="3" Background="#06070E" CornerRadius="8" BorderBrush="#1C1F38" BorderThickness="1" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <DockPanel Grid.Row="0" Margin="4,0,4,6">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="[Live]" Foreground="#38BDF8" FontSize="11" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,6,0"/>
                            <TextBlock Text="FORENSIC ACTIVITY FEED" Foreground="#94A3B8" FontSize="11" FontWeight="Bold"/>
                        </StackPanel>
                        <TextBlock Name="BtnClearLogs" Text="Clear View" Foreground="#64748B" FontSize="11" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>
                    <ListBox Grid.Row="1" Name="LogListBox" Background="Transparent" BorderThickness="0" FontFamily="Consolas, Segoe UI" FontSize="12" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemContainerStyle>
                            <Style TargetType="ListBoxItem">
                                <Setter Property="Padding" Value="4,2"/>
                                <Setter Property="Focusable" Value="False"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="ListBoxItem">
                                            <ContentPresenter />
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </ListBox.ItemContainerStyle>
                    </ListBox>
                </Grid>
            </Border>

            <!-- SCORECARD & ACTION FOOTER -->
            <Grid Grid.Row="4" Margin="0,10,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- Scorecard Badges -->
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Name="BadgeFlags" Background="#2A1215" BorderBrush="#991B1B" BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,0,8,0">
                        <TextBlock Name="TxtFlagCount" Text="0 FLAGS" Foreground="#F87171" FontSize="12" FontWeight="Bold"/>
                    </Border>
                    <Border Name="BadgeWarns" Background="#2D2109" BorderBrush="#854D0E" BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,0,8,0">
                        <TextBlock Name="TxtWarnCount" Text="0 WARNINGS" Foreground="#FBBF24" FontSize="12" FontWeight="Bold"/>
                    </Border>
                    <Border Name="BadgeCleans" Background="#0A2218" BorderBrush="#065F46" BorderThickness="1" CornerRadius="6" Padding="12,6">
                        <TextBlock Name="TxtCleanCount" Text="0 VERIFIED CLEAN" Foreground="#34D399" FontSize="12" FontWeight="Bold"/>
                    </Border>
                </StackPanel>

                <!-- Action Buttons -->
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="BtnExportJson" Content="Export JSON Report" Height="36" Padding="14,0" Background="#1E1B4B" Foreground="#C084FC" BorderBrush="#4C1D95" BorderThickness="1" FontWeight="SemiBold" Cursor="Hand" Margin="0,0,8,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnExit" Content="Exit" Height="36" Padding="16,0" Background="#131526" Foreground="#94A3B8" BorderThickness="0" FontWeight="SemiBold" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Resolve UI Elements
    $titleBarGrid      = $window.FindName("TitleBarGrid")
    $btnMin            = $window.FindName("BtnMin")
    $btnClose          = $window.FindName("BtnClose")
    $btnScan           = $window.FindName("BtnScan")
    $btnExportJson     = $window.FindName("BtnExportJson")
    $btnExit           = $window.FindName("BtnExit")
    $btnClearLogs      = $window.FindName("BtnClearLogs")
    $scanProgress      = $window.FindName("ScanProgress")
    $txtProgressStatus = $window.FindName("TxtProgressStatus")
    $txtPercent        = $window.FindName("TxtPercent")
    $logListBox        = $window.FindName("LogListBox")
    $txtLauncher       = $window.FindName("TxtLauncher")
    $txtProfile        = $window.FindName("TxtProfile")
    $txtLastPlayed     = $window.FindName("TxtLastPlayed")
    $txtServer         = $window.FindName("TxtServer")
    $targetStatusText  = $window.FindName("TargetStatusText")
    $txtHost           = $window.FindName("TxtHost")
    $txtUser           = $window.FindName("TxtUser")
    $txtAdmin          = $window.FindName("TxtAdmin")
    $adminBadge        = $window.FindName("AdminBadge")
    $txtFlagCount      = $window.FindName("TxtFlagCount")
    $txtWarnCount      = $window.FindName("TxtWarnCount")
    $txtCleanCount     = $window.FindName("TxtCleanCount")
    $txtScanState      = $window.FindName("TxtScanState")

    # Title Bar Drag & Window Controls
    $titleBarGrid.Add_MouseLeftButtonDown({
        param($s, $e)
        if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            $window.DragMove()
        }
    })

    $btnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnClose.Add_Click({ $window.Close() })
    $btnExit.Add_Click({ $window.Close() })
    $btnClearLogs.Add_MouseLeftButtonDown({ $logListBox.Items.Clear() })

    # Populate System Card
    $txtHost.Text = "Hostname : $env:COMPUTERNAME"
    $txtUser.Text = "User     : $env:USERNAME"
    $isAdmin = Test-IsAdmin
    if ($isAdmin) {
        $txtAdmin.Text = "ADMINISTRATOR"
        $txtAdmin.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        $adminBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
    } else {
        $txtAdmin.Text = "STANDARD USER"
        $txtAdmin.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        $adminBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
    }

    # Helper to pump WPF UI messages
    function Pump-WpfEvents {
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    }

    # Real-Time GUI Logger Callback
    $Global:GuiLoggerCallback = {
        param($entry)
        $window.Dispatcher.Invoke([Action]{
            $sp = [System.Windows.Controls.StackPanel]::new()
            $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $sp.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)

            # Timestamp
            $tbTime = [System.Windows.Controls.TextBlock]::new()
            $tbTime.Text = "$($entry.Timestamp) "
            $tbTime.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $tbTime.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
            $sp.Children.Add($tbTime) | Out-Null

            # Level Badge
            $tbBadge = [System.Windows.Controls.TextBlock]::new()
            $tbBadge.Text = "[$($entry.Level)] "
            $badgeColor = switch ($entry.Level) {
                "FLAG" { "#EF4444" }
                "WARN" { "#F59E0B" }
                "OK"   { "#10B981" }
                default{ "#38BDF8" }
            }
            $tbBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($badgeColor)
            $tbBadge.FontWeight = [System.Windows.FontWeights]::Bold
            $tbBadge.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
            $sp.Children.Add($tbBadge) | Out-Null

            # Message
            $tbMsg = [System.Windows.Controls.TextBlock]::new()
            $tbMsg.Text = $entry.Message
            $tbMsg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9")
            $sp.Children.Add($tbMsg) | Out-Null

            # Detail
            if ($entry.Detail) {
                $tbDet = [System.Windows.Controls.TextBlock]::new()
                $tbDet.Text = " -> $($entry.Detail)"
                $tbDet.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7DD3FC")
                $sp.Children.Add($tbDet) | Out-Null
            }

            $logListBox.Items.Add($sp) | Out-Null
            $logListBox.ScrollIntoView($sp)

            # Update Scorecard counters
            $txtFlagCount.Text = "$($Global:ReportData.Scorecard.Flags) FLAGS"
            $txtWarnCount.Text = "$($Global:ReportData.Scorecard.Warnings) WARNINGS"
            $txtCleanCount.Text = "$($Global:ReportData.Scorecard.Clean) VERIFIED CLEAN"
        })
    }

    # Status & Progress Callback
    $Global:GuiStatusCallback = {
        param([string]$status, [double]$pct)
        $window.Dispatcher.Invoke([Action]{
            if ($status) { $txtProgressStatus.Text = $status }
            if ($pct -ge 0) {
                $scanProgress.Value = $pct
                $txtPercent.Text = "$([int]$pct)%"
            }
        })
        Pump-WpfEvents
    }

    # Quick pre-inspection for Target Instance card on load
    try {
        $recent = Get-MinecraftInstances | Select-Object -First 1
        if ($recent) {
            $txtLauncher.Text = "Launcher : $($recent.LauncherName)"
            $txtProfile.Text = "Profile  : $($recent.ProfileName)"
            $txtLastPlayed.Text = "Last Run : $($recent.LastPlayedTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            $targetStatusText.Text = "TARGET FOUND"
        }
    } catch {}

    # Scan Button Action
    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false
        $btnScan.Content = "SCANNING..."
        $txtScanState.Text = "Status   : Inspection in progress"
        $txtScanState.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")

        # Reset counters
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $logListBox.Items.Clear()

        # Step 1: Target Instance (10%)
        Update-ScanStatus "Detecting last played Minecraft instance & analyzing logs..." 10
        Scan-LastPlayedInstance
        if ($Global:ReportData.LastPlayedInstance.LauncherName) {
            $inst = $Global:ReportData.LastPlayedInstance
            $txtLauncher.Text = "Launcher : $($inst.LauncherName)"
            $txtProfile.Text = "Profile  : $($inst.ProfileName)"
            $txtLastPlayed.Text = "Last Run : $($inst.LastPlayedTime)"
            if ($inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
                $txtServer.Text = "Server   : $($inst.ConnectedServers -join ', ')"
            }
        }
        Pump-WpfEvents

        # Step 2: Running Java Processes & Injections (25%)
        Update-ScanStatus "Inspecting Java processes, main classes and agents..." 25
        Scan-JavaProcesses
        Pump-WpfEvents

        # Step 3: Prefetch Traces (40%)
        Update-ScanStatus "Scanning Prefetch execution traces (Past $HoursPrefetch hrs)..." 40
        Scan-PrefetchTraces -Hours $HoursPrefetch
        Pump-WpfEvents

        # Step 4: BAM/DAM Registry (55%)
        Update-ScanStatus "Querying BAM/DAM kernel execution registry (Past $HoursBAM hrs)..." 55
        Scan-BAMRegistry -Hours $HoursBAM
        Pump-WpfEvents

        # Step 5: UserAssist ROT13 (70%)
        Update-ScanStatus "Decoding UserAssist ROT13 application execution history..." 70
        Scan-UserAssist
        Pump-WpfEvents

        # Step 6: File System, Temp drops & Anti-Forensics (85%)
        Update-ScanStatus "Checking Mods, Temp drops, Event Logs & USN Journal..." 85
        Scan-FileSystem -Hours $HoursFiles
        Pump-WpfEvents

        # Step 7: USB Storage Traces (95%)
        Update-ScanStatus "Enumerating USBSTOR device registry & removable drives..." 95
        Scan-USBStorage
        Pump-WpfEvents

        # Step 8: Final Report (100%)
        Update-ScanStatus "Forensic scan complete. Review summary scorecard below." 100
        $txtScanState.Text = "Status   : Scan Complete"
        $txtScanState.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")

        $btnScan.IsEnabled = $true
        $btnScan.Content = "RE-SCAN"
        Pump-WpfEvents
    })

    # Export JSON Button Action
    $btnExportJson.Add_Click({
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $filename = "Gricko_Report_${timestamp}.json"
        $savePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), $filename)
        try {
            $Global:ReportData | ConvertTo-Json -Depth 6 | Set-Content -Path $savePath -Encoding UTF8
            [System.Windows.MessageBox]::Show("Forensic report exported successfully to:`n$savePath", "Gricko SS Tool", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            $msg = $_.Exception.Message
            [System.Windows.MessageBox]::Show("Failed to export report: $msg", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    # Show Window
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
