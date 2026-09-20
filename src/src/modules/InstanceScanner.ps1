function Scan-LastPlayedInstance {
    Write-SectionHeader 'LAST PLAYED MINECRAFT INSTANCE & LOG FORENSICS'

    $instances = [System.Collections.Generic.List[PSCustomObject]]::new()

    $dotMc = Join-Path $env:APPDATA '.minecraft'
    if (Test-Path $dotMc) {
        $lpJson = Join-Path $dotMc 'launcher_profiles.json'
        $latestLog = Join-Path $dotMc 'logs\latest.log'

        $lastUsedTime = $null
        $profileName = 'Default / Vanilla'
        $versionId = 'Unknown'

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
                                $versionId = if ($p.lastVersionId) { $p.lastVersionId } else { 'Custom' }
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
                Launcher   = 'Standard .minecraft (Vanilla/Forge/Fabric)'
                Profile    = $profileName
                Version    = $versionId
                Path       = $dotMc
                LogFile    = $latestLog
                LastPlayed = $lastUsedTime
            })
        }
    }

    $lunarPath = Join-Path $env:USERPROFILE '.lunarclient'
    if (Test-Path $lunarPath) {
        $lunarLog = Join-Path $lunarPath 'offline\multiver\logs\latest.log'
        if (-not (Test-Path $lunarLog)) {
            $lunarLog = Join-Path $lunarPath 'logs\launcher\renderer.log'
        }
        if (Test-Path $lunarLog) {
            $instances.Add([PSCustomObject]@{
                Launcher   = 'Lunar Client'
                Profile    = 'Lunar MultiVer Profile'
                Version    = 'Lunar'
                Path       = $lunarPath
                LogFile    = $lunarLog
                LastPlayed = (Get-Item $lunarLog).LastWriteTime
            })
        }
    }

    $badlionPath = Join-Path $env:APPDATA 'Badlion Client'
    if (-not (Test-Path $badlionPath)) { $badlionPath = Join-Path $env:APPDATA '.minecraft\badlion' }
    if (Test-Path $badlionPath) {
        $blLog = Join-Path $badlionPath 'logs\latest.log'
        if (Test-Path $blLog) {
            $instances.Add([PSCustomObject]@{
                Launcher   = 'Badlion Client'
                Profile    = 'Badlion Standard'
                Version    = 'Badlion'
                Path       = $badlionPath
                LogFile    = $blLog
                LastPlayed = (Get-Item $blLog).LastWriteTime
            })
        }
    }

    $featherPath = Join-Path $env:APPDATA '.feather'
    if (Test-Path $featherPath) {
        $featherLog = Join-Path $featherPath 'logs\latest.log'
        if (Test-Path $featherLog) {
            $instances.Add([PSCustomObject]@{
                Launcher   = 'Feather Client'
                Profile    = 'Feather Profile'
                Version    = 'Feather'
                Path       = $featherPath
                LogFile    = $featherLog
                LastPlayed = (Get-Item $featherLog).LastWriteTime
            })
        }
    }

    $prismPath = Join-Path $env:APPDATA 'PrismLauncher\instances'
    if (Test-Path $prismPath) {
        $prismDirs = Get-ChildItem -Path $prismPath -Directory
        foreach ($pDir in $prismDirs) {
            $pLog = Join-Path $pDir.FullName '.minecraft\logs\latest.log'
            if (Test-Path $pLog) {
                $instances.Add([PSCustomObject]@{
                    Launcher   = 'Prism Launcher'
                    Profile    = $pDir.Name
                    Version    = 'Prism'
                    Path       = $pDir.FullName
                    LogFile    = $pLog
                    LastPlayed = (Get-Item $pLog).LastWriteTime
                })
            }
        }
    }

    $theseusPath = Join-Path $env:APPDATA 'com.modrinth.theseus\profiles'
    if (Test-Path $theseusPath) {
        $modrinthDirs = Get-ChildItem -Path $theseusPath -Directory
        foreach ($mDir in $modrinthDirs) {
            $mLog = Join-Path $mDir.FullName 'logs\latest.log'
            if (Test-Path $mLog) {
                $instances.Add([PSCustomObject]@{
                    Launcher   = 'Modrinth App (Theseus)'
                    Profile    = $mDir.Name
                    Version    = 'Modrinth Profile'
                    Path       = $mDir.FullName
                    LogFile    = $mLog
                    LastPlayed = (Get-Item $mLog).LastWriteTime
                })
            }
        }
    }

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
            LastPlayed = $lastPlayed.LastPlayed.ToString('o')
        }

        if (Test-Path $lastPlayed.LogFile) {
            $logItem = Get-Item $lastPlayed.LogFile
            Write-Alert -Level 'INFO' -Message 'Analyzing session log file' -Detail "$($lastPlayed.LogFile) (Size: $([math]::Round($logItem.Length / 1KB, 2)) KB)"

            if ($logItem.Length -eq 0) {
                Write-Alert -Level 'FLAG' -Message 'INSTANCE LOG WAS WIPED OR EMPTY (0 BYTES)!' -Detail 'Potential log clearance before screenshare.'
            } else {
                $logLines = Get-Content -Path $lastPlayed.LogFile -Tail 300 -ErrorAction SilentlyContinue

                $suspiciousLogHits = 0
                $connectedServers = @()

                foreach ($line in $logLines) {
                    if ($line -match 'Connecting to ([^,\s]+)') {
                        $server = $matches[1].Trim()
                        if ($server -notin $connectedServers) {
                            $connectedServers += $server
                        }
                    }

                    foreach ($sig in $Global:SuspiciousSignatures) {
                        if ($line -match "(?i)\b$sig\b") {
                            $suspiciousLogHits++
                            Write-Alert -Level 'FLAG' -Message 'SUSPICIOUS STRING FOUND IN ACTIVE SESSION LOG!' -Detail "Line: $line"
                            break
                        }
                    }
                }

                if ($connectedServers.Count -gt 0) {
                    Write-Alert -Level 'INFO' -Message 'Connected servers identified in session' -Detail ($connectedServers -join ', ')
                }

                if ($suspiciousLogHits -eq 0) {
                    Write-Alert -Level 'OK' -Message 'No known cheat signatures or injection traces found in latest.log.'
                }
            }
        }
    } else {
        Write-Alert -Level 'WARN' -Message 'Could not detect any Minecraft launchers or instance profiles.' -Detail 'Minecraft may be installed on a non-standard drive or launched as portable.'
    }
}
