```
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

# Fabric mod IDs explicitly exempt from all mod-cheat detection.
# These mods are ignored when their fabric.mod.json contains this exact ID.
$Global:FullyTrustedModIds = @(
    "chat_heads"
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
            $onlineCmd = "irm https://raw.githubusercontent.com/Jiszxy/Gricko-SS-Tool/main/dist/gricko-standalone.ps1 | iex"
            try {
                Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$onlineCmd`"" -Verb RunAs
                exit
            } catch {
                Write-Alert -Level "WARN" -Message "UAC Elevation was declined or failed." -Detail "Continuing in unprivileged mode."
            }
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
    $heurRegex = [regex]::new('(?i)\b(killaura|aimbot|triggerbot|velocitymultiplier|antivelocity|novelocity|wallhack|xray|bhop|fly|freecam|nofall|autoeat|scaffold|phase|jesus|wurst|meteor|vape|bleachhack|future|sigma|rusherhack|liquidbounce|autoclicker|hack|cheat)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $mixinHeurRegex = [regex]::new('(?i)(killaura|aimbot|autoclicker|antivelocity|novelocity|cheat|hack|auto_crystal|anchor_macro|mace_assist|triggerbot)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

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

        # -------------------------------------------------------------
        # FULL TRUST MOD-ID EXEMPTION
        # -------------------------------------------------------------
        # Read fabric.mod.json before any filename, metadata, mixin,
        # bytecode, heuristic, or structural cheat detection.
        $fullyTrusted = $false

        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

            $trustZip = [System.IO.Compression.ZipFile]::OpenRead($mod.FullName)
            $fabricMeta = $trustZip.GetEntry("fabric.mod.json")

            if ($fabricMeta) {
                $metaStream = $fabricMeta.Open()
                $metaReader = [System.IO.StreamReader]::new($metaStream)
                $fabricJson = $metaReader.ReadToEnd()
                $metaReader.Close()
                $metaStream.Close()

                try {
                    $fabricData = $fabricJson | ConvertFrom-Json

                    if ($fabricData.id -and
                        $Global:FullyTrustedModIds -contains [string]$fabricData.id) {
                        $fullyTrusted = $true
                    }
                } catch {}
            }

            $trustZip.Dispose()
        } catch {}

        if ($fullyTrusted) {
            # Completely ignore this mod in the scanner.
            continue
        }

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
                Invariants    = if ($cached.Invariants) { $cached.Invariants } else { @() }
                Modules       = if ($cached.Modules) { $cached.Modules } else { @() }
            }
            $result.Mods.Add($cloned)
            if ($cloned.IsFlagged) { $result.FlaggedMods.Add($cloned); $result.FlaggedCount++ }
            continue
        }

        $isFlagged            = $false
        $reason               = "Clean"
        $category             = "CLEAN"
        $aiRisk               = 0
        $aiDetails            = [System.Collections.Generic.List[string]]::new()
        $structuralInvariants = [System.Collections.Generic.HashSet[string]]::new()
        $detectedModules      = [System.Collections.Generic.HashSet[string]]::new()
        $detectedMechanics    = [System.Collections.Generic.HashSet[string]]::new()
        $detectedWebGui       = [System.Collections.Generic.List[string]]::new()
        $detectedLicenses     = [System.Collections.Generic.List[string]]::new()
        $strHits              = [System.Collections.Generic.List[string]]::new()
        $displayName          = [System.IO.Path]::GetFileNameWithoutExtension($mod.Name)

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

                    # -- LAYER 5: Evasion-Proof Structural Bytecode Invariants & Deep Capability Analysis ---
                    # Inspects bytecode mathematical and runtime invariants that cannot be renamed away
                    $detectedModules      = [System.Collections.Generic.HashSet[string]]::new()
                    $detectedMechanics    = [System.Collections.Generic.HashSet[string]]::new()
                    $detectedWebGui       = [System.Collections.Generic.List[string]]::new()
                    $detectedLicenses     = [System.Collections.Generic.List[string]]::new()
                    $structuralInvariants = [System.Collections.Generic.HashSet[string]]::new()
                    $strHits              = [System.Collections.Generic.List[string]]::new()

                    foreach ($entry in $allEntries) {
                        $fn = $entry.FullName
                        if ($entry.Length -le 0 -or $fn.EndsWith("/")) { continue }

                        # Class name inspection
                        $mMatch = $cheatClassRegex.Match($fn)
                        if ($mMatch.Success -and $detectedModules.Count -lt 12) {
                            $detectedModules.Add($mMatch.Groups[2].Value) | Out-Null
                        }

                        # Check files for bytecode / assets
                        if ($fn -match '\.(class|html|js|json)$') {
                            try {
                                $ces = $entry.Open()
                                $readLen = $ces.Read($readBuf, 0, [Math]::Min($entry.Length, 65536))
                                $ces.Close()
                                $entryText = [System.Text.Encoding]::UTF8.GetString($readBuf, 0, $readLen)

                                # Invariant 1: Embedded Local Web Server & Control Hub
                                if ($entryText.Contains("HttpServer") -and ($entryText.Contains("com/sun/net/httpserver") -or $entryText.Contains("createContext") -or $entryText.Contains("org/nanohttpd"))) {
                                    $structuralInvariants.Add("Embedded Local Web Server (createContext)") | Out-Null
                                }

                                # Invariant 2: StreamProof Screen Capture Evasion
                                if ($entryText.Contains("SetWindowDisplayAffinity") -or $entryText.Contains("WDA_EXCLUDEFROMCAPTURE") -or $entryText.Contains("User32Extra")) {
                                    $structuralInvariants.Add("StreamProof Screen Capture Evasion (SetWindowDisplayAffinity)") | Out-Null
                                }

                                # Invariant 3: Trigonometric Silent-Aim / Combat Rotation Math
                                if ($entryText.Contains("atan2") -and $entryText.Contains("toDegrees") -and 
                                    ($entryText.Contains("getYaw") -or $entryText.Contains("getPitch") -or $entryText.Contains("setYaw") -or $entryText.Contains("setPitch") -or $entryText.Contains("setYRot") -or $entryText.Contains("setXRot") -or $entryText.Contains("getYRot") -or $entryText.Contains("getXRot") -or $entryText.Contains("wrapDegrees"))) {
                                    $structuralInvariants.Add("Trig Combat Aimbot Rotation Math (atan2 -> player rotation)") | Out-Null
                                }

                                # Invariant 4: Automated Shield-Breaker Weapon Swap
                                if (($entryText.Contains("shield") -or $entryText.Contains("isBlocking") -or $entryText.Contains("isUsingItem")) -and 
                                    $entryText.Contains("setSelected") -and 
                                    ($entryText.Contains("axe") -or $entryText.Contains("Axe") -or $entryText.Contains("AxeItem") -or $entryText.Contains("targetReturnSlot"))) {
                                    $structuralInvariants.Add("Auto Shield-Breaker Weapon Swap (Target isShielding -> setSelected Axe)") | Out-Null
                                }

                                # Invariant 5: Automated Anchor / Crystal Macro Mechanics
                                if ($entryText.Contains("setSelected") -and 
                                    ($entryText.Contains("glowstone") -or $entryText.Contains("respawn_anchor") -or $entryText.Contains("end_crystal") -or $entryText.Contains("obsidian")) -and 
                                    ($entryText.Contains("interactBlock") -or $entryText.Contains("useItemOn") -or $entryText.Contains("KeyBinding") -or $entryText.Contains("KeyMapping"))) {
                                    $structuralInvariants.Add("Anchor/Crystal Combat Macro Placement Loop (setSelected -> interactBlock)") | Out-Null
                                }

                                # Invariant 6: Hardware Fingerprinting / Anti-Leak DRM
                                if ($entryText.Contains("wmic csproduct get uuid") -or $entryText.Contains("MachineGuid") -or $entryText.Contains("HWIDUtil") -or ($entryText.Contains("verifyLicense") -and $entryText.Contains("LicenseManager"))) {
                                    $structuralInvariants.Add("Hardware ID (HWID) Anti-Leak DRM") | Out-Null
                                    $detectedLicenses.Add("Private Cheat License & HWID Lock") | Out-Null
                                }

                                # Invariant 7: Mace / Velocity Combat Assist
                                if (($entryText.Contains("mace") -or $entryText.Contains("Mace")) -and $entryText.Contains("setSelected") -and 
                                    ($entryText.Contains("density") -or $entryText.Contains("spear") -or $entryText.Contains("targetReturnSlot")) -and 
                                    ($entryText.Contains("KeyMapping") -or $entryText.Contains("KeyBinding") -or $entryText.Contains("clickAttack"))) {
                                    $structuralInvariants.Add("Mace/Spear Automated Weapon Assist (density / spear swap)") | Out-Null
                                }

                                # Invariant 8: Embedded Local Web Dashboard
                                if ($fn -match '\.html$' -and ($entryText.Contains("Combat & CPVP") -or $entryText.Contains("TripleT") -or $entryText.Contains("Auto Crystal") -or $entryText.Contains("Mace Assist") -or $entryText.Contains("Anchor Macro"))) {
                                    $titleMatch = if ($entryText -match '(?i)<title>(.*?)</title>') { $Matches[1].Trim() } else { "Web GUI" }
                                    if ($detectedWebGui.Count -lt 2) {
                                        $detectedWebGui.Add("$fn ('$titleMatch')") | Out-Null
                                    }
                                }

                                # Fast module extraction only if combat keywords present
                                if ($entryText.Contains("Manager") -or $entryText.Contains("Macro") -or $entryText.Contains("Assist") -or $entryText.Contains("Aura") -or $entryText.Contains("Crystal") -or $entryText.Contains("Anchor")) {
                                    $textMatches = $cheatClassRegex.Matches($entryText)
                                    foreach ($tm in $textMatches) {
                                        if ($detectedModules.Count -lt 12) { $detectedModules.Add($tm.Groups[2].Value) | Out-Null }
                                    }
                                }

                                # Fast mechanics tokens
                                if ($entryText.Contains("shieldRemove")) { $detectedMechanics.Add("Auto Shield-Break (Axe Swap)") | Out-Null }
                                if ($entryText.Contains("aimAssistEnabled")) { $detectedMechanics.Add("Combat Aim-Assist FOV Cone") | Out-Null }
                                if ($entryText.Contains("fallVelocityCheck")) { $detectedMechanics.Add("Fall Velocity Auto-Crit Timing") | Out-Null }
                                if ($entryText.Contains("KeyBinding.setDown")) { $detectedMechanics.Add("Simulated Hardware KeyPresses") | Out-Null }
                                if ($entryText.Contains("targetReturnSlot")) { $detectedMechanics.Add("Automated Hotbar / Weapon Slot Swapping") | Out-Null }

                                # Bytecode suspicious strings (only run regex if sample matches trigger)
                                if ($strHits.Count -lt 6 -and ($entryText.Contains("Hack") -or $entryText.Contains("Cheat") -or $entryText.Contains("Aimbot") -or $entryText.Contains("KillAura"))) {
                                    $matches = $suspRegex.Matches($entryText)
                                    foreach ($m in $matches) {
                                        if ($strHits.Count -lt 6 -and -not $strHits.Contains($m.Value)) {
                                            $strHits.Add($m.Value)
                                        }
                                    }
                                }
                            } catch {}
                        }
                    }

                    # Evaluate: Structural Invariants, Known Modules, or Embedded GUI
                    if ($structuralInvariants.Count -gt 0 -or $detectedModules.Count -gt 0 -or $detectedWebGui.Count -gt 0 -or ($detectedMechanics.Count -ge 2)) {
                        $isFlagged = $true
                        $aiRisk = 100
                        $invList = @($structuralInvariants)
                        $topList = if ($invList.Count -gt 0) { @($invList | Select-Object -First 2) } else { @($detectedModules | Select-Object -First 3) }
                        if ($topList.Count -eq 0) { $topList = @($detectedMechanics | Select-Object -First 2) }

                        if ($hasMeta) {
                            $category = "DISGUISED CHEAT / TROJAN MOD"
                            $reason = "Disguised Trojan Mod: violates combat invariants ($($topList -join '; '))"
                        } else {
                            $category = "FLAGGED CHEAT / DISALLOWED"
                            $reason = "Violates combat cheat invariants: $($topList -join '; ')"
                        }

                        # Construct rich AI forensic capability breakdown
                        $aiDetails.Clear()
                        if ($structuralInvariants.Count -gt 0) {
                            $aiDetails.Add("Invariants: $(($structuralInvariants | Select-Object -First 4) -join '; ')")
                        }
                        if ($detectedModules.Count -gt 0) {
                            $aiDetails.Add("Modules: $(($detectedModules | Select-Object -First 8) -join ', ')")
                        }
                        if ($detectedMechanics.Count -gt 0) {
                            $aiDetails.Add("Mechanics: $(($detectedMechanics | Select-Object -First 4) -join ', ')")
                        }
                        if ($detectedWebGui.Count -gt 0) {
                            $aiDetails.Add("Embedded GUI: $($detectedWebGui[0])")
                        }
                        if ($detectedLicenses.Count -gt 0) {
                            $aiDetails.Add("Auth: $($detectedLicenses[0])")
                        }
                    } elseif ($strHits.Count -ge 4) {
                        $aiRisk += 55; $aiDetails.Add("Bytecode: $($strHits.Count) cheat API strings - '$($strHits[0])'")
                    } elseif ($strHits.Count -ge 2) {
                        $aiRisk += 28; $aiDetails.Add("Bytecode suspicious strings: '$($strHits[0])'")
                    } elseif ($strHits.Count -ge 1) {
                        $aiRisk += 10; $aiDetails.Add("Bytecode minor suspicious string: '$($strHits[0])'")
                    }

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

                        $zip.Dispose()
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
            Invariants    = if ($structuralInvariants) { @($structuralInvariants) } else { @() }
            Modules       = if ($detectedModules) { @($detectedModules) } else { @() }
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
           ... (115 KB left)
