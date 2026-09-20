<#
    Gricko SS Tool - Core Configuration & Signature Definitions
#>

$Global:ToolName = "Gricko SS Tool"
$Global:ToolVersion = "2.1.0"
$Global:ScanStartTime = Get-Date
$Global:Findings = [System.Collections.Generic.List[PSCustomObject]]::new()

$Global:ReportData = [ordered]@{
    Metadata = [ordered]@{
        ToolName        = $Global:ToolName
        Version         = $Global:ToolVersion
        Theme           = "Purple-Blue Aesthetic (Ocean Inspired)"
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
    JavaProcesses = @()
    PrefetchTraces = @()
    BAMTraces = @()
    UserAssistTraces = @()
    ModFiles = @()
    TempFiles = @()
    DownloadFiles = @()
    AntiForensics = @()
    USBDevices = @()
}

# Known Minecraft cheat clients, autoclickers, injection utilities, and cleansers
$Global:SuspiciousSignatures = @(
    # Ghost & Blatant Clients
    "vape", "raven", "bplus", "drip", "slinky", "koid", "itami", "mango", "breeze", 
    "dream", "haru", "dope", "entropy", "whiteout", "phantom", "novoline", "rise", 
    "tenacity", "augustus", "moon", "badpack", "liquidbounce", "aristois", "wurst", 
    "meteor", "inertial", "sigma", "flux", "pandora", "fdp", "zeroday", "impact", 
    "bleachhack", "ares", "sigma5", "futureclient", "rusherhack", "kamiblue", "lambda",
    "lambda-client", "exhibition", "astolfo", "cleanerclient", "skidclient",

    # Autoclickers & Macros
    "autoclicker", "auto-clicker", "fastclick", "speedclick", "op-autoclicker", 
    "gs-autoclicker", "maxclicker", "murgee", "forgeclicker", "ghostclicker", 
    "jitterclicker", "butterflyclicker", "tinytask", "speedautoclicker", "clicker",
    "macrokey", "rebind", "x-mouse", "xmouse", "autoclick",

    # Injection & Memory Inspection
    "processhacker", "cheatengine", "x64dbg", "x32dbg", "dnspy", "ilspy", 
    "bytecodeviewer", "recaf", "javadecompiler", "injector", "dllinject", 
    "extremeinjector", "nativeinjector", "systeminformer", "scylla", "ghidra",

    # Anti-Forensics & Cleaners
    "bleachbit", "ccleaner", "usndelete", "journalcleaner", "privazer", 
    "eraser", "sdelete", "cleanmem", "ddelete", "redact", "stringcleaner",
    "eventlogcleaner", "wevtutil"
)
