# ⚡ Gricko SS Tool - Minecraft Forensic Scanner

A high-performance, standalone Windows forensic utility built in native PowerShell for competitive Minecraft screensharing (SS), server refereeing, and cheat investigations. Inspired by tools like **Ocean SS**, **Paladin**, and **Echo**, featuring an electric **Purple & Blue aesthetic**.

Designed for server staff to identify the **exact last instance/client played**, active memory injections, ghost clients (Vape, Drip, Raven, Slinky, etc.), stealth javaagents, autoclickers, and anti-forensic evasion tactics without requiring any third-party software or binary downloads.

---

## 🔮 Theme & Visual Experience

* **Sleek Purple & Blue Palette**: Designed with stylized dark purple/magenta borders and vibrant cyan/electric blue accents.
* **Structured Alert Indicators**:
  * `[OK]` (Green): Verified clean forensic check.
  * `[INFO]` (Cyan): Informational system metrics and process identifiers.
  * `[WARN]` (Yellow): Anomaly or non-standard configuration (temp drop, mod update, unverified agent).
  * `[FLAG]` (Red): **High-confidence evidence of cheat client, injector, or anti-forensic tampering.**

---

## 🔍 Forensic Modules & Capabilities

### 1. 🎯 Last Played Instance & Log Forensics (Ocean SS Feature)
* **Launcher Detection**: Scans and parses instance profiles across all major Minecraft launchers:
  * Standard Minecraft (`.minecraft` - Vanilla, Forge, Fabric, OptiFine via `launcher_profiles.json`)
  * **Lunar Client** (`.lunarclient` offline multiver profiles & logs)
  * **Badlion Client** (`Badlion Client` / `.minecraft\badlion`)
  * **Feather Client** (`.feather`)
  * **Prism Launcher / MultiMC** (`PrismLauncher\instances` & `MultiMC\instances`)
  * **Modrinth App / Theseus** (`com.modrinth.theseus\profiles`)
* **Active Target Extraction**: Identifies the last launched profile, Minecraft version, launcher brand, and session launch timestamp.
* **Deep `latest.log` Audit**:
  * Inspects the last 300 lines of the target instance's session log.
  * Extracts IP addresses and hostnames of multiplayer servers connected during gameplay (e.g. Hypixel, Minemen Club).
  * Audits log lines for cheat initialization strings, classloader anomalies, and reach/killaura/velocity hooks.
  * Detects if the log was wiped or truncated to 0 bytes before screensharing.

### 2. 🧠 Active Process & Memory Analysis (`javaw.exe` / `java.exe`)
* **WMI/CIM Process Query**: Extracts complete JVM launch arguments, main class paths, and PID.
* **Stealth Agent Detection**: Scans for `-javaagent:` parameters (the primary vector for ghost client injection such as Vape, Drip, or Raven).
* **Untrusted Directory Execution**: Flags javaagents loaded from `%TEMP%`, `AppData\Local\Temp`, or `Downloads` (while recognizing official launcher agents like Modrinth Theseus).
* **Abnormal JVM Flags**: Identifies dangerous bypass flags such as `-noverify` (disabling JVM bytecode verification) and `-Xbootclasspath` overrides.

### 3. ⏱️ Execution Traces: Prefetch (`C:\Windows\Prefetch`)
* **Execution History**: Scans `.pf` execution artifacts modified within the last 48 hours.
* **Cheat & Autoclicker Detection**: Detects standalone autoclickers (OP-AutoClicker, GS-AutoClicker, Murgee, FastClick), ghost client launchers, and memory injectors.
* **Anti-Forensic Tools**: Detects execution of low-level cleaners (BleachBit, CCleaner, SDelete, JournalCleaner, or `fsutil` wiping).

### 4. 🛡️ Execution Traces: BAM / DAM Registry
* **Kernel-Level Timestamping**: Queries Background Activity Moderator (`BAM`) and Desktop Activity Moderator (`DAM`) keys across all user SIDs (`HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings\*`).
* **64-bit FILETIME Decoding**: Extracts kernel timestamps of executable runs that cannot be forged by altering NTFS file modification dates.
* **Temp & Downloads Detection**: Flags executables or JARs executed directly from temporary directories within the last 72 hours.

### 5. 🔤 Execution Traces: UserAssist (ROT13)
* **Decoded GUI Traces**: Decodes ROT13-encoded registry entries from `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist`.
* **Launch Counts & Dates**: Extracts run counts and exact last-execution timestamps for `.exe`, `.jar`, and `.lnk` files.

### 6. 📁 File System & Anti-Forensics Inspection
* **Mods Directory Audit**: Inspects `.minecraft\mods` for files modified within 24 hours and checks for abnormal extensions (`.dll`, `.exe`, `.bat`).
* **Temp & Downloads Scans**: Detects recently dropped cheat payloads or unpacked DLLs in `%TEMP%` and `Downloads`.
* **Event Log Clears**: Detects Event ID `1102` (Security audit log cleared) and Event ID `104` (System log cleared) within 72 hours.
* **USN Journal Integrity**: Queries `fsutil usn queryjournal C:` to detect deleted/purged NTFS change journals.
* **Recycle Bin Check**: Scans Recycle Bin for deleted `.jar` or `.exe` files.

### 7. 🔌 Hardware & USB Traces
* **USB Storage History**: Enumerates `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR` for flash drives connected to the PC.
* **Active USB Drives**: Detects currently mounted removable storage drives.

---

## 📋 Requirements & Permissions

* **Operating System**: Windows 10 (Build 1809+) or Windows 11 (64-bit / 32-bit).
* **PowerShell**: Native PowerShell 5.1 (Windows PowerShell) or PowerShell 7+ (`pwsh`).
* **Dependencies**: **Zero external dependencies** (No Python, No Node, No external .exe/.dll).
* **Privileges**: Administrator privileges are required to inspect `C:\Windows\Prefetch`, BAM registry keys, and Windows Event Logs.
  * *Automatic Self-Elevation*: The script automatically prompts for UAC elevation if launched as standard user.

---

## 🚀 How to Run

### Option 1: Local Execution (Recommended for Screenshares)

1. Open **PowerShell** as **Administrator**.
2. Navigate to the tool folder:
   ```powershell
   cd ss-tool
   ```
3. Run Gricko SS Tool:
   ```powershell
   .\scanner.ps1
   ```

#### Optional Flags:
* **Export timestamped JSON report**:
  ```powershell
  .\scanner.ps1 -ExportJson
  ```
* **Specify custom report destination**:
  ```powershell
  .\scanner.ps1 -ExportJson -OutputPath "C:\Evidence\player_audit.json"
  ```
* **Run in unprivileged mode without elevation**:
  ```powershell
  .\scanner.ps1 -NoElevation
  ```
* **Disable color formatting for plain text logs**:
  ```powershell
  .\scanner.ps1 -NoColor
  ```

---

## 🌐 GitHub Distribution & Quick-Run

Host `scanner.ps1` in your GitHub repository for instant, zero-download invocation during screenshares.

### Exact GitHub Raw One-Liner:

```powershell
irm https://raw.githubusercontent.com/<USERNAME>/<REPO>/main/ss-tool/scanner.ps1 | iex
```

### From Windows Run (`Win + R`) or CMD:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/<USERNAME>/<REPO>/main/ss-tool/scanner.ps1 | iex"
```

> **Staff Tip**: Running the one-liner in an elevated PowerShell terminal provides instant full-system visibility into both the active Minecraft instance and all historical forensic traces.
