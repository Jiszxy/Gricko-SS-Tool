<#
    Gricko SS Tool - Ocean-Inspired Forensic Desktop UI (WPF / XAML)
    Modern Dark Purple & Blue Aesthetic with Interactive Scan Controls
#>

function Show-GrickoGui {
    param(
        [int]$HoursPrefetch = 48,
        [int]$HoursFiles = 24,
        [int]$HoursBAM = 72
    )

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gricko SS Tool - Ocean Forensic Suite"
        Height="720" Width="1000"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        ResizeMode="CanMinimize">

    <Window.Resources>
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="6"/>
            <Setter Property="Background" Value="#0F1123"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="#0A0B14">
                            <Track x:Name="PART_Track" IsDirectionReversed="true">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border Background="#3B3F63" CornerRadius="3"/>
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

    <Border CornerRadius="12" BorderThickness="1.5">
        <Border.BorderBrush>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#8B5CF6" Offset="0.0"/>
                <GradientStop Color="#3B82F6" Offset="0.5"/>
                <GradientStop Color="#06B6D4" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0.2,1">
                <GradientStop Color="#0D0E1A" Offset="0.0"/>
                <GradientStop Color="#07080F" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.Background>

        <Grid Margin="18">
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/>
                <RowDefinition Height="120"/>
                <RowDefinition Height="75"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="65"/>
            </Grid.RowDefinitions>

            <!-- TITLE BAR -->
            <Grid Grid.Row="0" Name="TitleBarGrid" Background="Transparent">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="*" Foreground="#A855F7" FontSize="18" FontWeight="Bold" Margin="0,0,10,0"/>
                    <TextBlock Text="GRICKO SS TOOL" Foreground="#F8FAFC" FontSize="17" FontWeight="Bold" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                    <Border Background="#1E1B4B" CornerRadius="4" Padding="6,2" Margin="12,0,0,0" VerticalAlignment="Center" BorderBrush="#4338CA" BorderThickness="1">
                        <TextBlock Text="OCEAN SUITE v2.2" Foreground="#38BDF8" FontSize="11" FontWeight="SemiBold"/>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="BtnMin" Content="_" Width="36" Height="28" Background="#131526" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand" Margin="0,0,6,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="5"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnClose" Content="X" Width="36" Height="28" Background="#1E1428" Foreground="#F43F5E" BorderThickness="0" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="5"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- TARGET & SYSTEM CARDS -->
            <Grid Grid.Row="1" Margin="0,8,0,8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="14"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Target Instance Card -->
                <Border Grid.Column="0" Background="#101222" CornerRadius="8" BorderBrush="#252847" BorderThickness="1" Padding="14,10">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <DockPanel Grid.Row="0" Margin="0,0,0,6">
                            <TextBlock Text="TARGET MINECRAFT INSTANCE" Foreground="#A78BFA" FontSize="11" FontWeight="Bold"/>
                            <Border Name="TargetStatusBadge" Background="#064E3B" CornerRadius="4" Padding="6,1" HorizontalAlignment="Right">
                                <TextBlock Name="TargetStatusText" Text="ANALYZING..." Foreground="#34D399" FontSize="10" FontWeight="Bold"/>
                            </Border>
                        </DockPanel>
                        <StackPanel Grid.Row="1" VerticalAlignment="Center">
                            <TextBlock Name="TxtLauncher" Text="Launcher : Detecting..." Foreground="#E2E8F0" FontSize="12" Margin="0,1"/>
                            <TextBlock Name="TxtProfile" Text="Profile  : Detecting..." Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtLastPlayed" Text="Last Run : Detecting..." Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtServer" Text="Server   : None detected" Foreground="#38BDF8" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- System & Elevation Card -->
                <Border Grid.Column="2" Background="#101222" CornerRadius="8" BorderBrush="#252847" BorderThickness="1" Padding="14,10">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <DockPanel Grid.Row="0" Margin="0,0,0,6">
                            <TextBlock Text="SYSTEM &amp; INTEGRITY STATUS" Foreground="#60A5FA" FontSize="11" FontWeight="Bold"/>
                            <Border Name="AdminBadge" Background="#1E1B4B" CornerRadius="4" Padding="6,1" HorizontalAlignment="Right">
                                <TextBlock Name="TxtAdmin" Text="CHECKING..." Foreground="#38BDF8" FontSize="10" FontWeight="Bold"/>
                            </Border>
                        </DockPanel>
                        <StackPanel Grid.Row="1" VerticalAlignment="Center">
                            <TextBlock Name="TxtHost" Text="Hostname : Detecting..." Foreground="#E2E8F0" FontSize="12" Margin="0,1"/>
                            <TextBlock Name="TxtUser" Text="User     : Detecting..." Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtEngine" Text="Engine   : Gricko Forensic Core v2.2.0" Foreground="#A78BFA" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtScanState" Text="Status   : Ready for inspection" Foreground="#34D399" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </Grid>

            <!-- SCAN CONTROL ACTION AREA -->
            <Border Grid.Row="2" Background="#101222" CornerRadius="8" BorderBrush="#252847" BorderThickness="1" Padding="14,10" Margin="0,0,0,8">
                <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="220"/>
                        <ColumnDefinition Width="16"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Button Name="BtnScan" Content="START SCAN" Height="44" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" Cursor="Hand">
                        <Button.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                <GradientStop Color="#7C3AED" Offset="0.0"/>
                                <GradientStop Color="#2563EB" Offset="1.0"/>
                            </LinearGradientBrush>
                        </Button.Background>
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>

                    <StackPanel Grid.Column="2" VerticalAlignment="Center">
                        <DockPanel Margin="0,0,0,6">
                            <TextBlock Name="TxtProgressStatus" Text="Ready to scan. Click 'START SCAN' to begin forensic analysis." Foreground="#94A3B8" FontSize="11"/>
                            <TextBlock Name="TxtPercent" Text="0%" Foreground="#38BDF8" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right"/>
                        </DockPanel>
                        <ProgressBar Name="ScanProgress" Height="8" Minimum="0" Maximum="100" Value="0" Background="#0A0B14" BorderThickness="0">
                            <ProgressBar.Foreground>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#8B5CF6" Offset="0.0"/>
                                    <GradientStop Color="#38BDF8" Offset="1.0"/>
                                </LinearGradientBrush>
                            </ProgressBar.Foreground>
                        </ProgressBar>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- LIVE ACTIVITY LOG CONSOLE -->
            <Border Grid.Row="3" Background="#06070E" CornerRadius="8" BorderBrush="#1C1F38" BorderThickness="1" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <DockPanel Grid.Row="0" Margin="4,0,4,6">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="[Live]" Foreground="#38BDF8" FontSize="11" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,6,0"/>
                            <TextBlock Text="FORENSIC ACTIVITY FEED" Foreground="#94A3B8" FontSize="11" FontWeight="Bold"/>
                        </StackPanel>
                        <TextBlock Name="BtnClearLogs" Text="Clear View" Foreground="#64748B" FontSize="11" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>
                    <ListBox Grid.Row="1" Name="LogListBox" Background="Transparent" BorderThickness="0" FontFamily="Consolas, Segoe UI" FontSize="12" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemContainerStyle>
                            <Style TargetType="ListBoxItem">
                                <Setter Property="Padding" Value="4,2"/>
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
                </Grid>
            </Border>

            <!-- SCORECARD & ACTION FOOTER -->
            <Grid Grid.Row="4" Margin="0,10,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- Scorecard Badges -->
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Name="BadgeFlags" Background="#2A1215" BorderBrush="#991B1B" BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,0,8,0">
                        <TextBlock Name="TxtFlagCount" Text="0 FLAGS" Foreground="#F87171" FontSize="12" FontWeight="Bold"/>
                    </Border>
                    <Border Name="BadgeWarns" Background="#2D2109" BorderBrush="#854D0E" BorderThickness="1" CornerRadius="6" Padding="12,6" Margin="0,0,8,0">
                        <TextBlock Name="TxtWarnCount" Text="0 WARNINGS" Foreground="#FBBF24" FontSize="12" FontWeight="Bold"/>
                    </Border>
                    <Border Name="BadgeCleans" Background="#0A2218" BorderBrush="#065F46" BorderThickness="1" CornerRadius="6" Padding="12,6">
                        <TextBlock Name="TxtCleanCount" Text="0 VERIFIED CLEAN" Foreground="#34D399" FontSize="12" FontWeight="Bold"/>
                    </Border>
                </StackPanel>

                <!-- Action Buttons -->
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="BtnExportJson" Content="Export JSON Report" Height="36" Padding="14,0" Background="#1E1B4B" Foreground="#C084FC" BorderBrush="#4C1D95" BorderThickness="1" FontWeight="SemiBold" Cursor="Hand" Margin="0,0,8,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnExit" Content="Exit" Height="36" Padding="16,0" Background="#131526" Foreground="#94A3B8" BorderThickness="0" FontWeight="SemiBold" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="6"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Resolve UI Elements
    $titleBarGrid      = $window.FindName("TitleBarGrid")
    $btnMin            = $window.FindName("BtnMin")
    $btnClose          = $window.FindName("BtnClose")
    $btnScan           = $window.FindName("BtnScan")
    $btnExportJson     = $window.FindName("BtnExportJson")
    $btnExit           = $window.FindName("BtnExit")
    $btnClearLogs      = $window.FindName("BtnClearLogs")
    $scanProgress      = $window.FindName("ScanProgress")
    $txtProgressStatus = $window.FindName("TxtProgressStatus")
    $txtPercent        = $window.FindName("TxtPercent")
    $logListBox        = $window.FindName("LogListBox")
    $txtLauncher       = $window.FindName("TxtLauncher")
    $txtProfile        = $window.FindName("TxtProfile")
    $txtLastPlayed     = $window.FindName("TxtLastPlayed")
    $txtServer         = $window.FindName("TxtServer")
    $targetStatusText  = $window.FindName("TargetStatusText")
    $txtHost           = $window.FindName("TxtHost")
    $txtUser           = $window.FindName("TxtUser")
    $txtAdmin          = $window.FindName("TxtAdmin")
    $adminBadge        = $window.FindName("AdminBadge")
    $txtFlagCount      = $window.FindName("TxtFlagCount")
    $txtWarnCount      = $window.FindName("TxtWarnCount")
    $txtCleanCount     = $window.FindName("TxtCleanCount")
    $txtScanState      = $window.FindName("TxtScanState")

    # Title Bar Drag & Window Controls
    $titleBarGrid.Add_MouseLeftButtonDown({
        param($s, $e)
        if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            $window.DragMove()
        }
    })

    $btnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnClose.Add_Click({ $window.Close() })
    $btnExit.Add_Click({ $window.Close() })
    $btnClearLogs.Add_MouseLeftButtonDown({ $logListBox.Items.Clear() })

    # Populate System Card
    $txtHost.Text = "Hostname : $env:COMPUTERNAME"
    $txtUser.Text = "User     : $env:USERNAME"
    $isAdmin = Test-IsAdmin
    if ($isAdmin) {
        $txtAdmin.Text = "ADMINISTRATOR"
        $txtAdmin.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        $adminBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
    } else {
        $txtAdmin.Text = "STANDARD USER"
        $txtAdmin.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        $adminBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
    }

    # Helper to pump WPF UI messages
    function Pump-WpfEvents {
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    }

    # Real-Time GUI Logger Callback
    $Global:GuiLoggerCallback = {
        param($entry)
        $window.Dispatcher.Invoke([Action]{
            $sp = [System.Windows.Controls.StackPanel]::new()
            $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $sp.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)

            # Timestamp
            $tbTime = [System.Windows.Controls.TextBlock]::new()
            $tbTime.Text = "$($entry.Timestamp) "
            $tbTime.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $tbTime.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
            $sp.Children.Add($tbTime) | Out-Null

            # Level Badge
            $tbBadge = [System.Windows.Controls.TextBlock]::new()
            $tbBadge.Text = "[$($entry.Level)] "
            $badgeColor = switch ($entry.Level) {
                "FLAG" { "#EF4444" }
                "WARN" { "#F59E0B" }
                "OK"   { "#10B981" }
                default{ "#38BDF8" }
            }
            $tbBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($badgeColor)
            $tbBadge.FontWeight = [System.Windows.FontWeights]::Bold
            $tbBadge.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
            $sp.Children.Add($tbBadge) | Out-Null

            # Message
            $tbMsg = [System.Windows.Controls.TextBlock]::new()
            $tbMsg.Text = $entry.Message
            $tbMsg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9")
            $sp.Children.Add($tbMsg) | Out-Null

            # Detail
            if ($entry.Detail) {
                $tbDet = [System.Windows.Controls.TextBlock]::new()
                $tbDet.Text = " -> $($entry.Detail)"
                $tbDet.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7DD3FC")
                $sp.Children.Add($tbDet) | Out-Null
            }

            $logListBox.Items.Add($sp) | Out-Null
            $logListBox.ScrollIntoView($sp)

            # Update Scorecard counters
            $txtFlagCount.Text = "$($Global:ReportData.Scorecard.Flags) FLAGS"
            $txtWarnCount.Text = "$($Global:ReportData.Scorecard.Warnings) WARNINGS"
            $txtCleanCount.Text = "$($Global:ReportData.Scorecard.Clean) VERIFIED CLEAN"
        })
    }

    # Status & Progress Callback
    $Global:GuiStatusCallback = {
        param([string]$status, [double]$pct)
        $window.Dispatcher.Invoke([Action]{
            if ($status) { $txtProgressStatus.Text = $status }
            if ($pct -ge 0) {
                $scanProgress.Value = $pct
                $txtPercent.Text = "$([int]$pct)%"
            }
        })
        Pump-WpfEvents
    }

    # Quick pre-inspection for Target Instance card on load
    try {
        $recent = Get-MinecraftInstances | Select-Object -First 1
        if ($recent) {
            $txtLauncher.Text = "Launcher : $($recent.LauncherName)"
            $txtProfile.Text = "Profile  : $($recent.ProfileName)"
            $txtLastPlayed.Text = "Last Run : $($recent.LastPlayedTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            $targetStatusText.Text = "TARGET FOUND"
        }
    } catch {}

    # Scan Button Action
    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false
        $btnScan.Content = "SCANNING..."
        $txtScanState.Text = "Status   : Inspection in progress"
        $txtScanState.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")

        # Reset counters
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $logListBox.Items.Clear()

        # Step 1: Target Instance (10%)
        Update-ScanStatus "Detecting last played Minecraft instance & analyzing logs..." 10
        Scan-LastPlayedInstance
        if ($Global:ReportData.LastPlayedInstance.LauncherName) {
            $inst = $Global:ReportData.LastPlayedInstance
            $txtLauncher.Text = "Launcher : $($inst.LauncherName)"
            $txtProfile.Text = "Profile  : $($inst.ProfileName)"
            $txtLastPlayed.Text = "Last Run : $($inst.LastPlayedTime)"
            if ($inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
                $txtServer.Text = "Server   : $($inst.ConnectedServers -join ', ')"
            }
        }
        Pump-WpfEvents

        # Step 2: Running Java Processes & Injections (25%)
        Update-ScanStatus "Inspecting Java processes, main classes and agents..." 25
        Scan-JavaProcesses
        Pump-WpfEvents

        # Step 3: Prefetch Traces (40%)
        Update-ScanStatus "Scanning Prefetch execution traces (Past $HoursPrefetch hrs)..." 40
        Scan-PrefetchTraces -Hours $HoursPrefetch
        Pump-WpfEvents

        # Step 4: BAM/DAM Registry (55%)
        Update-ScanStatus "Querying BAM/DAM kernel execution registry (Past $HoursBAM hrs)..." 55
        Scan-BAMRegistry -Hours $HoursBAM
        Pump-WpfEvents

        # Step 5: UserAssist ROT13 (70%)
        Update-ScanStatus "Decoding UserAssist ROT13 application execution history..." 70
        Scan-UserAssist
        Pump-WpfEvents

        # Step 6: File System, Temp drops & Anti-Forensics (85%)
        Update-ScanStatus "Checking Mods, Temp drops, Event Logs & USN Journal..." 85
        Scan-FileSystem -Hours $HoursFiles
        Pump-WpfEvents

        # Step 7: USB Storage Traces (95%)
        Update-ScanStatus "Enumerating USBSTOR device registry & removable drives..." 95
        Scan-USBStorage
        Pump-WpfEvents

        # Step 8: Final Report (100%)
        Update-ScanStatus "Forensic scan complete. Review summary scorecard below." 100
        $txtScanState.Text = "Status   : Scan Complete"
        $txtScanState.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")

        $btnScan.IsEnabled = $true
        $btnScan.Content = "RE-SCAN"
        Pump-WpfEvents
    })

    # Export JSON Button Action
    $btnExportJson.Add_Click({
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $filename = "Gricko_Report_${timestamp}.json"
        $savePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), $filename)
        try {
            $Global:ReportData | ConvertTo-Json -Depth 6 | Set-Content -Path $savePath -Encoding UTF8
            [System.Windows.MessageBox]::Show("Forensic report exported successfully to:`n$savePath", "Gricko SS Tool", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            $msg = $_.Exception.Message
            [System.Windows.MessageBox]::Show("Failed to export report: $msg", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    # Show Window
    $window.ShowDialog() | Out-Null
}
