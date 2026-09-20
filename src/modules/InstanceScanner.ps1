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

        # Deep scan all installed mods in this active instance
        Scan-InstanceMods -InstancePath $lastPlayed.Path -ProfileName $lastPlayed.Profile
    } else {
        Write-Alert -Level "WARN" -Message "Could not detect any Minecraft launchers or instance profiles." -Detail "Minecraft may be installed on a non-standard drive or launched as portable."
    }
}

function Scan-InstanceMods {
    param(
        [string]$InstancePath,
        [string]$ProfileName
    )

    if (-not $InstancePath -or -not (Test-Path $InstancePath)) { return }
    $modsFolder = Join-Path $InstancePath "mods"
    if (-not (Test-Path $modsFolder)) { return }

    Write-Alert -Level "INFO" -Message "Deep scanning installed mods in active profile" -Detail "$modsFolder"

    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    $modFiles = Get-ChildItem -Path $modsFolder -File -Filter "*.jar" -ErrorAction SilentlyContinue | Sort-Object Name
    $activeMods = [System.Collections.Generic.List[PSCustomObject]]::new()
    $flaggedCount = 0

    foreach ($mod in $modFiles) {
        $isFlagged = $false
        $reason = "Clean"
        $category = "CLEAN"
        $displayName = [System.IO.Path]::GetFileNameWithoutExtension($mod.Name)

        # 1. Filename pattern matching
        foreach ($sig in $Global:CheatSignatures) {
            if ($mod.Name -match "(?i)$sig") {
                $isFlagged = $true
                $category = "FLAGGED CHEAT / DISALLOWED"
                $reason = "Matches cheat / disallowed signature: $sig"
                break
            }
        }

        # 2. Deep inspection inside JAR
        if (-not $isFlagged) {
            try {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($mod.FullName)

                # Check fabric.mod.json / quilt.mod.json / mcmod.info
                $metaEntry = $zip.GetEntry("fabric.mod.json")
                if (-not $metaEntry) { $metaEntry = $zip.GetEntry("quilt.mod.json") }
                if (-not $metaEntry) { $metaEntry = $zip.GetEntry("mcmod.info") }

                if ($metaEntry) {
                    $stream = $metaEntry.Open()
                    $reader = [System.IO.StreamReader]::new($stream)
                    $metaContent = $reader.ReadToEnd()
                    $reader.Close()
                    $stream.Close()

                    foreach ($sig in $Global:CheatSignatures) {
                        if ($metaContent -match "(?i)`"id`"\s*:\s*`"[^`"]*$sig" -or $metaContent -match "(?i)`"name`"\s*:\s*`"[^`"]*$sig") {
                            $isFlagged = $true
                            $category = "FLAGGED CHEAT / DISALLOWED"
                            $reason = "Internal metadata matches signature: $sig"
                            break
                        }
                    }
                }

                # Check class package entries
                if (-not $isFlagged) {
                    foreach ($entry in $zip.Entries) {
                        $eName = $entry.FullName.ToLower()
                        if ($eName -match "wurstclient" -or $eName -match "meteordevelopment" -or $eName -match "vape" -or $eName -match "crystaloptimizer" -or $eName -match "anchoroptimizer" -or $eName -match "autoclicker") {
                            $isFlagged = $true
                            $category = "FLAGGED CHEAT / DISALLOWED"
                            $reason = "Internal package contains cheat class: $($entry.FullName)"
                            break
                        }
                    }
                }

                $zip.Dispose()
            } catch {}
        }

        if ($isFlagged) {
            $flaggedCount++
            Write-Alert -Level "FLAG" -Message "SUSPICIOUS OR CHEAT MOD DETECTED IN ACTIVE INSTANCE!" -Detail "$($mod.Name) ($reason)"
        }

        $activeMods.Add([PSCustomObject]@{
            Name          = $displayName
            FileName      = $mod.Name
            FullPath      = $mod.FullName
            SizeKB        = [math]::Round($mod.Length / 1KB, 1)
            LastWriteTime = $mod.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            IsFlagged     = $isFlagged
            Category      = $category
            Reason        = $reason
        })
    }

    $Global:ReportData.ActiveInstanceMods = $activeMods
    if ($flaggedCount -gt 0) {
        Write-Alert -Level "FLAG" -Message "$flaggedCount cheat/disallowed mod(s) found in active profile" -Detail "Profile: $ProfileName"
    } else {
        Write-Alert -Level "OK" -Message "All $($activeMods.Count) installed mods passed initial integrity scan" -Detail "Profile: $ProfileName"
    }
}

