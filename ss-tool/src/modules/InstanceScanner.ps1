<#
    Gricko SS Tool - Comprehensive Multi-Client & Multi-Instance Forensic Scanner
    Discovers, enumerates, and deeply analyzes ALL Minecraft clients, launchers & profiles.
#>

function Analyze-InstanceLog {
    param([string]$LogFilePath)

    $result = [PSCustomObject]@{
        LogExists        = $false
        LogPath          = $LogFilePath
        LogSizeKB        = 0
        IsWiped          = $false
        ConnectedServers = [System.Collections.Generic.List[string]]::new()
        SuspiciousHits   = [System.Collections.Generic.List[string]]::new()
    }

    if (-not $LogFilePath -or -not (Test-Path $LogFilePath)) {
        return $result
    }

    try {
        $logItem = Get-Item $LogFilePath -ErrorAction SilentlyContinue
        if (-not $logItem) { return $result }

        $result.LogExists = $true
        $result.LogSizeKB = [math]::Round($logItem.Length / 1KB, 2)

        if ($logItem.Length -eq 0) {
            $result.IsWiped = $true
            return $result
        }

        $logLines = Get-Content -Path $LogFilePath -Tail 300 -ErrorAction SilentlyContinue
        if ($logLines) {
            foreach ($line in $logLines) {
                if ($line -match "Connecting to ([^,\s]+)") {
                    $srv = $matches[1].Trim()
                    if ($srv -notin $result.ConnectedServers) { $result.ConnectedServers.Add($srv) }
                } elseif ($line -match "(?i)Website:\s*([a-zA-Z0-9\.\-]+)") {
                    $srv = $matches[1].Trim()
                    if ($srv -notin $result.ConnectedServers) { $result.ConnectedServers.Add($srv) }
                } elseif ($line -match "(?i)\[CHAT\].*(minemen\.club|hypixel\.net|invadedlands\.net|pvptemple\.com|coldpvp\.com|bedless\.club|mcpvp\.club|syuu\.net|loyisa\.cn)") {
                    $srv = $matches[1].Trim()
                    if ($srv -notin $result.ConnectedServers) { $result.ConnectedServers.Add($srv) }
                }

                foreach ($sig in $Global:SuspiciousSignatures) {
                    if ($line -match "(?i)\b$sig\b") {
                        if ($line -notin $result.SuspiciousHits) {
                            $result.SuspiciousHits.Add($line.Trim())
                        }
                        break
                    }
                }
            }
        }
    } catch {}

    return $result
}

function Analyze-InstanceMods {
    param(
        [string]$InstancePath,
        [string]$ProfileName = "Unknown"
    )

    $result = [PSCustomObject]@{
        Mods         = [System.Collections.Generic.List[PSCustomObject]]::new()
        FlaggedMods  = [System.Collections.Generic.List[PSCustomObject]]::new()
        TotalCount   = 0
        FlaggedCount = 0
    }

    if (-not $InstancePath -or -not (Test-Path $InstancePath)) { return $result }

    # Check both 'mods' and Feather's 'user-mods'
    $candidateModFolders = @(
        (Join-Path $InstancePath "mods"),
        (Join-Path $InstancePath "user-mods"),
        (Join-Path $InstancePath ".minecraft\mods")
    )

    $modFiles = @()
    foreach ($mf in $candidateModFolders) {
        if (Test-Path $mf) {
            $found = Get-ChildItem -Path $mf -File -Filter "*.jar" -ErrorAction SilentlyContinue
            if ($found) { $modFiles += $found }
        }
    }

    if ($modFiles.Count -eq 0) { return $result }

    # Deduplicate jars by filename
    $uniqueJars = $modFiles | Sort-Object Name -Unique
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    foreach ($mod in $uniqueJars) {
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

        $modObj = [PSCustomObject]@{
            Name          = $displayName
            FileName      = $mod.Name
            FullPath      = $mod.FullName
            SizeKB        = [math]::Round($mod.Length / 1KB, 1)
            LastWriteTime = $mod.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            IsFlagged     = $isFlagged
            Category      = $category
            Reason        = $reason
        }

        $result.Mods.Add($modObj)
        if ($isFlagged) {
            $result.FlaggedMods.Add($modObj)
            $result.FlaggedCount++
        }
    }

    $result.TotalCount = $result.Mods.Count
    return $result
}

function Scan-LastPlayedInstance {
    Write-SectionHeader "MINECRAFT INSTANCES & LOG FORENSICS (ALL CLIENTS)"

    $instances = [System.Collections.Generic.List[PSCustomObject]]::new()

    # -------------------------------------------------------------
    # 0. Active Running Java / Minecraft Process Check
    # -------------------------------------------------------------
    try {
        $javaProcesses = Get-CimInstance Win32_Process -Filter "Name = 'javaw.exe' or Name = 'java.exe'" -ErrorAction SilentlyContinue
        foreach ($proc in $javaProcesses) {
            $cmd = $proc.CommandLine
            if (-not $cmd) { continue }
            if ($cmd -match "minecraft" -or $cmd -match "lunar" -or $cmd -match "feather" -or $cmd -match "badlion" -or $cmd -match "forge" -or $cmd -match "fabric" -or $cmd -match "optifine" -or $cmd -match "net.minecraft") {
                $clientName = "Minecraft (Vanilla / Custom)"
                if ($cmd -match "(?i)feather") { $clientName = "Feather Client" }
                elseif ($cmd -match "(?i)lunar") { $clientName = "Lunar Client" }
                elseif ($cmd -match "(?i)badlion") { $clientName = "Badlion Client" }
                elseif ($cmd -match "(?i)theseus|modrinth") { $clientName = "Modrinth App" }
                elseif ($cmd -match "(?i)curseforge") { $clientName = "CurseForge" }
                elseif ($cmd -match "(?i)prism") { $clientName = "Prism Launcher" }
                elseif ($cmd -match "(?i)salwyrr") { $clientName = "Salwyrr Client" }
                elseif ($cmd -match "(?i)labymod") { $clientName = "LabyMod" }
                elseif ($cmd -match "(?i)fabric") { $clientName = "Fabric Loader" }
                elseif ($cmd -match "(?i)forge") { $clientName = "Forge Loader" }

                $gameDir = $null
                if ($cmd -match '--gameDir\s+"?([^"]+)"?') { $gameDir = $matches[1].Trim() }
                elseif ($cmd -match '-Dminecraft\.applet\.TargetDirectory="?([^"]+)"?') { $gameDir = $matches[1].Trim() }

                $logPath = if ($gameDir) { Join-Path $gameDir "logs\latest.log" } else { $null }

                $instances.Add([PSCustomObject]@{
                    Launcher   = "$clientName (Running)"
                    Profile    = "Active Game (PID $($proc.ProcessId))"
                    Version    = "Active Running Session"
                    Path       = if ($gameDir) { $gameDir } else { "Process PID $($proc.ProcessId)" }
                    LogFile    = $logPath
                    LastPlayed = (Get-Date)
                    IsRunning  = $true
                })
            }
        }
    } catch {}

    # -------------------------------------------------------------
    # 1. Modrinth Launcher (All Profiles & All Drives)
    # -------------------------------------------------------------
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
            
            # Detect version from profile-metadata.json if available
            $mVer = "Modrinth Profile"
            $metaJson = Join-Path $mDir.FullName "profile-metadata.json"
            if (Test-Path $metaJson) {
                try {
                    $mj = Get-Content -Raw $metaJson -ErrorAction SilentlyContinue | ConvertFrom-Json
                    if ($mj.game_version) { $mVer = "$($mj.loader) $($mj.game_version)" }
                } catch {}
            }

            $instances.Add([PSCustomObject]@{
                Launcher   = "Modrinth App"
                Profile    = $mDir.Name
                Version    = $mVer
                Path       = $mDir.FullName
                LogFile    = if (Test-Path $mLog) { $mLog } else { $null }
                LastPlayed = $mTime
                IsRunning  = $false
            })
        }
    }

    # -------------------------------------------------------------
    # 2. Feather Client (All Profiles & Root)
    # -------------------------------------------------------------
    $featherPaths = @(
        (Join-Path $env:APPDATA ".feather"),
        (Join-Path $env:USERPROFILE ".feather"),
        (Join-Path $env:LOCALAPPDATA ".feather")
    )
    foreach ($fPath in $featherPaths) {
        if (Test-Path $fPath) {
            # Check for sub-instances
            $fInstancesDir = Join-Path $fPath "instances"
            $hasSub = $false
            if (Test-Path $fInstancesDir) {
                $fSubDirs = Get-ChildItem -Path $fInstancesDir -Directory -ErrorAction SilentlyContinue
                foreach ($fsd in $fSubDirs) {
                    $hasSub = $true
                    $fLog = Join-Path $fsd.FullName "logs\latest.log"
                    $fTime = if (Test-Path $fLog) { (Get-Item $fLog).LastWriteTime } else { $fsd.LastWriteTime }
                    $instances.Add([PSCustomObject]@{
                        Launcher   = "Feather Client"
                        Profile    = $fsd.Name
                        Version    = "Feather Instance"
                        Path       = $fsd.FullName
                        LogFile    = $fLog
                        LastPlayed = $fTime
                        IsRunning  = $false
                    })
                }
            }

            # Also add root feather profile
            $fLogRoot = Join-Path $fPath "logs\latest.log"
            $fRootTime = if (Test-Path $fLogRoot) { (Get-Item $fLogRoot).LastWriteTime } else { (Get-Item $fPath).LastWriteTime }
            $instances.Add([PSCustomObject]@{
                Launcher   = "Feather Client"
                Profile    = "Feather Default"
                Version    = "Feather Fabric/Forge"
                Path       = $fPath
                LogFile    = $fLogRoot
                LastPlayed = $fRootTime
                IsRunning  = $false
            })
            break
        }
    }

    # -------------------------------------------------------------
    # 3. Lunar Client (MultiVer & Subversions)
    # -------------------------------------------------------------
    $lunarPath = Join-Path $env:USERPROFILE ".lunarclient"
    if (Test-Path $lunarPath) {
        $multiVer = Join-Path $lunarPath "offline\multiver"
        $hasMulti = $false
        if (Test-Path $multiVer) {
            $lunarVersions = Get-ChildItem -Path $multiVer -Directory -ErrorAction SilentlyContinue
            foreach ($lv in $lunarVersions) {
                $hasMulti = $true
                $lvLog = Join-Path $lv.FullName "logs\latest.log"
                if (-not (Test-Path $lvLog)) { $lvLog = Join-Path $multiVer "logs\latest.log" }
                $lvTime = if (Test-Path $lvLog) { (Get-Item $lvLog).LastWriteTime } else { $lv.LastWriteTime }
                $instances.Add([PSCustomObject]@{
                    Launcher   = "Lunar Client"
                    Profile    = $lv.Name
                    Version    = "Lunar MultiVer ($($lv.Name))"
                    Path       = $lv.FullName
                    LogFile    = $lvLog
                    LastPlayed = $lvTime
                    IsRunning  = $false
                })
            }
        }

        # Also add overall Lunar Client profile
        $lunarLog = Join-Path $lunarPath "offline\multiver\logs\latest.log"
        if (-not (Test-Path $lunarLog)) { $lunarLog = Join-Path $lunarPath "logs\launcher\renderer.log" }
        if (-not (Test-Path $lunarLog)) { $lunarLog = Join-Path $lunarPath "logs\launcher\main.log" }
        $lTime = if (Test-Path $lunarLog) { (Get-Item $lunarLog).LastWriteTime } else { (Get-Item $lunarPath).LastWriteTime }
        $instances.Add([PSCustomObject]@{
            Launcher   = "Lunar Client"
            Profile    = "Lunar Client"
            Version    = "Lunar Client"
            Path       = $lunarPath
            LogFile    = $lunarLog
            LastPlayed = $lTime
            IsRunning  = $false
        })
    }

    # -------------------------------------------------------------
    # 4. Badlion Client
    # -------------------------------------------------------------
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
                IsRunning  = $false
            })
            break
        }
    }

    # -------------------------------------------------------------
    # 5. CurseForge (All Instances)
    # -------------------------------------------------------------
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
                    IsRunning  = $false
                })
            }
        }
    }

    # -------------------------------------------------------------
    # 6. Prism Launcher & MultiMC & PolyMC (All Instances)
    # -------------------------------------------------------------
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
                    IsRunning  = $false
                })
            }
        }
    }

    # -------------------------------------------------------------
    # 7. Salwyrr Client
    # -------------------------------------------------------------
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
                IsRunning  = $false
            })
            break
        }
    }

    # -------------------------------------------------------------
    # 8. Standard .minecraft (Parse ALL Profiles in launcher_profiles.json)
    # -------------------------------------------------------------
    $dotMcCandidates = @((Join-Path $env:APPDATA ".minecraft"))
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        $cand = Join-Path $drive.Root ".minecraft"
        if ((Test-Path $cand) -and ($cand -notin $dotMcCandidates)) {
            $dotMcCandidates += $cand
        }
    }

    foreach ($dotMc in $dotMcCandidates) {
        if (-not (Test-Path $dotMc)) { continue }

        $lpJson = Join-Path $dotMc "launcher_profiles.json"
        $latestLog = Join-Path $dotMc "logs\latest.log"
        $mcAddedAny = $false

        if (Test-Path $lpJson) {
            try {
                $lp = Get-Content -Raw -Path $lpJson -ErrorAction SilentlyContinue | ConvertFrom-Json
                if ($lp.profiles) {
                    foreach ($prop in $lp.profiles.PSObject.Properties) {
                        $p = $prop.Value
                        $pName = if ($p.name) { $p.name } else { $prop.Name }
                        $vId = if ($p.lastVersionId) { $p.lastVersionId } else { "Vanilla / Forge / Fabric" }
                        $pDir = if ($p.gameDir -and (Test-Path $p.gameDir)) { $p.gameDir } else { $dotMc }
                        $pLog = Join-Path $pDir "logs\latest.log"
                        
                        $pTime = $null
                        if ($p.lastUsed) {
                            try { $pTime = [DateTime]::Parse($p.lastUsed) } catch {}
                        }
                        if (-not $pTime -and (Test-Path $pLog)) {
                            $pTime = (Get-Item $pLog).LastWriteTime
                        }
                        if (-not $pTime) {
                            $pTime = (Get-Item $pDir).LastWriteTime
                        }

                        $instances.Add([PSCustomObject]@{
                            Launcher   = "Standard Minecraft"
                            Profile    = $pName
                            Version    = $vId
                            Path       = $pDir
                            LogFile    = $pLog
                            LastPlayed = $pTime
                            IsRunning  = $false
                        })
                        $mcAddedAny = $true
                    }
                }
            } catch {}
        }

        # If no individual profile was added from JSON, add standard .minecraft
        if (-not $mcAddedAny) {
            $logWriteTime = if (Test-Path $latestLog) { (Get-Item $latestLog).LastWriteTime } else { (Get-Item $dotMc).LastWriteTime }
            $instances.Add([PSCustomObject]@{
                Launcher   = "Standard Minecraft"
                Profile    = "Standard Profile"
                Version    = "Vanilla / Forge / Fabric"
                Path       = $dotMc
                LogFile    = $latestLog
                LastPlayed = $logWriteTime
                IsRunning  = $false
            })
        }
    }

    # -------------------------------------------------------------
    # Deduplicate & Deep Analyze ALL Discovered Instances
    # -------------------------------------------------------------
    $uniqueInstances = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenKeys = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($inst in $instances) {
        $key = "$($inst.Launcher)|$($inst.Profile)|$($inst.Path)".ToLower()
        if (-not $seenKeys.Contains($key)) {
            $seenKeys.Add($key) | Out-Null
            $uniqueInstances.Add($inst)
        }
    }

    # Deeply analyze logs and mods for EVERY instance found on the machine
    $analyzedInstances = [System.Collections.Generic.List[PSCustomObject]]::new()
    $allFlaggedModsCount = 0

    foreach ($inst in $uniqueInstances) {
        $logAnalysis = Analyze-InstanceLog -LogFilePath $inst.LogFile
        $modsAnalysis = Analyze-InstanceMods -InstancePath $inst.Path -ProfileName $inst.Profile

        $lpTimeStr = if ($inst.LastPlayed -is [DateTime]) {
            $inst.LastPlayed.ToString("yyyy-MM-dd HH:mm:ss")
        } elseif ($inst.LastPlayed) {
            "$($inst.LastPlayed)"
        } else {
            "Historical"
        }

        $analyzedObj = [PSCustomObject]@{
            Id               = [Guid]::NewGuid().ToString()
            DisplayName      = "$($inst.Launcher) - $($inst.Profile)"
            Launcher         = $inst.Launcher
            LauncherName     = $inst.Launcher
            Profile          = $inst.Profile
            ProfileName      = $inst.Profile
            Version          = $inst.Version
            Path             = $inst.Path
            LogFile          = $inst.LogFile
            LastPlayed       = $inst.LastPlayed
            LastPlayedTime   = $lpTimeStr
            IsRunning        = [bool]$inst.IsRunning
            ConnectedServers = $logAnalysis.ConnectedServers
            IsLogWiped       = $logAnalysis.IsWiped
            SuspiciousLog    = $logAnalysis.SuspiciousHits
            Mods             = $modsAnalysis.Mods
            FlaggedMods      = $modsAnalysis.FlaggedMods
            TotalModsCount   = $modsAnalysis.TotalCount
            FlaggedModsCount = $modsAnalysis.FlaggedCount
        }

        # Raise alerts for cheat detections in any instance
        if ($analyzedObj.FlaggedModsCount -gt 0) {
            $allFlaggedModsCount += $analyzedObj.FlaggedModsCount
            foreach ($fm in $analyzedObj.FlaggedMods) {
                Write-Alert -Level "FLAG" -Message "SUSPICIOUS OR CHEAT MOD DETECTED!" -Detail "[$($analyzedObj.Launcher) / $($analyzedObj.Profile)] $($fm.FileName) ($($fm.Reason))"
            }
        }

        if ($analyzedObj.IsLogWiped) {
            Write-Alert -Level "FLAG" -Message "INSTANCE LOG WAS WIPED OR EMPTY (0 BYTES)!" -Detail "[$($analyzedObj.Launcher) / $($analyzedObj.Profile)] $($analyzedObj.LogFile)"
        }

        $analyzedInstances.Add($analyzedObj)
    }

    # Sort instances: running first, then by last played descending
    $sortedInstances = $analyzedInstances | Sort-Object -Property @{ Expression = { $_.IsRunning }; Descending = $true }, @{ Expression = { if ($_.LastPlayed -is [DateTime]) { $_.LastPlayed } else { [DateTime]::MinValue } }; Descending = $true }

    $Global:ReportData.AllInstances = $sortedInstances

    # Pick the most suitable default / last played instance
    $lastPlayed = $sortedInstances | Select-Object -First 1

    if ($lastPlayed) {
        $Global:ReportData.LastPlayedInstance = [ordered]@{
            Launcher         = $lastPlayed.Launcher
            LauncherName     = $lastPlayed.Launcher
            Profile          = $lastPlayed.Profile
            ProfileName      = $lastPlayed.Profile
            Version          = $lastPlayed.Version
            Path             = $lastPlayed.Path
            LogFile          = $lastPlayed.LogFile
            LastPlayed       = $lastPlayed.LastPlayedTime
            LastPlayedTime   = $lastPlayed.LastPlayedTime
            ConnectedServers = $lastPlayed.ConnectedServers
            IsLogWiped       = $lastPlayed.IsLogWiped
            TotalModsCount   = $lastPlayed.TotalModsCount
            FlaggedModsCount = $lastPlayed.FlaggedModsCount
        }

        $Global:ReportData.ActiveInstanceMods = $lastPlayed.Mods

        Write-Host ""
        Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host "  |  (*) ACTIVE TARGET INSTANCE (ALL $($sortedInstances.Count) INSTANCES ANALYZED)               |" -ForegroundColor Magenta
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
        Write-Host ($lastPlayed.LastPlayedTime).PadRight(58) -NoNewline -ForegroundColor Green
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  |  Path     : " -NoNewline -ForegroundColor DarkMagenta
        $truncPath = if ($lastPlayed.Path.Length -gt 58) { "..." + $lastPlayed.Path.Substring($lastPlayed.Path.Length - 55) } else { $lastPlayed.Path }
        Write-Host $truncPath.PadRight(58) -NoNewline -ForegroundColor DarkCyan
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  |  Mods     : " -NoNewline -ForegroundColor DarkMagenta
        $modSummary = "$($lastPlayed.TotalModsCount) installed ($($lastPlayed.FlaggedModsCount) flagged)"
        Write-Host $modSummary.PadRight(58) -NoNewline -ForegroundColor $(if ($lastPlayed.FlaggedModsCount -gt 0) { "Red" } else { "Green" })
        Write-Host "|" -ForegroundColor Magenta
        Write-Host "  +--------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host ""

        # Summary list of all other detected clients & instances
        if ($sortedInstances.Count -gt 1) {
            Write-Host "  Discovered Minecraft Instances ($($sortedInstances.Count) total across all launchers):" -ForegroundColor DarkGray
            foreach ($other in $sortedInstances) {
                $statusFlag = if ($other.FlaggedModsCount -gt 0) { "[!] CHEAT MODS ($($other.FlaggedModsCount))" } else { "[OK] Clean ($($other.TotalModsCount) mods)" }
                $col = if ($other.FlaggedModsCount -gt 0) { "Red" } else { "DarkGray" }
                Write-Host "    * [$($other.Launcher)] $($other.Profile) -> $statusFlag | Last: $($other.LastPlayedTime)" -ForegroundColor $col
            }
            Write-Host ""
        }

        if ($lastPlayed.ConnectedServers.Count -gt 0) {
            Write-Alert -Level "INFO" -Message "Connected servers identified in target session" -Detail ($lastPlayed.ConnectedServers -join ", ")
        }

        if ($lastPlayed.FlaggedModsCount -gt 0) {
            Write-Alert -Level "FLAG" -Message "$($lastPlayed.FlaggedModsCount) cheat/disallowed mod(s) in active profile" -Detail "Profile: $($lastPlayed.Profile)"
        } else {
            Write-Alert -Level "OK" -Message "All $($lastPlayed.TotalModsCount) mods passed integrity scan" -Detail "Profile: $($lastPlayed.Profile)"
        }
    } else {
        Write-Alert -Level "WARN" -Message "Could not detect any Minecraft launchers or instance profiles." -Detail "Minecraft may be installed on a non-standard drive or launched as portable."
    }
}

function Scan-InstanceMods {
    param(
        [string]$InstancePath,
        [string]$ProfileName
    )
    $res = Analyze-InstanceMods -InstancePath $InstancePath -ProfileName $ProfileName
    $Global:ReportData.ActiveInstanceMods = $res.Mods
    return $res
}
