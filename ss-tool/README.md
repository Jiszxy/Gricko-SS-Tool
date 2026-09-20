# Gricko SS Tool

A modular forensic utility written in native PowerShell for Minecraft screensharing (SS) and cheat detection. Inspired by tools like **Ocean SS** with a custom **Purple & Blue** theme.

Designed to detect active injections, ghost clients (Vape, Drip, Raven, Slinky, etc.), stealth javaagents, autoclickers, and anti-forensic evasion tactics without third-party dependencies.

---

## Capabilities

### 1. Last Played Instance & Log Forensics
* Auto-detects instance profiles across all major launchers:
  * Standard Minecraft (`.minecraft` - Vanilla, Forge, Fabric, OptiFine via `launcher_profiles.json`)
  * **Lunar Client** (`.lunarclient` offline multiver profiles & logs)
  * **Badlion Client** (`Badlion Client` / `.minecraft\badlion`)
  * **Feather Client** (`.feather`)
  * **Prism Launcher / MultiMC** (`PrismLauncher\instances` & `MultiMC\instances`)
  * **Modrinth App / Theseus** (`com.modrinth.theseus\profiles`)
* Identifies target launcher brand, profile name, Minecraft version, and session timestamp.
* Deep log scan on `latest.log`:
  * Identifies multiplayer servers connected during gameplay (e.g. Hypixel, Minemen Club).
  * Scans for cheat initialization strings and reach/killaura/velocity hooks.
  * Detects if the log was wiped or truncated to 0 bytes before screenshare.

### 2. Process & Memory Analysis
* Extracts JVM arguments, main class paths, and PID via WMI/CIM.
* Scans for injected `-javaagent:` parameters.
* Flags javaagents loaded from `%TEMP%`, `AppData\Local\Temp`, or `Downloads`.
* Flags bypass parameters such as `-noverify` and `-Xbootclasspath` overrides.

### 3. Execution Traces
* **Prefetch**: Scans `.pf` execution artifacts modified within 48 hours for autoclickers, ghost clients, and cleaner tools.
* **BAM / DAM Registry**: Parses kernel-level 64-bit `FILETIME` timestamps across all user accounts. Cannot be faked by altering file dates on disk.
* **UserAssist**: Decodes ROT13 registry entries to recover execution counts and timestamps.

### 4. File System & Anti-Forensics
* Audits `.minecraft\mods` for recent modifications and abnormal extensions (`.dll`, `.exe`, `.bat`).
* Detects recent drops in `%TEMP%` and `Downloads`.
* Checks Windows Event Log for Event ID `1102` (Security audit cleared) and Event ID `104` (System log cleared) within 72 hours.
* Queries `fsutil usn queryjournal C:` to detect deleted/purged NTFS change journals.
* Inspects Recycle Bin for deleted `.jar` or `.exe` files.

### 5. Hardware & USB Storage
* Enumerates `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR` for flash drives connected to the PC.
* Detects currently mounted removable storage drives.

---

## Requirements

* Windows 10 (Build 1809+) or Windows 11.
* PowerShell 5.1 or PowerShell 7+.
* Administrator privileges (the tool auto-elevates if launched unprivileged).
* Zero external dependencies.

---

## Quick Start (Screenshare One-Liner)

Run directly in PowerShell (as Administrator for full kernel artifact visibility):

```powershell
irm https://raw.githubusercontent.com/Jiszxy/Gricko-SS-Tool/main/dist/gricko-standalone.ps1 | iex
```

This immediately launches the **Ocean-Inspired Desktop GUI Application** featuring:
* Target Minecraft Instance card with live launcher, profile, version & server detection.
* System & integrity status panel (admin elevation badge, hostname, user).
* Prominent **START SCAN** button with animated gradient progress bar.
* Live forensic activity console streaming real-time findings with color-coded badges (`[FLAG]`, `[WARN]`, `[OK]`).
* Instant Scorecard breakdown with one-click JSON export.

Or launch from Windows Run (`Win + R`) or Command Prompt:
```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Jiszxy/Gricko-SS-Tool/main/dist/gricko-standalone.ps1 | iex"
```

---

## Local Development

```powershell
git clone https://github.com/Jiszxy/Gricko-SS-Tool.git
cd Gricko-SS-Tool
.\scanner.ps1
```

To recompile the standalone distribution after modifying `src/`:
```powershell
.\build.ps1
```

### Parameters
* `-Cli`: Runs directly in command-line / terminal mode without launching the GUI window.
* `-ExportJson`: Automatically export scan report to a timestamped JSON file.
* `-OutputPath <path>`: Custom file path for the JSON export.
* `-NoElevation`: Run without prompting for UAC elevation.
* `-NoColor`: Plain-text terminal output.
* `-HoursPrefetch <int>`: Prefetch lookback window (default: 48).
* `-HoursBAM <int>`: BAM registry lookback window (default: 72).
* `-HoursFiles <int>`: File modification lookback window (default: 24).

