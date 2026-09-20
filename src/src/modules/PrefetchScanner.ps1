function Scan-PrefetchTraces {
    param([int]$Hours = $HoursPrefetch)
    Write-SectionHeader "EXECUTION TRACES: PREFETCH (PAST $Hours HOURS)"

    $prefetchDir = 'C:\Windows\Prefetch'
    if (-not (Test-Path $prefetchDir)) {
        Write-Alert -Level 'WARN' -Message "Prefetch directory '$prefetchDir' not found or inaccessible." -Detail 'Elevation required.'
        return
    }

    $timeCutoff = (Get-Date).AddHours(-$Hours)
    $pfFiles = Get-ChildItem -Path $prefetchDir -Filter '*.pf' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $timeCutoff } | Sort-Object LastWriteTime -Descending

    if (-not $pfFiles) {
        Write-Alert -Level 'WARN' -Message "No Prefetch files modified within the last $Hours hours." -Detail 'Prefetch may be disabled or cleared.'
        return
    }

    Write-Alert -Level 'INFO' -Message "Analyzed $($pfFiles.Count) recent Prefetch execution records."

    $flaggedCount = 0
    foreach ($file in $pfFiles) {
        $rawName = $file.BaseName
        $execName = ($rawName -replace '-[A-F0-9]{8}$', '')

        $isMatch = $false
        $matchedSig = ''

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
            LastExecution  = $file.LastWriteTime.ToString('o')
            Size           = $file.Length
            SignatureMatch = $matchedSig
            Flagged        = $isMatch
        }
        $Global:ReportData.PrefetchTraces += $entry

        if ($isMatch) {
            $flaggedCount++
            Write-Alert -Level 'FLAG' -Message 'SUSPICIOUS EXECUTABLE IN PREFETCH!' -Detail "$($file.Name) (Last Executed: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
        } elseif ($execName -in @('FSUTIL', 'CMD', 'POWERSHELL', 'REGEDIT', 'TASKKILL', 'VSSADMIN')) {
            Write-Alert -Level 'INFO' -Message 'System utility execution in Prefetch' -Detail "$($file.Name) at $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
    }

    if ($flaggedCount -eq 0) {
        Write-Alert -Level 'OK' -Message 'No known cheat or cleaner signatures identified in recent Prefetch files.'
    }
}
