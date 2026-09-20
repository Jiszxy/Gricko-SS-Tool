function Scan-FileSystem {
    param([int]$Hours = $HoursFiles)
    Write-SectionHeader "FILE SYSTEM, TEMP & ANTI-FORENSICS SCANS"

    $timeCutoff = (Get-Date).AddHours(-$Hours)

    $mcModsPath = Join-Path $env:APPDATA '.minecraft\mods'
    if (Test-Path $mcModsPath) {
        $mods = Get-ChildItem -Path $mcModsPath -File -ErrorAction SilentlyContinue
        Write-Alert -Level 'INFO' -Message 'Found Minecraft mods directory' -Detail "Path: $mcModsPath ($($mods.Count) files)"

        $modFlags = 0
        foreach ($mod in $mods) {
            $isRecent = ($mod.LastWriteTime -ge $timeCutoff)
            $isSusName = $false
            $matchedSig = ''

            foreach ($sig in $Global:SuspiciousSignatures) {
                if ($mod.Name -match "(?i)$sig") {
                    $isSusName = $true
                    $matchedSig = $sig
                    break
                }
            }

            $isAbnormalExt = ($mod.Extension -notin @('.jar', '.litemod', '.disabled'))

            $entry = [PSCustomObject]@{
                FileName      = $mod.Name
                FullPath      = $mod.FullName
                SizeKB        = [math]::Round($mod.Length / 1KB, 2)
                LastWriteTime = $mod.LastWriteTime.ToString('o')
                Recent        = $isRecent
                Flagged       = ($isSusName -or $isAbnormalExt)
                Reason        = if ($isSusName) { "Signature: $matchedSig" } elseif ($isAbnormalExt) { "Abnormal Extension: $($mod.Extension)" } else { "Clean" }
            }
            $Global:ReportData.ModFiles += $entry

            if ($isSusName) {
                $modFlags++
                Write-Alert -Level 'FLAG' -Message 'CHEAT MOD DETECTED IN MODS DIRECTORY!' -Detail "$($mod.Name) (Matches: $matchedSig)"
            } elseif ($isAbnormalExt) {
                $modFlags++
                Write-Alert -Level 'FLAG' -Message 'ABNORMAL FILE DETECTED IN MODS DIRECTORY!' -Detail "$($mod.Name) (Extension: $($mod.Extension))"
            } elseif ($isRecent) {
                Write-Alert -Level 'WARN' -Message "Mod file recently modified (within $Hours hours)" -Detail "$($mod.Name) at $($mod.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            }
        }

        if ($modFlags -eq 0) {
            Write-Alert -Level 'OK' -Message 'No known cheat clients or abnormal files detected in .minecraft\mods.'
        }
    } else {
        Write-Alert -Level 'INFO' -Message "No standard .minecraft\mods directory found at $mcModsPath."
    }

    $tempPaths = @($env:TEMP, "$env:LOCALAPPDATA\Temp") | Select-Object -Unique
    $tempFilesFound = 0
    $tempFlags = 0

    foreach ($tPath in $tempPaths) {
        if (Test-Path $tPath) {
            $recentTemp = Get-ChildItem -Path $tPath -File -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -ge $timeCutoff -and ($_.Extension -in @('.jar', '.dll', '.exe', '.class')) }

            foreach ($tf in $recentTemp) {
                $tempFilesFound++
                $isSus = $false
                $matchedSig = ''

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
                    LastWriteTime = $tf.LastWriteTime.ToString('o')
                    Flagged       = $isSus
                }
                $Global:ReportData.TempFiles += $entry

                if ($isSus) {
                    $tempFlags++
                    Write-Alert -Level 'FLAG' -Message 'SUSPICIOUS PAYLOAD IN TEMP DIRECTORY!' -Detail "$($tf.FullName) (Signature: $matchedSig)"
                } elseif ($tf.Extension -eq '.jar' -or $tf.Extension -eq '.dll') {
                    Write-Alert -Level 'WARN' -Message 'Recently dropped executable/library in Temp' -Detail "$($tf.Name) at $($tf.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
                }
            }
        }
    }

    if ($tempFilesFound -eq 0) {
        Write-Alert -Level 'OK' -Message 'No recently created .jar or .dll binaries found in Temp.'
    } elseif ($tempFlags -eq 0) {
        Write-Alert -Level 'OK' -Message 'No known cheat signatures in recent Temp drops.'
    }

    $dlPath = Join-Path $env:USERPROFILE 'Downloads'
    if (Test-Path $dlPath) {
        $recentDownloads = Get-ChildItem -Path $dlPath -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $timeCutoff -and ($_.Extension -in @('.jar', '.exe', '.zip', '.rar', '.7z')) }

        foreach ($dl in $recentDownloads) {
            $isSus = $false
            $matchedSig = ''

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
                LastWriteTime = $dl.LastWriteTime.ToString('o')
                Flagged       = $isSus
            }
            $Global:ReportData.DownloadFiles += $entry

            if ($isSus) {
                Write-Alert -Level 'FLAG' -Message 'CHEAT UTILITY IN RECENT DOWNLOADS!' -Detail "$($dl.Name) (Matches: $matchedSig)"
            }
        }
    }

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
            Write-Alert -Level 'FLAG' -Message 'EVENT LOG PURGE DETECTED (ANTI-FORENSICS)!' -Detail "Log: $($ev.LogName) cleared at $($ev.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))"
            $Global:ReportData.AntiForensics += [PSCustomObject]@{
                Type        = 'EventLogCleared'
                LogName     = $ev.LogName
                TimeCreated = $ev.TimeCreated.ToString('o')
                Id          = $ev.Id
            }
        }
    } else {
        Write-Alert -Level 'OK' -Message 'No Security or System event log clearances recorded in the last 72 hours.'
    }

    try {
        $usnOutput = & fsutil usn queryjournal C: 2>&1
        $usnText = $usnOutput -join ' '
        if ($usnText -like '*is not active*' -or $usnText -like '*Error:*') {
            Write-Alert -Level 'FLAG' -Message 'USN JOURNAL HAS BEEN DELETED OR DISABLED ON DRIVE C:!' -Detail 'Critical anti-forensics indicator used to erase file deletion history.'
            $Global:ReportData.AntiForensics += [PSCustomObject]@{
                Type    = 'USNJournalDisabled'
                Message = $usnText
            }
        } else {
            Write-Alert -Level 'OK' -Message 'NTFS USN Change Journal is active and healthy on volume C:.'
        }
    } catch {
        Write-Alert -Level 'INFO' -Message 'Could not query USN Journal status (requires admin privileges).'
    }

    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.Namespace(10)
        $rbCount = $recycleBin.Items().Count
        Write-Alert -Level 'INFO' -Message "Recycle Bin item count: $rbCount"
        
        foreach ($item in $recycleBin.Items()) {
            if ($item.Name -like '*.jar' -or $item.Name -like '*.exe') {
                Write-Alert -Level 'WARN' -Message 'Executable or JAR located inside Recycle Bin' -Detail $item.Name
            }
        }
    } catch {}
}
