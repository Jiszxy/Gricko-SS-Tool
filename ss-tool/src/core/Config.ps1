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
    "bettermace", "better-mace", "maceassist", "mace-assist", "mace.assist",
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
