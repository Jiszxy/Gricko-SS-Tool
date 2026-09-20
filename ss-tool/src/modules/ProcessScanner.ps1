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
