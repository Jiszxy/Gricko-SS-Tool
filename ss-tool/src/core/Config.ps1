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
    ModFiles           = @()
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

    # Disallowed Combat Optimizers & Unfair PvP Modifications
    "crystal.*optimizer", "crystaloptimizer", "marlow.*crystal",
    "anchor.*optimizer", "anchoroptimizer", "herosanchor",
    "autoclicker", "auto-clicker", "triggerbot", "reach", "hitbox",
    "aimassist", "fastplace", "autototem", "autoanchor", "autopot",
    "freecam", "freelook", "xray", "x-ray", "baritone", "seedcracker"
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
