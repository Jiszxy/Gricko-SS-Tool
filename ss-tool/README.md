# Gricko SS Tool

A fast Minecraft screenshare (SS) tool made in PowerShell with a custom dark GUI.

Detects ghost clients, loaders, injected javaagents, autoclickers, and deleted/modified files without needing external dependencies or downloads.

## How to run

Open PowerShell as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/Jiszxy/Gricko-SS-Tool/main/dist/gricko-standalone.ps1 | iex
```

Or run via Win + R:
```bat
powershell -ep bypass -c "irm https://raw.githubusercontent.com/Jiszxy/Gricko-SS-Tool/main/dist/gricko-standalone.ps1 | iex"
```

## Features

- **Launcher & Instance Check**: Finds what client you're on, checks `.minecraft`, Lunar, Badlion, Feather, Modrinth, Prism, MultiMC, etc.
- **Mod & Bytecode Scan**: Scans mod folders and checks jar contents for cheats, suspicious mixins, and known cheat packages (Anchor Optimizer, Crystal Optimizer, FreeLook, etc.).
- **Process & Injections**: Scans active JVM arguments for injected `-javaagent`, temp paths, or bypass flags (`-noverify`).
- **Prefetch & BAM**: Reads Windows Prefetch and BAM registry records for recently run cheats, clickers, or cleaners even if they were renamed or moved.
- **UserAssist**: Decodes ROT13 execution history to find programs run on the PC.
- **File System & Anti-Forensics**: Checks `%TEMP%`, recent Downloads, cleared event logs, and USN journal state.
- **USB History**: Checks plugged in USB drives to see if tools were run off a flash drive.
- **GUI & Scorecard**: Clean dark UI that lists discovered instances, shows flagged mods with reasons, and lets you export findings to JSON.

## Local / CLI Usage

If you cloned the repo:
```powershell
.\scanner.ps1
```

To run in terminal mode without the GUI:
```powershell
.\scanner.ps1 -Cli
```

Parameters:
- `-Cli`: Skip GUI and print results to console
- `-ExportJson`: Export scan results to JSON file
- `-HoursPrefetch <int>`: Prefetch lookback hours (default: 48)
- `-HoursBAM <int>`: BAM lookback hours (default: 72)
- `-HoursFiles <int>`: File modification lookback hours (default: 24)

## Building

To rebuild the single-file standalone script after editing `src/`:
```powershell
.\build.ps1
```
