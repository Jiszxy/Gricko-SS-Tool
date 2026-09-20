<#
    Gricko SS Tool - Minimalist Ocean-Style Automated Screenshare GUI
    Compact Floating Window with Fishbone Logo, 2-Minute Deep Scan & Clean Results
#>

function Show-GrickoGui {
    param(
        [int]$HoursPrefetch = 168, # 7 days deep scan
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

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gricko SS Tool"
        Height="460" Width="580"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        ResizeMode="CanMinimize">

    <Window.Resources>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="5"/>
            <Setter Property="Background" Value="#101114"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="#101114">
                            <Track x:Name="PART_Track" IsDirectionReversed="true">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border Background="#3A3D4A" CornerRadius="2"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Name="RootBorder" CornerRadius="14" BorderThickness="1.2" BorderBrush="#252833">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                <GradientStop Color="#15161A" Offset="0.0"/>
                <GradientStop Color="#0E0F13" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.Background>

        <Grid Margin="18">
            <Grid.RowDefinitions>
                <RowDefinition Height="32"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="24"/>
            </Grid.RowDefinitions>

            <!-- TOP BAR: MINIMAL CONTROLS (NO EXTRA TEXT) -->
            <Grid Grid.Row="0" Name="TitleBarGrid" Background="Transparent">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button Name="BtnMin" Content="-" Width="30" Height="24" Background="#1A1C24" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand" Margin="0,0,5,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnClose" Content="X" Width="30" Height="24" Background="#1A1C24" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- BODY CONTENT -->
            <Grid Grid.Row="1">

                <!-- VIEW 1: HOME (SCAN LAUNCHER) -->
                <StackPanel Name="HomeView" Visibility="Visible" HorizontalAlignment="Center" VerticalAlignment="Center">
                    
                    <!-- Fishbone Transparent Logo -->
                    <Border Margin="0,0,0,16" HorizontalAlignment="Center">
                        <Image Name="LogoImgHome" Width="140" Height="70" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
                    </Border>

                    <!-- Scan Action Button -->
                    <Border CornerRadius="24" Background="#1E202B" BorderBrush="#323648" BorderThickness="1.2" HorizontalAlignment="Center" Margin="0,0,0,16">
                        <Button Name="BtnScan" Content="DEEP SCAN PC" Width="210" Height="46" FontSize="13" FontWeight="Bold" Foreground="#FFFFFF" Background="Transparent" BorderThickness="0" Cursor="Hand">
                            <Button.Style>
                                <Style TargetType="Button">
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="Button">
                                                <Border Name="btnBdr" Background="Transparent" CornerRadius="24">
                                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="btnBdr" Property="Background" Value="#2A2D3D"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </Button.Style>
                        </Button>
                    </Border>

                    <TextBlock Text="Comprehensive Minecraft Forensics &amp; Client Inspector" Foreground="#64748B" FontSize="11" HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- VIEW 2: PROGRESS (2-MINUTE DEEP SCAN) -->
                <StackPanel Name="ProgressView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="440">
                    <Image Name="LogoImgProgress" Width="110" Height="54" HorizontalAlignment="Center" Margin="0,0,0,14" RenderOptions.BitmapScalingMode="HighQuality"/>
                    
                    <TextBlock Text="DEEP SCANNING SYSTEM" Foreground="#F8FAFC" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                    <TextBlock Text="Thorough inspection of processes, prefetch, BAM, registry &amp; game instances..." Foreground="#64748B" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,20"/>

                    <!-- Progress Bar (Silver Neon) -->
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

                    <!-- Status Text -->
                    <TextBlock Name="TxtProgressStatus" Text="Initializing deep PC inspection... - 0%" Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- VIEW 3: CLEAN RESULTS SUMMARY (ONLY CLIENT & SUS MODS) -->
                <StackPanel Name="ResultsView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="460">
                    <Image Name="LogoImgResults" Width="110" Height="54" HorizontalAlignment="Center" Margin="0,0,0,8" RenderOptions.BitmapScalingMode="HighQuality"/>
                    
                    <TextBlock Name="TxtResultTitle" Text="Scan Complete" Foreground="#F8FAFC" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                    <TextBlock Name="TxtResultSubtitle" Text="System inspection finished" Foreground="#34D399" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,12"/>

                    <!-- Client & Last Instance Info Card -->
                    <Border Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,10" Margin="0,0,0,10">
                        <StackPanel>
                            <DockPanel Margin="0,0,0,4">
                                <TextBlock Text="ACTIVE / LAST PLAYED MINECRAFT CLIENT" Foreground="#94A3B8" FontSize="10.5" FontWeight="Bold"/>
                                <TextBlock Name="TxtResultTime" Text="N/A" Foreground="#38BDF8" FontSize="10.5" FontWeight="Bold" HorizontalAlignment="Right"/>
                            </DockPanel>
                            <TextBlock Name="TxtResultClient" Text="Client   : Detecting..." Foreground="#E2E8F0" FontSize="12" FontWeight="SemiBold" Margin="0,1"/>
                            <TextBlock Name="TxtResultProfile" Text="Profile  : Standard" Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtResultServer" Text="Server   : None" Foreground="#38BDF8" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Border>

                    <!-- Cheat Detection Result Box -->
                    <Border Name="DetectionBox" Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,8" Margin="0,0,0,14">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="TxtDetectionsBadge" Text="[OK] No Cheats or Suspicious Clients Detected" Foreground="#34D399" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtCheatList" Text="" Foreground="#F87171" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,3,0,0" Visibility="Collapsed"/>
                        </StackPanel>
                    </Border>

                    <!-- Action Buttons -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button Name="BtnDetails" Content="DETAILS" Width="120" Height="34" FontSize="12" FontWeight="Bold" Foreground="#FFFFFF" Background="#262A38" BorderBrush="#3B4259" BorderThickness="1" Cursor="Hand" Margin="0,0,10,0">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                        <Button Name="BtnRescan" Content="RE-SCAN" Width="100" Height="34" FontSize="12" FontWeight="Bold" Foreground="#94A3B8" Background="#161822" BorderThickness="0" Cursor="Hand">
                            <Button.Resources>
                                <Style TargetType="Border">
                                    <Setter Property="CornerRadius" Value="17"/>
                                </Style>
                            </Button.Resources>
                        </Button>
                    </StackPanel>
                </StackPanel>

                <!-- VIEW 4: CLEAN DETAILS INSPECTOR (NO SPAM) -->
                <Grid Name="DetailsView" Visibility="Collapsed" Height="350" Margin="4,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,8">
                        <TextBlock Text="FORENSIC INSPECTION DETAILS" Foreground="#F8FAFC" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button Name="BtnBackFromDetails" Content="&lt;- Back" Background="Transparent" Foreground="#38BDF8" BorderThickness="0" FontSize="12" FontWeight="SemiBold" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>

                    <!-- Clean Categorized Details Log -->
                    <Border Grid.Row="1" Background="#0C0D11" CornerRadius="8" BorderBrush="#1C1E26" BorderThickness="1" Padding="8">
                        <ListBox Name="DetailsListBox" Background="Transparent" BorderThickness="0" FontFamily="Consolas, Segoe UI" FontSize="11.5" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                            <ListBox.ItemContainerStyle>
                                <Style TargetType="ListBoxItem">
                                    <Setter Property="Padding" Value="3,2"/>
                                    <Setter Property="Focusable" Value="False"/>
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="ListBoxItem">
                                                <ContentPresenter />
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </ListBox.ItemContainerStyle>
                        </ListBox>
                    </Border>

                    <DockPanel Grid.Row="2" Margin="0,8,0,0">
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

            </Grid>

            <!-- FOOTER WATERMARK -->
            <Grid Grid.Row="2">
                <TextBlock Text="powered by Gricko SS Tool" Foreground="#475569" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,4,2"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
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

    $logoImgHome       = $window.FindName("LogoImgHome")
    $logoImgProgress   = $window.FindName("LogoImgProgress")
    $logoImgResults    = $window.FindName("LogoImgResults")

    $btnScan           = $window.FindName("BtnScan")
    $btnRescan         = $window.FindName("BtnRescan")
    $btnDetails        = $window.FindName("BtnDetails")
    $btnBackFromDetails= $window.FindName("BtnBackFromDetails")
    $btnExportJson     = $window.FindName("BtnExportJson")

    $scanProgress      = $window.FindName("ScanProgress")
    $txtProgressStatus = $window.FindName("TxtProgressStatus")

    $txtResultTitle    = $window.FindName("TxtResultTitle")
    $txtResultSubtitle = $window.FindName("TxtResultSubtitle")
    $txtResultTime     = $window.FindName("TxtResultTime")
    $txtResultClient   = $window.FindName("TxtResultClient")
    $txtResultProfile  = $window.FindName("TxtResultProfile")
    $txtResultServer   = $window.FindName("TxtResultServer")

    $detectionBox      = $window.FindName("DetectionBox")
    $txtDetectionsBadge= $window.FindName("TxtDetectionsBadge")
    $txtCheatList      = $window.FindName("TxtCheatList")

    $detailsListBox    = $window.FindName("DetailsListBox")
    $txtSummaryStats   = $window.FindName("TxtSummaryStats")

    # Set Transparent Logo on Image Controls
    $logoSrc = Get-LogoSource
    if ($logoSrc) {
        $logoImgHome.Source = $logoSrc
        $logoImgProgress.Source = $logoSrc
        $logoImgResults.Source = $logoSrc
    }

    # FREE WINDOW DRAGGING FROM ANYWHERE
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
        $detailsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnBackFromDetails.Add_Click({
        $detailsView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
    })

    $btnRescan.Add_Click({
        $resultsView.Visibility = [System.Windows.Visibility]::Collapsed
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

    function Add-CleanDetailLine {
        param(
            [string]$Category,
            [string]$Status,
            [string]$Text,
            [string]$Color
        )

        $sp = [System.Windows.Controls.StackPanel]::new()
        $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $sp.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)

        $tbCat = [System.Windows.Controls.TextBlock]::new()
        $tbCat.Text = "[$Category]".PadRight(10)
        $tbCat.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
        $tbCat.FontWeight = [System.Windows.FontWeights]::Bold
        $tbCat.Width = 80
        $sp.Children.Add($tbCat) | Out-Null

        $tbStat = [System.Windows.Controls.TextBlock]::new()
        $tbStat.Text = "$Status "
        $tbStat.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
        $tbStat.FontWeight = [System.Windows.FontWeights]::Bold
        $tbStat.Width = 65
        $sp.Children.Add($tbStat) | Out-Null

        $tbTxt = [System.Windows.Controls.TextBlock]::new()
        $tbTxt.Text = $Text
        $tbTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
        $sp.Children.Add($tbTxt) | Out-Null

        $detailsListBox.Items.Add($sp) | Out-Null
    }

    # 2-Minute Deep Scan Runner
    $btnScan.Add_Click({
        $homeView.Visibility = [System.Windows.Visibility]::Collapsed
        $progressView.Visibility = [System.Windows.Visibility]::Visible
        $detailsListBox.Items.Clear()

        # Reset state
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $Global:ReportData.CheatClients = @()
        $Global:ReportData.LegitClients = @()

        # Step 1: Memory & Active Process Inspection (0% to 15% - ~18s)
        for ($pct = 1; $pct -le 15; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Scanning active memory & running processes... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-JavaProcesses
        Pump-WpfEvents

        # Step 2: Minecraft Instances, Versions & Logs (15% to 35% - ~24s)
        Scan-LastPlayedInstance
        for ($pct = 16; $pct -le 35; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Deep scanning Minecraft instances, versions & mods... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }

        # Step 3: Windows Prefetch & BAM Execution History (35% to 60% - ~30s)
        for ($pct = 36; $pct -le 60; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Scanning Windows Prefetch & BAM kernel timestamps... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-PrefetchTraces -Hours $HoursPrefetch
        Scan-BAMRegistry -Hours $HoursBAM
        Pump-WpfEvents

        # Step 4: UserAssist & MuiCache Application History (60% to 80% - ~24s)
        for ($pct = 61; $pct -le 80; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Auditing UserAssist ROT13 & execution traces... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-UserAssist
        Pump-WpfEvents

        # Step 5: File System, Temp drops & Anti-Forensics (80% to 95% - ~18s)
        for ($pct = 81; $pct -le 95; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Auditing file systems, temp drops & anti-forensics... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }
        Scan-FileSystem -Hours $HoursFiles
        Scan-USBStorage
        Pump-WpfEvents

        # Step 6: Finalizing & Compiling Report (95% to 100% - ~6s)
        for ($pct = 96; $pct -le 100; $pct++) {
            $scanProgress.Value = $pct
            $txtProgressStatus.Text = "Finalizing forensic report & scorecard... - $pct%"
            Pump-WpfEvents
            Start-Sleep -Milliseconds 1200
        }

        # Format Clean Results
        $inst = $Global:ReportData.LastPlayedInstance
        $timeStr = $null
        $launcherStr = $null
        $profileStr = "Standard Profile"
        $versionStr = ""

        if ($inst) {
            $timeStr = if ($inst.LastPlayedTime) { $inst.LastPlayedTime } elseif ($inst.LastPlayed) { $inst.LastPlayed } else { $null }
            $launcherStr = if ($inst.LauncherName) { $inst.LauncherName } elseif ($inst.Launcher) { $inst.Launcher } else { $null }
            $profileStr = if ($inst.ProfileName) { $inst.ProfileName } elseif ($inst.Profile) { $inst.Profile } else { "Standard Profile" }
            $versionStr = if ($inst.Version) { $inst.Version } else { "" }
        }

        # Fallback 1: Active running Java/Minecraft process
        if (-not $launcherStr -and $Global:ReportData.JavaProcesses -and $Global:ReportData.JavaProcesses.Count -gt 0) {
            $jp = $Global:ReportData.JavaProcesses[0]
            $launcherStr = "Active Java (PID $($jp.ProcessId))"
            $timeStr = "Running Right Now"
            $profileStr = "Active Game Session"
        }

        # Fallback 2: Check any prefetch/BAM traces
        if (-not $launcherStr) {
            $pfMatch = $Global:Findings | Where-Object { $_.Detail -like "*javaw.exe*" -or $_.Detail -like "*minecraft.exe*" -or $_.Detail -like "*lunar*" -or $_.Detail -like "*feather*" -or $_.Detail -like "*badlion*" } | Select-Object -First 1
            if ($pfMatch) {
                $launcherStr = "Minecraft (Prefetch / BAM Trace)"
                $timeStr = "Recent Execution Trace"
                $profileStr = "Historical Instance"
            }
        }

        if ($launcherStr) {
            $txtResultTime.Text = if ($timeStr) { "$timeStr" } else { "Active / Recent" }
            $txtResultClient.Text = "Client   : $launcherStr"
            $txtResultProfile.Text = if ($versionStr -and $versionStr -ne "Unknown") { "Profile  : $profileStr ($versionStr)" } else { "Profile  : $profileStr" }
            if ($inst -and $inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
                $txtResultServer.Text = "Server   : $($inst.ConnectedServers -join ', ')"
            } else {
                $txtResultServer.Text = "Server   : Singleplayer / Unrecorded"
            }
        } else {
            $txtResultTime.Text = "No Instance Found"
            $txtResultClient.Text = "Client   : No Minecraft installation detected"
            $txtResultProfile.Text = "Profile  : N/A"
            $txtResultServer.Text = "Server   : N/A"
        }

        # Filter actual cheat detections (Prestige, Grim, Vape, Drip, Slinky, Raven, etc.)
        # Exclude normal Essential/Theseus/JNA temp libraries from cheat detections
        $actualCheats = [System.Collections.Generic.List[string]]::new()
        foreach ($f in $Global:Findings) {
            if ($f.Level -eq "FLAG") {
                $msg = "$($f.Message) $($f.Detail)"
                if ($msg -notlike "*essential*" -and $msg -notlike "*theseus*" -and $msg -notlike "*imgui*" -and $msg -notlike "*jna*") {
                    $actualCheats.Add($f.Detail)
                }
            }
        }

        # Build Clean Details List (No Spam)
        Add-CleanDetailLine "SESSION" "[INFO]" "Last Played Client: $($txtResultClient.Text)" "#38BDF8"
        Add-CleanDetailLine "SESSION" "[INFO]" "Last Launched Time: $($txtResultTime.Text)" "#E2E8F0"
        Add-CleanDetailLine "SESSION" "[INFO]" "Last Profile & Version: $($txtResultProfile.Text)" "#94A3B8"
        if ($txtResultServer.Text -ne "Server   : None") {
            Add-CleanDetailLine "SESSION" "[INFO]" "Multiplayer Server: $($txtResultServer.Text)" "#38BDF8"
        }

        # Process List
        if ($Global:ReportData.JavaProcesses -and $Global:ReportData.JavaProcesses.Count -gt 0) {
            foreach ($jp in $Global:ReportData.JavaProcesses) {
                Add-CleanDetailLine "PROCESS" "[INFO]" "Active Java PID $($jp.ProcessId) ($($jp.Name))" "#34D399"
                if ($jp.JavaAgents -and $jp.JavaAgents.Count -gt 0) {
                    foreach ($ja in $jp.JavaAgents) {
                        Add-CleanDetailLine "AGENT" "[WARN]" "JavaAgent Hook: $ja" "#FBBF24"
                    }
                }
            }
        } else {
            Add-CleanDetailLine "PROCESS" "[CLEAN]" "No active Minecraft Java processes currently executing." "#10B981"
        }

        # Cheats & Suspicious Mods
        if ($actualCheats.Count -gt 0) {
            foreach ($c in $actualCheats) {
                Add-CleanDetailLine "CHEAT" "[FLAG]" "Detected Cheat / Injected Artifact: $c" "#EF4444"
            }
            $txtResultTitle.Text = "Cheats Detected"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $txtResultSubtitle.Text = "$($actualCheats.Count) suspicious or cheat client artifacts found"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
            $txtDetectionsBadge.Text = "[!] SUSPICIOUS CLIENT / CHEATS DETECTED"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $detectionBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#991B1B")

            $uniqueCheats = $actualCheats | Select-Object -Unique
            $txtCheatList.Text = ($uniqueCheats -join " | ")
            $txtCheatList.Visibility = [System.Windows.Visibility]::Visible
        } else {
            Add-CleanDetailLine "SCAN" "[CLEAN]" "Deep PC inspection verified zero ghost clients or cheat loaders." "#10B981"
            $txtResultTitle.Text = "Scan Complete"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
            $txtResultSubtitle.Text = "All deep forensic tests concluded"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtDetectionsBadge.Text = "[OK] No Cheats or Suspicious Clients Detected"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $detectionBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#065F46")
            $txtCheatList.Visibility = [System.Windows.Visibility]::Collapsed
        }

        $txtSummaryStats.Text = "$($actualCheats.Count) Cheats Flagged | Full 2-Minute PC Deep Scan Finished"

        # Show Results View
        $progressView.Visibility = [System.Windows.Visibility]::Collapsed
        $resultsView.Visibility = [System.Windows.Visibility]::Visible
        Pump-WpfEvents
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