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
    ActiveInstanceMods = @()
    AllInstances       = @()
    ModFiles           = @()
    DownloadFiles      = @()
    TempFiles          = @()
    AntiForensics      = @()
    USBDevices         = @()
}

# Comprehensive Minecraft Cheat, Ghost Client & Disallowed Mod Signatures
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
    "kamiblue", "lambda", "cleanerclient", "thunderhack", "mathax",

    # Mace / CPVP / Weapon Exploit Mods (1.21+)
    "maceassist", "mace-assist", "mace.assist",
    "lungemacro", "lunge-macro", "mace.trigger", "macetrigger",
    "cpvpmod", "cpvp-mod", "cpvpclient", "macemod", "maceboost",
    "mace.*optimizer", "windchargemod", "windcharge.*assist",

    # Triggerbot / Auto-Attack / Auto-Swing
    "triggerbot", "trigger-bot", "triggerbotmanager", "autoattack",
    "auto-attack", "autoswing", "auto-swing", "swingaura", "attackaura",
    "combotrigger", "attacktrigger", "clicktrigger", "autoclick",
    "autoclicker", "auto-clicker", "clickassist",

    # Aim Assist / Rotation Hacks
    "aimassist", "aim-assist", "maceaimassist", "smoothaim", "smooth-aim",
    "rotationmanager", "rotation-manager", "aimbot", "aim-bot",
    "aimhelper", "rotationhelper", "snapaim", "silentaim", "predictiveaim",
    "targetstrafe", "aimstrafe",

    # Crystal PvP Automation (Macros & Cheats - legitimate optimizers like Marlow/Kind are excluded)
    "crystalaura", "crystal-aura", "autocrystal", "auto-crystal",
    "autocristal", "fastcrystal", "crystalbot", "autoanchor", "auto-anchor",
    "anchormacro", "anchor-macro", "doubleanchor", "double-anchor", "anchorbot",

    # Velocity / Anti-Knockback
    "velocityhack", "velocity-hack", "antivelocity", "novelocity",
    "antikb", "anti-kb", "noknockback", "knockbackmod", "kbmod",
    "velocitymod", "reducekb",

    # Stream-Proof / Anti-Screenshare Evasion
    "streamproof", "stream-proof", "screenshare.*evad", "antiscreen",
    "anti-screen", "overlayproof", "hiddenoverlay", "invisibleoverlay",
    "explodemod",

    # Classic Disallowed Mods
    "hitbox", "reach", "extendedreach", "reachmod",
    "fastplace", "autototem", "autopot", "autoshield",
    "freecam", "xray", "x-ray", "baritone", "seedcracker",
    "nofall", "nofall.*mod", "antifall", "killaura", "killa.aura",
    "scaffoldmod", "towerbotmod", "speedmod", "flightmod"
)

# Known Legitimate Public Modrinth / CurseForge Mods (Optimizers, Camera, Performance)
$Global:LegitimateModSignatures = @(
    "kindscrystaloptimizer", "kinds_anchor_optimizer", "kinds-anchor-optimizer",
    "marlowcrystal", "marlow-crystal-optimizer", "herosanchoroptimizer",
    "clientsidecrystals", "freelook", "cpvpoptimizer", "jiszxycpvpoptimizer",
    "sodium", "lithium", "ferritecore", "iris", "entityculling", "immediatelyfast",
    "krypton", "modmenu", "fabric-api", "clumps", "shieldfixes", "crosshairaddons",
    "c2me", "bobby", "appleskin", "cloth-config", "yet-another-config-lib"
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

    $uniqueJars = $modFiles | Sort-Object Name -Unique
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    if (-not $Global:ModAnalysisCache) {
        $Global:ModAnalysisCache = @{}
    }

    # Pre-compiled high-performance regexes for instant multi-pattern evaluation
    $cheatPkgs = @("wurstclient","meteordevelopment","vape",
                   "autoclicker","raven/b","liquidbounce",
                   "rusherhack","tenacity","novoline","rise/client","futureclient",
                   "astolfo","sigma/client","salware","drip/loader","weavemc",
                   "weave/loader","bape/client","lowkey/client","itami/client",
                   "dreamclient","entropy/client","spectral/client","pluto/client",
                   "us/kenny","us/kenny/mace","us/kenny/triggerbot","us/kenny/web",
                   "maceassist","mace/assist","lungemacro","lunge/macro",
                   "windchargeassist","windcharge/assist",
                   "crystalaura","crystal/aura","autocrystal","auto/crystal",
                   "anchormacro","anchor/macro","doubleanchor","double/anchor")
    $cheatPkgRegex = [regex]::new('(?i)(' + (($cheatPkgs | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    # Generic combat automation and macro class detector (identifies disguised / Trojan mods regardless of package or mod name)
    $cheatClassRegex = [regex]::new('(?i)(^|[\\/._])(AutoCrystal|AnchorMacro|DoubleAnchor|AutoTotem|MaceAssist|Triggerbot|KillAura|AimAssist|AimBot|ReachMod|ExplodeManager|ExplodeMacro|LungeMacro|HitboxExpand|CrystalAura|FastCrystal|AutoAnchor|MultiKeyBinding|KeyBindingClient|StreamProofOverlay|WebConfigServer|WindChargeAssist|KeyEventManager|AutomatorManager)(Manager|Module|Client|Hack|Cheat|Service|Helper|Impl)?(\.class|\$|_)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $highConfidenceBytecodeRegex = [regex]::new('(?i)\b(MaceAssistManager|AnchorMacroManager|DoubleAnchorManager|AutoCrystalManager|AutoTotemManager|TriggerbotManager|AutomatorManager|LungeMacroManager|ExplodeManager|StreamProofOverlayManager|WebConfigServer|MultiKeyBindingClient)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    $suspPats = @(
        "RotationManager","AimAssist","AimBot","lookAt","snapTo","smoothAim",
        "smoothRotate","rotateToEntity","rotateToPlayer","predictRotation",
        "ReachCheck","ReachExtend","hitboxSize","attackRange","extendHitbox",
        "setReach","hitboxExpand","reachDistance",
        "EspModule","PlayerESP","StorageESP","TracerModule","drawBox","drawOutline",
        "KillAura","MultiAura","TriggerBot","AutoClick","attackEntity",
        "autoSwing","swingAura","autoAttack","attackAura","triggerAttack",
        "FlightModule","SpeedModule","NoFall","StepModule","TimerModule",
        "VelocityModule","AntiKnockback","NoVelocity","velocityMultiplier",
        "InjectLoader","AgentLoader","premain","agentmain","retransformClasses",
        "AntiScreen","DisableDebugger","AntiAC","BypassAC","checkIntegrity",
        "streamProof","StreamProof","hideFromScreen","overlayWindow","invisibleOverlay",
        "MaceAssistManager","MaceAssist","maceAssist","maceTrigger","MaceTrigger",
        "LungeMacro","lungeMacro","maceAim","MaceAim","maceBoost","MaceBoost",
        "TriggerbotManager","triggerbotManager","triggerBot","TriggerBot",
        "PlayerEspManager","playerEspManager","StreamProofOverlayManager",
        "WebConfigServer","webConfigServer","explodeMod","ExplodeMod",
        "WindChargeAssist","windChargeAssist","maceSwing","autoMace","AutoMace",
        "fallVelocityCheck","minFallDistance","aimAssistEnabled",
        "smartCrit","smartCrits","shieldBypass","ShieldBypass","autoAxeSwap",
        "CrystalAura","crystalAura","AutoCrystal","autoCrystal",
        "AnchorMacro","anchorMacro","DoubleAnchor","doubleAnchor",
        "Allatori","Obfuscated by","Stringer","Zelix","DashO","JBCO","SkidFuscator"
    )
    $suspRegex = [regex]::new('(?i)\b(' + (($suspPats | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $dangerRegex = [regex]::new('(?i)(java/lang/instrument/|sun/misc/Unsafe|java/lang/reflect/Proxy|com/sun/tools/attach/)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $heurRegex = [regex]::new('(?i)\b(killaura|aimbot|triggerbot|reach|velocitymultiplier|antivelocity|novelocity|esp|wallhack|xray|bhop|fly|freecam|nofall|autoeat|scaffold|phase|step|jesus|wurst|meteor|vape|bleachhack|future|sigma|rusherhack|liquidbounce|autoclicker|hack|cheat)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $mixinHeurRegex = [regex]::new('(?i)(killaura|aimbot|autoclicker|reach|velocitymultiplier|antivelocity|esp|cheat|hack|antiac)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    # AI Helper: Shannon entropy (randomness measure for obfuscation detection)
    function Measure-NameEntropy {
        param([string]$s)
        if (-not $s -or $s.Length -lt 4) { return 0.0 }
        $freq = @{}
        foreach ($c in $s.ToCharArray()) { $k = "$c"; if ($freq[$k]) { $freq[$k]++ } else { $freq[$k] = 1 } }
        $len = $s.Length; $ent = 0.0
        foreach ($v in $freq.Values) { $p = $v / $len; $ent -= $p * [Math]::Log($p, 2) }
        return [Math]::Round($ent, 3)
    }

    $readBuf  = [byte[]]::new(65536)
    $smallBuf = [byte[]]::new(8192)

    foreach ($mod in $uniqueJars) {
        if (Get-Command Pump-WpfEvents -ErrorAction SilentlyContinue) { Pump-WpfEvents }

        $cacheKey = "$($mod.Name)|$($mod.Length)"
        if ($Global:ModAnalysisCache.ContainsKey($cacheKey)) {
            $cached = $Global:ModAnalysisCache[$cacheKey]
            $cloned = [PSCustomObject]@{
                Name          = $cached.Name
                FileName      = $cached.FileName
                FullPath      = $mod.FullName
                SizeKB        = $cached.SizeKB
                LastWriteTime = $mod.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                IsFlagged     = $cached.IsFlagged
                Category      = $cached.Category
                Reason        = $cached.Reason
                AIRiskScore   = $cached.AIRiskScore
                AIDetails     = $cached.AIDetails
            }
            $result.Mods.Add($cloned)
            if ($cloned.IsFlagged) { $result.FlaggedMods.Add($cloned); $result.FlaggedCount++ }
            continue
        }

        $isFlagged    = $false
        $reason       = "Clean"
        $category     = "CLEAN"
        $aiRisk       = 0
        $aiDetails    = [System.Collections.Generic.List[string]]::new()
        $displayName  = [System.IO.Path]::GetFileNameWithoutExtension($mod.Name)

        # -- LAYER 1: Filename signature matching ------------------------------
        $isKnownLegit = $false
        if ($Global:LegitimateModSignatures) {
            foreach ($ls in $Global:LegitimateModSignatures) {
                if ($mod.Name -match "(?i)$ls") { $isKnownLegit = $true; break }
            }
        }

        if (-not $isKnownLegit) {
            foreach ($sig in $Global:CheatSignatures) {
                if ($mod.Name -match "(?i)$sig") {
                    $isFlagged = $true; $category = "FLAGGED CHEAT / DISALLOWED"
                    $reason = "Filename matches known cheat signature: $sig"; $aiRisk = 100; break
                }
            }
        }

        if (-not $isFlagged) {
            try {
                $zip        = [System.IO.Compression.ZipFile]::OpenRead($mod.FullName)
                $allEntries = @($zip.Entries)

                # Single-pass fast classification of all entries (avoids slow PowerShell pipelines)
                $classEntries  = [System.Collections.Generic.List[System.IO.Compression.ZipArchiveEntry]]::new()
                $classNames    = [System.Collections.Generic.List[string]]::new()
                $mixinEntries  = [System.Collections.Generic.List[System.IO.Compression.ZipArchiveEntry]]::new()
                $resourceCount = 0

                foreach ($entry in $allEntries) {
                    $fn = $entry.FullName
                    if ($fn.EndsWith(".class", [System.StringComparison]::OrdinalIgnoreCase)) {
                        $classEntries.Add($entry)
                        $classNames.Add([System.IO.Path]::GetFileNameWithoutExtension($fn))
                    } elseif (-not $fn.EndsWith("/")) {
                        $resourceCount++
                        if ($fn -match "mixin.*\.json$") {
                            $mixinEntries.Add($entry)
                        }
                    }
                }

                # -- LAYER 2: Mod metadata inspection -----------------------------
                $metaNames  = @("fabric.mod.json","quilt.mod.json","mcmod.info","META-INF/mods.toml","META-INF/MANIFEST.MF")
                $metaAll    = ""
                $hasMeta    = $false

                foreach ($mn in $metaNames) {
                    $me = $zip.GetEntry($mn)
                    if ($me) {
                        $hasMeta = $true
                        try {
                            $ms = $me.Open(); $mr = [System.IO.StreamReader]::new($ms)
                            $metaAll += $mr.ReadToEnd(); $mr.Close(); $ms.Close()
                        } catch {}
                    }
                }

                if ($metaAll) {
                    # Check if metadata declares a legitimate mod ID
                    if ($Global:LegitimateModSignatures -and -not $isKnownLegit) {
                        foreach ($ls in $Global:LegitimateModSignatures) {
                            if ($metaAll -match "(?i)""id""\s*:\s*""[^""]*$ls") { $isKnownLegit = $true; break }
                        }
                    }

                    # Known cheat signature in metadata id/name
                    if (-not $isKnownLegit) {
                        foreach ($sig in $Global:CheatSignatures) {
                            if ($metaAll -match "(?i)""id""\s*:\s*""[^""]*$sig" -or
                                $metaAll -match "(?i)""name""\s*:\s*""[^""]*$sig") {
                                $isFlagged = $true; $category = "FLAGGED CHEAT / DISALLOWED"
                                $reason = "Mod metadata id/name matches cheat signature: $sig"; $aiRisk = 100; break
                            }
                        }
                    }
                    # Extra heuristic keywords in metadata
                    if (-not $isFlagged) {
                        $mMatch = $heurRegex.Match($metaAll)
                        if ($mMatch.Success) {
                            $aiRisk += 40
                            $aiDetails.Add("Metadata contains cheat keyword: '$($mMatch.Value)'")
                        }
                    }
                }

                if (-not $isFlagged) {

                    # -- LAYER 3: Mixin configuration analysis ---------------------
                    foreach ($entry in $mixinEntries) {
                        try {
                            $ms = $entry.Open(); $mr = [System.IO.StreamReader]::new($ms)
                            $mc = $mr.ReadToEnd(); $mr.Close(); $ms.Close()
                            if ($mixinHeurRegex.IsMatch($mc)) {
                                $aiRisk += 50; $aiDetails.Add("Mixin targets cheat/combat class: $($entry.FullName)"); break
                            }
                        } catch {}
                    }

                    # -- LAYER 4: Known cheat class-path packages & combat automation classes
                    foreach ($entry in $classEntries) {
                        $fn = $entry.FullName
                        if ($cheatClassRegex.IsMatch($fn)) {
                            $isFlagged = $true
                            $shortName = [System.IO.Path]::GetFileNameWithoutExtension($fn)
                            if ($hasMeta) {
                                $category = "DISGUISED CHEAT / TROJAN MOD"
                                $reason = "Trojan/Fake mod: disguised as innocent mod but contains combat automation class: $shortName"
                            } else {
                                $category = "FLAGGED CHEAT / DISALLOWED"
                                $reason = "Contains combat automation / macro class: $shortName"
                            }
                            $aiRisk = 100
                            break
                        }
                    }

                    if (-not $isFlagged) {
                        foreach ($entry in $allEntries) {
                            $fn = $entry.FullName
                            if ($cheatPkgRegex.IsMatch($fn)) {
                                $isFlagged = $true; $category = "FLAGGED CHEAT / DISALLOWED"
                                $reason = "Contains known cheat class package: $fn"; $aiRisk = 100; break
                            }
                        }
                    }

                    if (-not $isFlagged) {

                        # -- LAYER 5: Suspicious string constants in .class bytecode ---
                        $checkCount = [Math]::Min(25, $classEntries.Count)
                        $strHits    = [System.Collections.Generic.List[string]]::new()
                        $highHit    = $null

                        for ($ci = 0; $ci -lt $checkCount; $ci++) {
                            $ce = $classEntries[$ci]
                            try {
                                $ces = $ce.Open()
                                $readLen = $ces.Read($readBuf, 0, [Math]::Min($ce.Length, 65536))
                                $ces.Close()
                                $classAscii = [System.Text.Encoding]::ASCII.GetString($readBuf, 0, $readLen)
                                if (-not $highHit -and $highConfidenceBytecodeRegex.IsMatch($classAscii)) {
                                    $highHit = $highConfidenceBytecodeRegex.Match($classAscii).Value
                                }
                                $matches = $suspRegex.Matches($classAscii)
                                foreach ($m in $matches) {
                                    if ($strHits.Count -lt 6 -and -not $strHits.Contains($m.Value)) {
                                        $strHits.Add($m.Value)
                                    }
                                }
                            } catch {}
                        }

                        if ($highHit) {
                            $isFlagged = $true
                            if ($hasMeta) {
                                $category = "DISGUISED CHEAT / TROJAN MOD"
                                $reason = "Trojan/Fake mod: bytecode contains combat automation hook: $highHit"
                            } else {
                                $category = "FLAGGED CHEAT / DISALLOWED"
                                $reason = "Bytecode contains combat automation hook: $highHit"
                            }
                            $aiRisk = 100
                        } elseif ($strHits.Count -ge 4) { $aiRisk += 55; $aiDetails.Add("Bytecode: $($strHits.Count) cheat API strings - '$($strHits[0])'") }
                        elseif   ($strHits.Count -ge 2) { $aiRisk += 28; $aiDetails.Add("Bytecode suspicious strings: '$($strHits[0])'") }
                        elseif   ($strHits.Count -eq 1) { $aiRisk += 10; $aiDetails.Add("Bytecode minor suspicious string: '$($strHits[0])'") }

                        # -- LAYER 6: Obfuscation entropy scoring ------------------
                        if ($classNames.Count -ge 5) {
                            $shortCount = 0
                            foreach ($cn in $classNames) { if ($cn.Length -le 2) { $shortCount++ } }
                            $shortRatio = $shortCount / $classNames.Count

                            if ($shortRatio -gt 0.65 -and $classNames.Count -gt 20) {
                                $aiRisk += 35; $aiDetails.Add("Heavy obfuscation: $([math]::Round($shortRatio*100))% of $($classNames.Count) classes are 1-2 char names")
                            } elseif ($shortRatio -gt 0.35 -and $classNames.Count -gt 10) {
                                $aiRisk += 14; $aiDetails.Add("Moderate obfuscation: $([math]::Round($shortRatio*100))% short class names")
                            }
                            $sampleStr = ($classNames | Select-Object -First 30) -join ""
                            $ent = Measure-NameEntropy -s $sampleStr
                            if ($ent -gt 4.6) { $aiRisk += 18; $aiDetails.Add("High class-path entropy ($ent bits) - randomized naming") }
                        }

                        # -- LAYER 7: Suspicious JAR structure ---------------------
                        $classCount = $classEntries.Count
                        $sizeKB     = [math]::Round($mod.Length / 1KB, 1)

                        if (-not $hasMeta)                                { $aiRisk += 20; $aiDetails.Add("No mod metadata (unusual for legitimate mods)") }
                        if ($resourceCount -eq 0 -and $classCount -gt 5) { $aiRisk += 15; $aiDetails.Add("Pure class-only JAR ($classCount classes, 0 resources)") }
                        if ($sizeKB -lt 25 -and $classCount -gt 12)      { $aiRisk += 18; $aiDetails.Add("Suspicious: $sizeKB KB JAR with $classCount classes (typical loader)") }

                        # -- LAYER 8: Dangerous Java API imports -------------------
                        $dangerHits  = 0
                        $dangerLimit = [Math]::Min(6, $classEntries.Count)

                        for ($di = 0; $di -lt $dangerLimit; $di++) {
                            $ce = $classEntries[$di]
                            try {
                                $ces = $ce.Open(); $rlen = $ces.Read($smallBuf, 0, 8192); $ces.Close()
                                $es  = [System.Text.Encoding]::ASCII.GetString($smallBuf, 0, $rlen)
                                if ($dangerRegex.IsMatch($es)) { $dangerHits++ }
                            } catch {}
                        }
                        if ($dangerHits -ge 3) { $aiRisk += 25; $aiDetails.Add("$dangerHits dangerous Java APIs: instrument/unsafe/proxy/attach") }
                        elseif ($dangerHits -gt 0) { $aiRisk += 8 }

                        $zip.Dispose()

                        # -- Final AI Verdict ---------------------------------------
                        $aiRisk = [Math]::Min($aiRisk, 99)

                        if ($aiRisk -ge 60) {
                            $isFlagged = $true; $category = "HEURISTIC RISK - AI FLAGGED"
                            $top = if ($aiDetails.Count -gt 0) { $aiDetails[0] } else { "Multiple heuristic triggers" }
                            $reason = "AI Risk: $aiRisk/99 - $top"
                        } elseif ($aiRisk -ge 30) {
                            $category = "LOW RISK - REVIEW SUGGESTED"
                            $top = if ($aiDetails.Count -gt 0) { $aiDetails[0] } else { "Minor heuristic hit" }
                            $reason = "AI Risk: $aiRisk/99 - $top"
                        }

                    } else { $zip.Dispose() }
                } else { $zip.Dispose() }
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
            AIRiskScore   = $aiRisk
            AIDetails     = if ($aiDetails.Count -gt 0) { ($aiDetails -join " | ") } else { "" }
        }

        $result.Mods.Add($modObj)
        $Global:ModAnalysisCache[$cacheKey] = $modObj
        if ($isFlagged) { $result.FlaggedMods.Add($modObj); $result.FlaggedCount++ }
    }

    $result.TotalCount = $result.Mods.Count
    return $result
}


function Scan-LastPlayedInstance {
    param([scriptblock]$ProgressCallback)
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

    $instIdx = 0
    $instTotal = [Math]::Max(1, $uniqueInstances.Count)
    foreach ($inst in $uniqueInstances) {
        $instIdx++
        if ($ProgressCallback) {
            $curPct = [Math]::Min(35, 16 + [int][Math]::Round(($instIdx / $instTotal) * 19))
            & $ProgressCallback $curPct "Deep scanning [$($inst.Launcher)] $($inst.Profile)"
        }
        if (Get-Command Pump-WpfEvents -ErrorAction SilentlyContinue) { Pump-WpfEvents }
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
            if (-not $Global:ReportData.DownloadFiles) {
                $Global:ReportData['DownloadFiles'] = @()
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
    Compact Floating Window with Fishbone Logo, Deep Multi-Instance Scan, Dynamic Client/Instance Selector & Full Mods Browser
#>

function Show-GrickoGui {
    param(
        [int]$HoursPrefetch = 168,
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

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gricko SS Tool" Height="540" Width="580"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ResizeMode="NoResize" FontFamily="Segoe UI, Tahoma, Helvetica, Arial">

    <Window.Resources>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="6"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Track Name="PART_Track" IsDirectionReversed="True">
                            <Track.Thumb>
                                <Thumb>
                                    <Thumb.Template>
                                        <ControlTemplate TargetType="Thumb">
                                            <Border Background="#334155" CornerRadius="3"/>
                                        </ControlTemplate>
                                    </Thumb.Template>
                                </Thumb>
                            </Track.Thumb>
                        </Track>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#161822"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderBrush" Value="#2E344A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#161822"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="FontSize" Value="11"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#2E1C48"/>
                    <Setter Property="Foreground" Value="#C084FC"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#3B2667"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Border Name="RootBorder" Background="#0F1015" CornerRadius="12" BorderBrush="#1E2029" BorderThickness="1.5">
        <Border.Effect>
            <DropShadowEffect BlurRadius="30" Color="#000000" Opacity="0.85" ShadowDepth="6"/>
        </Border.Effect>

        <Grid Margin="20,14,20,16">
            <Grid.RowDefinitions>
                <RowDefinition Height="32"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="18"/>
            </Grid.RowDefinitions>

            <!-- TITLE BAR -->
            <Grid Name="TitleBarGrid" Grid.Row="0" Background="Transparent">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="GRICKO" Foreground="#F8FAFC" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                    <TextBlock Text=" SS TOOL" Foreground="#818CF8" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                    <Border Background="#1E2230" CornerRadius="4" Padding="6,1" Margin="8,0,0,0" VerticalAlignment="Center">
                        <TextBlock Text="v2.3" Foreground="#94A3B8" FontSize="9.5" FontWeight="SemiBold"/>
                    </Border>
                </StackPanel>

                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button Name="BtnMin" Content="-" Width="28" Height="24" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" FontSize="14" Cursor="Hand" FontWeight="Bold"/>
                    <Button Name="BtnClose" Content="x" Width="28" Height="24" Background="Transparent" Foreground="#94A3B8" BorderThickness="0" FontSize="13" Cursor="Hand" FontWeight="Bold" Margin="2,0,0,0"/>
                </StackPanel>
            </Grid>

            <!-- MAIN CONTENT AREA -->
            <Grid Grid.Row="1" Margin="0,4,0,4">

                <!-- VIEW 1: HOME (COMPACT OCEAN STYLE) -->
                <StackPanel Name="HomeView" Visibility="Visible" HorizontalAlignment="Center" VerticalAlignment="Center" Width="380">
                    <Image Name="LogoImgHome" Width="140" Height="68" HorizontalAlignment="Center" Margin="0,0,0,16" RenderOptions.BitmapScalingMode="HighQuality"/>
                    <TextBlock Text="GRICKO SCREENSHARE" Foreground="#F8FAFC" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,3"/>
                    <TextBlock Text="Next-Gen Automated Minecraft Forensic Engine" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,24"/>

                    <Button Name="BtnScan" Width="200" Height="42" Content="SCAN" FontSize="14" FontWeight="Bold" Foreground="#0F1015" Cursor="Hand">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Name="BtnBorder" CornerRadius="21">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="#FFFFFF" Offset="0.0"/>
                                            <GradientStop Color="#CBD5E1" Offset="1.0"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="BtnBorder" Property="Background">
                                            <Setter.Value>
                                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                    <GradientStop Color="#FFFFFF" Offset="0.0"/>
                                                    <GradientStop Color="#E2E8F0" Offset="1.0"/>
                                                </LinearGradientBrush>
                                            </Setter.Value>
                                        </Setter>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>

                    <TextBlock Text="Deep PC, Multi-Client &amp; All Mods Analysis" Foreground="#475569" FontSize="10.5" HorizontalAlignment="Center" Margin="0,14,0,0"/>
                </StackPanel>

                <!-- VIEW 2: 2-MINUTE PROGRESS SCAN -->
                <StackPanel Name="ProgressView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="440">
                    <Image Name="LogoImgProgress" Width="120" Height="58" HorizontalAlignment="Center" Margin="0,0,0,12" RenderOptions.BitmapScalingMode="HighQuality"/>
                    <TextBlock Text="DEEP SCANNING SYSTEM" Foreground="#F8FAFC" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                    <TextBlock Text="Analyzing all Minecraft clients, instances, memory &amp; mods" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,20"/>

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

                    <TextBlock Name="TxtProgressStatus" Text="Initializing deep PC inspection... - 0%" Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- VIEW 3: RESULTS SUMMARY -->
                <StackPanel Name="ResultsView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="480">
                    <Image Name="LogoImgResults" Width="110" Height="54" HorizontalAlignment="Center" Margin="0,0,0,8" RenderOptions.BitmapScalingMode="HighQuality"/>
                    
                    <TextBlock Name="TxtResultTitle" Text="Scan Complete" Foreground="#F8FAFC" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                    <TextBlock Name="TxtResultSubtitle" Text="System &amp; client inspection finished" Foreground="#34D399" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,10"/>

                    <!-- Client & Instance Info Card with Dynamic Selector -->
                    <Border Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,10" Margin="0,0,0,10">
                        <StackPanel>
                            <DockPanel Margin="0,0,0,5">
                                <TextBlock Text="TARGET CLIENT &amp; INSTANCE" Foreground="#94A3B8" FontSize="10.5" FontWeight="Bold" VerticalAlignment="Center"/>
                                <TextBlock Name="TxtResultTime" Text="N/A" Foreground="#38BDF8" FontSize="10.5" FontWeight="Bold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            </DockPanel>

                            <!-- Client / Instance Selector Dropdown -->
                            <ComboBox Name="CmbResultInstance" Margin="0,2,0,6" Cursor="Hand"/>

                            <TextBlock Name="TxtResultClient" Text="Client   : Detecting..." Foreground="#E2E8F0" FontSize="12" FontWeight="SemiBold" Margin="0,1"/>
                            <TextBlock Name="TxtResultProfile" Text="Profile  : Standard" Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtResultServer" Text="Server   : None" Foreground="#38BDF8" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Border>

                    <!-- Cheat & Mod Detection Result Box -->
                    <Border Name="DetectionBox" Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,8" Margin="0,0,0,12">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="TxtDetectionsBadge" Text="[OK] No Cheats or Suspicious Clients Detected" Foreground="#34D399" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtCheatList" Text="" Foreground="#F87171" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,3,0,0" Visibility="Collapsed"/>
                        </StackPanel>
                    </Border>

                    <!-- Action Buttons -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button Name="BtnDetails" Content="DETAILS" Width="105" Height="34" FontSize="11.5" FontWeight="Bold" Foreground="#FFFFFF" Background="#262A38" BorderBrush="#3B4259" BorderThickness="1" Cursor="Hand" Margin="0,0,8,0">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                        <Button Name="BtnMods" Content="ALL MODS" Width="125" Height="34" FontSize="11.5" FontWeight="Bold" Foreground="#FFFFFF" Background="#2E1C48" BorderBrush="#7C3AED" BorderThickness="1" Cursor="Hand" Margin="0,0,8,0">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                        <Button Name="BtnRescan" Content="RE-SCAN" Width="95" Height="34" FontSize="11.5" FontWeight="Bold" Foreground="#94A3B8" Background="#161822" BorderThickness="0" Cursor="Hand">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                    </StackPanel>
                </StackPanel>

                <!-- VIEW 4: CLEAN DETAILS VIEW -->
                <Grid Name="DetailsView" Visibility="Collapsed" Height="365" Margin="4,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,6">
                        <TextBlock Text="FORENSIC INSPECTION DETAILS" Foreground="#F8FAFC" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button Name="BtnBackFromDetails" Content="&lt;- Back" Background="Transparent" Foreground="#38BDF8" BorderThickness="0" FontSize="12" FontWeight="SemiBold" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>

                    <!-- Client & Instance Chooser in Details -->
                    <Border Grid.Row="1" Background="#161822" CornerRadius="6" BorderBrush="#25293A" BorderThickness="1" Padding="8,4" Margin="0,0,0,6">
                        <DockPanel>
                            <TextBlock Text="TARGET INSTANCE:" Foreground="#818CF8" FontSize="10.5" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <ComboBox Name="CmbDetailsInstance" Cursor="Hand"/>
                        </DockPanel>
                    </Border>

                    <Border Grid.Row="2" Background="#0C0D11" CornerRadius="8" BorderBrush="#1C1E26" BorderThickness="1" Padding="12">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Name="DetailsContentPanel">
                                <!-- Populated dynamically based on selected client/instance -->
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <DockPanel Grid.Row="3" Margin="0,6,0,0">
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

                <!-- VIEW 5: ALL INSTALLED MODS BROWSER -->
                <Grid Name="ModsView" Visibility="Collapsed" Height="365" Margin="4,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,6">
                        <StackPanel>
                            <TextBlock Name="TxtModsTitle" Text="INSTALLED MODS" Foreground="#F8FAFC" FontSize="13" FontWeight="Bold"/>
                            <TextBlock Name="TxtModsSubtitle" Text="Last Played Instance" Foreground="#A78BFA" FontSize="11"/>
                        </StackPanel>
                        <Button Name="BtnBackFromMods" Content="&lt;- Back" Background="Transparent" Foreground="#38BDF8" BorderThickness="0" FontSize="12" FontWeight="SemiBold" Cursor="Hand" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </DockPanel>

                    <!-- Client & Instance Switcher in Mods View -->
                    <Border Grid.Row="1" Background="#161822" CornerRadius="6" BorderBrush="#25293A" BorderThickness="1" Padding="8,3" Margin="0,0,0,6">
                        <DockPanel>
                            <TextBlock Text="INSTANCE:" Foreground="#818CF8" FontSize="10.5" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <ComboBox Name="CmbModsInstance" Cursor="Hand"/>
                        </DockPanel>
                    </Border>

                    <!-- Filter / Search Box -->
                    <Border Grid.Row="2" Background="#161822" CornerRadius="6" BorderBrush="#262A38" BorderThickness="1" Padding="10,4" Margin="0,0,0,6">
                        <DockPanel>
                            <TextBlock Text="Search:" Foreground="#64748B" FontSize="11" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <TextBox Name="TxtModSearch" Background="Transparent" Foreground="#F1F5F9" BorderThickness="0" FontSize="11.5" VerticalAlignment="Center"/>
                        </DockPanel>
                    </Border>

                    <!-- Mods List ScrollViewer -->
                    <Border Grid.Row="3" Background="#0C0D11" CornerRadius="8" BorderBrush="#1C1E26" BorderThickness="1" Padding="8">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Name="ModsListPanel">
                                <!-- Populated dynamically with clean mod cards -->
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <DockPanel Grid.Row="4" Margin="0,6,0,0">
                        <TextBlock Name="TxtModsSummaryStats" Text="0 Mods Installed" Foreground="#64748B" FontSize="11" VerticalAlignment="Center"/>
                        <TextBlock Name="TxtModsFlaggedCount" Text="" Foreground="#EF4444" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
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

    $xml = [xml]$xaml
    $reader = [System.Xml.XmlNodeReader]::new($xml)
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
    $modsView          = $window.FindName("ModsView")

    $logoImgHome       = $window.FindName("LogoImgHome")
    $logoImgProgress   = $window.FindName("LogoImgProgress")
    $logoImgResults    = $window.FindName("LogoImgResults")

    $btnScan           = $window.FindName("BtnScan")
    $btnRescan         = $window.FindName("BtnRescan")
    $btnDetails        = $window.FindName("BtnDetails")
    $btnMods           = $window.FindName("BtnMods")
    $btnBackFromDetails= $window.FindName("BtnBackFromDetails")
    $btnBackFromMods   = $window.FindName("BtnBackFromMods")
    $btnExportJson     = $window.FindName("BtnExportJson")

    $scanProgress      = $window.FindName("ScanProgress")
    $txtProgressStatus = $window.FindName("TxtProgressStatus")

    $txtResultTitle    = $window.FindName("TxtResultTitle")
    $txtResultSubtitle = $window.FindName("TxtResultSubtitle")
    $txtResultTime     = $window.FindName("TxtResultTime")
    $txtResultClient   = $window.FindName("TxtResultClient")
    $txtResultProfile  = $window.FindName("TxtResultProfile")
    $txtResultServer   = $window.FindName("TxtResultServer")

    $cmbResultInstance = $window.FindName("CmbResultInstance")
    $cmbDetailsInstance= $window.FindName("CmbDetailsInstance")
    $cmbModsInstance   = $window.FindName("CmbModsInstance")

    $detectionBox      = $window.FindName("DetectionBox")
    $txtDetectionsBadge= $window.FindName("TxtDetectionsBadge")
    $txtCheatList      = $window.FindName("TxtCheatList")

    $detailsContentPanel = $window.FindName("DetailsContentPanel")
    $txtSummaryStats   = $window.FindName("TxtSummaryStats")

    $txtModsTitle      = $window.FindName("TxtModsTitle")
    $txtModsSubtitle   = $window.FindName("TxtModsSubtitle")
    $txtModSearch      = $window.FindName("TxtModSearch")
    $modsListPanel     = $window.FindName("ModsListPanel")
    $txtModsSummaryStats = $window.FindName("TxtModsSummaryStats")
    $txtModsFlaggedCount = $window.FindName("TxtModsFlaggedCount")

    # Set Transparent Logo on Image Controls
    $logoSrc = Get-LogoSource
    if ($logoSrc) {
        $logoImgHome.Source = $logoSrc
        $logoImgProgress.Source = $logoSrc
        $logoImgResults.Source = $logoSrc
    }

    # Free Window Dragging
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
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnMods.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnBackFromDetails.Add_Click({
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnBackFromMods.Add_Click({
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnRescan.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $modsView.Visibility = [System.Windows.Visibility]::Collapsed
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
        $tbLbl.Width = 95
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

    # Populate Mods View with Clean Cards
    function Render-ModsList {
        param([string]$Filter = "")
        $modsListPanel.Children.Clear()

        $mods = $Global:ReportData.ActiveInstanceMods
        if (-not $mods -or $mods.Count -eq 0) {
            $tbEmpty = [System.Windows.Controls.TextBlock]::new()
            $tbEmpty.Text = "No mods found for this instance."
            $tbEmpty.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $tbEmpty.FontSize = 11.5
            $tbEmpty.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            $tbEmpty.Margin = [System.Windows.Thickness]::new(0, 30, 0, 0)
            $modsListPanel.Children.Add($tbEmpty) | Out-Null
            return
        }

        $filteredMods = if ($Filter) {
            $mods | Where-Object { $_.Name -like "*$Filter*" -or $_.FileName -like "*$Filter*" -or $_.Reason -like "*$Filter*" }
        } else {
            $mods
        }

        # Sort: Known cheats first, then AI-flagged by risk score, then low-risk, then clean alphabetical
        $sortedMods = $filteredMods | Sort-Object -Property @{
            Expression = {
                if ($_.IsFlagged -and $_.Category -notlike "*HEURISTIC*") { 3 }
                elseif ($_.Category -like "*HEURISTIC*") { 2 }
                elseif ($_.Category -like "*LOW RISK*") { 1 }
                else { 0 }
            }; Descending = $true
        }, @{ Expression = { if ($_.AIRiskScore) { $_.AIRiskScore } else { 0 } }; Descending = $true },
           @{ Expression = { $_.Name }; Descending = $false }


        foreach ($mod in $sortedMods) {
            $card = [System.Windows.Controls.Border]::new()
            $card.CornerRadius = [System.Windows.CornerRadius]::new(6)
            $card.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
            $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)

            $cardStack = [System.Windows.Controls.StackPanel]::new()
            $headerDock = [System.Windows.Controls.DockPanel]::new()

            $tbName = [System.Windows.Controls.TextBlock]::new()
            $tbName.Text = $mod.FileName
            $tbName.FontSize = 11.5
            $tbName.FontWeight = [System.Windows.FontWeights]::SemiBold
            $tbName.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

            $badge = [System.Windows.Controls.Border]::new()
            $badge.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $badge.Padding = [System.Windows.Thickness]::new(6, 1, 6, 1)
            [System.Windows.Controls.DockPanel]::SetDock($badge, [System.Windows.Controls.Dock]::Right)

            $tbBadge = [System.Windows.Controls.TextBlock]::new()
            $tbBadge.FontSize = 9.5
            $tbBadge.FontWeight = [System.Windows.FontWeights]::Bold

            $isAiHeuristic  = ($mod.Category -like "*HEURISTIC*")
            $isLowRisk      = ($mod.Category -like "*LOW RISK*")

            if ($mod.IsFlagged -and -not $isAiHeuristic) {
                # Known cheat signature - Red
                $card.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A1215")
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7F1D1D")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $badge.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7F1D1D")
                $tbBadge.Text      = "KNOWN CHEAT"
                $tbBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FCA5A5")
                $tbName.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            } elseif ($isAiHeuristic) {
                # AI heuristic risk - Orange
                $card.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#271810")
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#92400E")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $badge.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#92400E")
                $riskScore = if ($mod.AIRiskScore) { " ($($mod.AIRiskScore)/99)" } else { "" }
                $tbBadge.Text      = "AI RISK$riskScore"
                $tbBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FCD34D")
                $tbName.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FB923C")
            } elseif ($isLowRisk) {
                # Low risk / review - Yellow
                $card.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1900")
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#713F12")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $badge.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#713F12")
                $riskScore = if ($mod.AIRiskScore) { " ($($mod.AIRiskScore)/99)" } else { "" }
                $tbBadge.Text      = "REVIEW$riskScore"
                $tbBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FEF08A")
                $tbName.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EAB308")
            } else {
                # Clean - Green
                $card.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#131620")
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E2330")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                $badge.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                $tbBadge.Text      = "CLEAN"
                $tbBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6EE7B7")
                $tbName.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E8F0")
            }

            $badge.Child = $tbBadge
            $headerDock.Children.Add($badge) | Out-Null
            $headerDock.Children.Add($tbName) | Out-Null
            $cardStack.Children.Add($headerDock) | Out-Null

            if ($mod.IsFlagged -or $isAiHeuristic -or $isLowRisk) {
                $tbReason = [System.Windows.Controls.TextBlock]::new()
                $prefix = if ($mod.IsFlagged -and -not $isAiHeuristic) { "[!] " } elseif ($isAiHeuristic) { "[AI] " } else { "[?] " }
                $tbReason.Text = $prefix + $mod.Reason
                $reasonColor = if ($mod.IsFlagged -and -not $isAiHeuristic) { "#FBBF24" } elseif ($isAiHeuristic) { "#FB923C" } else { "#EAB308" }
                $tbReason.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($reasonColor)
                $tbReason.FontSize = 10.5
                $tbReason.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $tbReason.Margin = [System.Windows.Thickness]::new(0, 2, 0, 1)
                $cardStack.Children.Add($tbReason) | Out-Null

                # Show additional AI analysis details if present
                if ($mod.AIDetails -and $mod.AIDetails.Length -gt 0) {
                    $tbAI = [System.Windows.Controls.TextBlock]::new()
                    $tbAI.Text = "AI Analysis: " + $mod.AIDetails
                    $tbAI.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
                    $tbAI.FontSize = 10
                    $tbAI.TextWrapping = [System.Windows.TextWrapping]::Wrap
                    $tbAI.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)
                    $cardStack.Children.Add($tbAI) | Out-Null
                }
            }

            $tbMeta = [System.Windows.Controls.TextBlock]::new()
            $tbMeta.Text = "Size: " + $mod.SizeKB + " KB  |  Modified: " + $mod.LastWriteTime
            $tbMeta.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $tbMeta.FontSize = 10
            $cardStack.Children.Add($tbMeta) | Out-Null

            $card.Child = $cardStack
            $modsListPanel.Children.Add($card) | Out-Null
        }
    }

    # Live Search on Mod Box
    $txtModSearch.Add_TextChanged({
        Render-ModsList -Filter $txtModSearch.Text.Trim()
    })

    # Render Forensic Details for Chosen Instance
    $script:cachedActualCheats = @()

    function Render-DetailsForInstance {
        param([PSCustomObject]$inst)

        $detailsContentPanel.Children.Clear()
        if (-not $inst) { return }

        Add-CleanSectionHeader "CHOSEN MINECRAFT INSTANCE & SESSION"
        Add-CleanRow "Client"   $inst.Launcher "#38BDF8"
        Add-CleanRow "Profile"  $inst.Profile "#E2E8F0"
        if ($inst.Version) { Add-CleanRow "Version"  $inst.Version "#E2E8F0" }
        Add-CleanRow "Played"   $inst.LastPlayedTime "#34D399"
        Add-CleanRow "Path"     $inst.Path "#94A3B8"
        if ($inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
            Add-CleanRow "Server"   ($inst.ConnectedServers -join ", ") "#38BDF8"
        } else {
            Add-CleanRow "Server"   "Singleplayer / Unrecorded" "#64748B"
        }

        if ($inst.IsLogWiped) {
            Add-CleanRow "Log File" "LOG WAS WIPED / 0 BYTES (ALERT!)" "#EF4444"
        } elseif ($inst.SuspiciousLog -and $inst.SuspiciousLog.Count -gt 0) {
            Add-CleanRow "Log Hits" "$($inst.SuspiciousLog.Count) suspicious lines identified" "#FBBF24"
        } else {
            Add-CleanRow "Log Status" "Normal session log integrity" "#34D399"
        }

        Add-CleanSectionHeader "INSTANCE MODS ($($inst.TotalModsCount) TOTAL)"
        Add-CleanRow "Installed" "$($inst.TotalModsCount) mod jar(s) in profile" "#38BDF8"
        if ($inst.FlaggedModsCount -gt 0) {
            Add-CleanRow "Suspicious" "$($inst.FlaggedModsCount) cheat mod(s) flagged!" "#EF4444"
            foreach ($fm in $inst.FlaggedMods) {
                Add-CleanRow " - Flagged" "$($fm.FileName) ($($fm.Reason))" "#FBBF24"
            }
        } else {
            Add-CleanRow "Integrity" "All $($inst.TotalModsCount) mods passed integrity scan" "#34D399"
        }

        # Summary of All Other Discovered Instances on PC
        if ($Global:ReportData.AllInstances -and $Global:ReportData.AllInstances.Count -gt 1) {
            Add-CleanSectionHeader "ALL DISCOVERED CLIENTS & PROFILES ($($Global:ReportData.AllInstances.Count) TOTAL)"
            foreach ($other in $Global:ReportData.AllInstances) {
                $stColor = if ($other.FlaggedModsCount -gt 0) { "#EF4444" } else { "#34D399" }
                $stDesc = if ($other.FlaggedModsCount -gt 0) { "[!] $($other.FlaggedModsCount) CHEAT MODS | $($other.TotalModsCount) mods" } else { "Clean ($($other.TotalModsCount) mods)" }
                Add-CleanRow "[$($other.Launcher)]" "$($other.Profile) -> $stDesc" $stColor
            }
        }

        # Global Cheat & Suspicious Artifacts (Prefetch, BAM, and flagged files)
        Add-CleanSectionHeader "SYSTEM CHEAT & SUSPICIOUS ARTIFACTS"
        if ($script:cachedActualCheats.Count -gt 0) {
            $shownFiles = @()
            foreach ($c in $script:cachedActualCheats) {
                if ($c.File -notin $shownFiles) {
                    $shownFiles += $c.File
                    Add-CleanRow "File"     $c.File "#EF4444"
                    if ($c.Path) { Add-CleanRow "Location" $c.Path "#94A3B8" }
                    if ($c.Time) { Add-CleanRow "Activity" "Executed / Modified $c.Time" "#FBBF24" }
                }
            }
        } else {
            Add-CleanRow "Status" "Clean: No cheat files or blacklisted loaders detected on this PC." "#34D399"
        }
    }

    # Synchronize Active Instance across Results, Details, and Mods Views
    $script:isSyncingInstance = $false

    function Sync-SelectedInstance([int]$idx) {
        if ($script:isSyncingInstance) { return }
        if (-not $Global:ReportData.AllInstances -or $idx -lt 0 -or $idx -ge $Global:ReportData.AllInstances.Count) { return }

        $script:isSyncingInstance = $true
        try {
            $targetInst = $Global:ReportData.AllInstances[$idx]
            $Global:ReportData.LastPlayedInstance = $targetInst
            $Global:ReportData.ActiveInstanceMods = $targetInst.Mods

            # Sync Dropdown controls
            if ($cmbResultInstance.SelectedIndex -ne $idx) { $cmbResultInstance.SelectedIndex = $idx }
            if ($cmbDetailsInstance.SelectedIndex -ne $idx) { $cmbDetailsInstance.SelectedIndex = $idx }
            if ($cmbModsInstance.SelectedIndex -ne $idx) { $cmbModsInstance.SelectedIndex = $idx }

            # Update Results Card
            $txtResultTime.Text = if ($targetInst.LastPlayedTime) { "$($targetInst.LastPlayedTime)" } else { "Historical" }
            $txtResultClient.Text = "Client   : $($targetInst.Launcher)"
            $verDisplay = if ($targetInst.Version) { " ($($targetInst.Version))" } else { "" }
            $txtResultProfile.Text = "Profile  : $($targetInst.Profile)$verDisplay"
            if ($targetInst.ConnectedServers -and $targetInst.ConnectedServers.Count -gt 0) {
                $txtResultServer.Text = "Server   : $($targetInst.ConnectedServers -join ', ')"
            } else {
                $txtResultServer.Text = "Server   : Singleplayer / Unrecorded"
            }

            # Update Mods Button & View
            $btnMods.Content = "ALL MODS ($($targetInst.TotalModsCount))"
            $txtModsTitle.Text = "INSTALLED MODS ($($targetInst.TotalModsCount))"
            $txtModsSubtitle.Text = "[$($targetInst.Launcher)] $($targetInst.Profile)"
            $txtModsSummaryStats.Text = "$($targetInst.TotalModsCount) mods in $($targetInst.Profile)"
            if ($targetInst.FlaggedModsCount -gt 0) {
                $txtModsFlaggedCount.Text = "[!] $($targetInst.FlaggedModsCount) Flagged Suspicious"
                $txtModsFlaggedCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
            } else {
                $txtModsFlaggedCount.Text = "[OK] All Mods Clean"
                $txtModsFlaggedCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            }
            Render-ModsList -Filter $txtModSearch.Text.Trim()

            # Update Details Panel
            Render-DetailsForInstance -inst $targetInst
        } finally {
            $script:isSyncingInstance = $false
        }
    }

    # Hook ComboBox selection events
    $cmbResultInstance.Add_SelectionChanged({ Sync-SelectedInstance $cmbResultInstance.SelectedIndex })
    $cmbDetailsInstance.Add_SelectionChanged({ Sync-SelectedInstance $cmbDetailsInstance.SelectedIndex })
    $cmbModsInstance.Add_SelectionChanged({ Sync-SelectedInstance $cmbModsInstance.SelectedIndex })

    # Deep Scan Runner
    $btnScan.Add_Click({
        $homeView.Visibility = [System.Windows.Visibility]::Collapsed
        $progressView.Visibility = [System.Windows.Visibility]::Visible
        $detailsContentPanel.Children.Clear()
        $modsListPanel.Children.Clear()

        try {
            # Reset state
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $Global:ReportData.CheatClients = @()
        $Global:ReportData.LegitClients = @()
        $Global:ReportData.ActiveInstanceMods = @()
        $Global:ReportData.AllInstances = @()

        # Step 1: Memory & Active Process Inspection (0% to 15%)
        for ($pct = 1; $pct -le 15; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Scanning active memory & running processes... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 35
        }
        try { Scan-JavaProcesses } catch { Write-Host "Process scan error: $_" }
        Pump-WpfEvents

        # Step 2: Minecraft Instances, Versions & Deep Mods Inspection (15% to 35%)
        $scanProgress.Value = 16
        $txtProgressStatus.Text = "Deep scanning all Minecraft clients & instances... - 16%"
        Pump-WpfEvents
        $instCallback = {
            param([int]$p, [string]$msg)
            $scanProgress.Value = $p
            $txtProgressStatus.Text = "$msg - $p%"
            Pump-WpfEvents
        }
        try { Scan-LastPlayedInstance -ProgressCallback $instCallback } catch { Write-Host "Instance scan error: $_" }
        $scanProgress.Value = 35
        $txtProgressStatus.Text = "Minecraft instances & mods analyzed - 35%"
        Pump-WpfEvents

        # Step 3: Windows Prefetch & BAM Execution History (35% to 60%)
        for ($pct = 36; $pct -le 60; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Scanning Windows Prefetch & BAM kernel timestamps... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 30
        }
        try { Scan-PrefetchTraces -Hours $HoursPrefetch } catch { Write-Host "Prefetch scan error: $_" }
        try { Scan-BAMRegistry -Hours $HoursBAM } catch { Write-Host "BAM scan error: $_" }
        Pump-WpfEvents

        # Step 4: UserAssist & MuiCache Application History (60% to 80%)
        for ($pct = 61; $pct -le 80; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Auditing UserAssist ROT13 & execution traces... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 30
        }
        try { Scan-UserAssist } catch { Write-Host "UserAssist scan error: $_" }
        Pump-WpfEvents

        # Step 5: File System, Temp drops & Anti-Forensics (80% to 95%)
        for ($pct = 81; $pct -le 95; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Auditing file systems, temp drops & anti-forensics... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 30
        }
        try { Scan-FileSystem -Hours $HoursFiles } catch { Write-Host "FileSystem scan error: $_" }
        try { Scan-USBStorage } catch { Write-Host "USBStorage scan error: $_" }
        Pump-WpfEvents

        # Step 6: Finalizing & Compiling Report (95% to 100%)
        for ($pct = 96; $pct -le 100; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Finalizing forensic report & scorecard... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 30
        }

        # Collect all system-level cheat detections (Prefetch, BAM, FileSystem, etc.)
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

        # Include flagged mods across ALL instances so no cheat mod is ever missed
        if ($Global:ReportData.AllInstances) {
            foreach ($inst in $Global:ReportData.AllInstances) {
                if ($inst.FlaggedMods) {
                    foreach ($fm in $inst.FlaggedMods) {
                        $actualCheats.Add([PSCustomObject]@{
                            File   = $fm.FileName
                            Path   = $fm.FullPath
                            Time   = $fm.LastWriteTime
                            Reason = "[$($inst.Launcher) / $($inst.Profile)] $($fm.Reason)"
                        })
                    }
                }
            }
        }

        $script:cachedActualCheats = $actualCheats

        # Populate Instance Selector Dropdowns
        $script:isSyncingInstance = $true
        $cmbResultInstance.Items.Clear()
        $cmbDetailsInstance.Items.Clear()
        $cmbModsInstance.Items.Clear()

        $allInst = $Global:ReportData.AllInstances
        if ($allInst -and $allInst.Count -gt 0) {
            foreach ($inst in $allInst) {
                $statusTag = if ($inst.FlaggedModsCount -gt 0) {
                    " [!] $($inst.FlaggedModsCount) CHEAT MODS"
                } elseif ($inst.TotalModsCount -gt 0) {
                    " ($($inst.TotalModsCount) mods)"
                } else {
                    " (0 mods)"
                }

                $displayText = "[$($inst.Launcher)] $($inst.Profile)$statusTag"
                $cmbResultInstance.Items.Add($displayText) | Out-Null
                $cmbDetailsInstance.Items.Add($displayText) | Out-Null
                $cmbModsInstance.Items.Add($displayText) | Out-Null
            }
            $script:isSyncingInstance = $false
            Sync-SelectedInstance 0
        } else {
            $script:isSyncingInstance = $false
            $txtResultTime.Text = "No Instance Found"
            $txtResultClient.Text = "Client   : No Minecraft installation detected"
            $txtResultProfile.Text = "Profile  : N/A"
            $txtResultServer.Text = "Server   : N/A"
            $btnMods.Content = "ALL MODS (0)"
        }

        # Main Screen Cheat Badge Status
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

        $txtSummaryStats.Text = "$($actualCheats.Count) Cheats Flagged | $($allInst.Count) Clients/Instances Discovered"
        } catch {
            Write-Host "Scan encountered an error: $_" -ForegroundColor Red
            if ($Global:Findings.Count -eq 0) {
                Write-Alert -Level "WARN" -Message "Scan encountered an exception: $($_.Exception.Message)"
            }
        } finally {
            # Show Results View
            $progressView.Visibility = [System.Windows.Visibility]::Collapsed
            $resultsView.Visibility = [System.Windows.Visibility]::Visible
            Pump-WpfEvents
        }
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
