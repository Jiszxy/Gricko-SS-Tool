<#
    Gricko SS Tool - Minimalist Ocean-Style Automated Screenshare GUI
    Compact Floating Window with Shark Logo, Centered Progress & Detailed Inspection
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
        Title="Gricko SS Tool - Advanced Automated Screenshare"
        Height="440" Width="580"
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

    <Border CornerRadius="14" BorderThickness="1.2" BorderBrush="#252833">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                <GradientStop Color="#15161A" Offset="0.0"/>
                <GradientStop Color="#0F1014" Offset="1.0"/>
            </LinearGradientBrush>
        </Border.Background>

        <Grid Margin="18">
            <Grid.RowDefinitions>
                <RowDefinition Height="32"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="24"/>
            </Grid.RowDefinitions>

            <!-- TOP BAR: DRAGGABLE REGION & CONTROLS -->
            <Grid Grid.Row="0" Name="TitleBarGrid" Background="Transparent">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="gricko" Foreground="#64748B" FontSize="11" FontWeight="SemiBold" Margin="4,0,0,0"/>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="BtnMin" Content="—" Width="30" Height="24" Background="#1A1C24" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand" Margin="0,0,5,0">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                    <Button Name="BtnClose" Content="✕" Width="30" Height="24" Background="#1A1C24" Foreground="#94A3B8" BorderThickness="0" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="4"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- MAIN DYNAMIC CONTENT AREA -->
            <Grid Grid.Row="1" VerticalAlignment="Center">
                
                <!-- VIEW 1: HOME & SCAN BUTTON -->
                <StackPanel Name="HomeView" Visibility="Visible" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,10,0,0">
                    <!-- Shark Logo -->
                    <TextBlock Text="}&lt;(((*&gt;" Foreground="#CBD5E1" FontSize="36" FontWeight="Bold" FontFamily="Consolas, Courier New" HorizontalAlignment="Center" Margin="0,0,0,14"/>
                    
                    <!-- Title & Subtitle -->
                    <TextBlock Text="Gricko SS Tool" Foreground="#F8FAFC" FontSize="20" FontWeight="Bold" FontFamily="Segoe UI" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                    <TextBlock Text="Advanced Automated screenshare" Foreground="#94A3B8" FontSize="12.5" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,26"/>

                    <!-- Centered Scan Button -->
                    <Button Name="BtnScan" Content="SCAN" Width="140" Height="38" FontSize="13" FontWeight="Bold" Foreground="#FFFFFF" Background="#262A38" BorderBrush="#3B4259" BorderThickness="1" Cursor="Hand" HorizontalAlignment="Center">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="19"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>

                <!-- VIEW 2: SCANNING PROGRESS BAR -->
                <StackPanel Name="ProgressView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="420" Margin="0,15,0,0">
                    <!-- Shark Logo -->
                    <TextBlock Text="}&lt;(((*&gt;" Foreground="#E2E8F0" FontSize="36" FontWeight="Bold" FontFamily="Consolas, Courier New" HorizontalAlignment="Center" Margin="0,0,0,14"/>
                    
                    <TextBlock Text="Gricko SS Tool" Foreground="#F8FAFC" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                    <TextBlock Text="Advanced Automated screenshare" Foreground="#94A3B8" FontSize="12.5" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,28"/>

                    <!-- Rounded Progress Bar -->
                    <Border CornerRadius="8" Height="14" Background="#1B1D26" Margin="0,0,0,12" ClipToBounds="True">
                        <ProgressBar Name="ScanProgress" Height="14" Minimum="0" Maximum="100" Value="0" Background="Transparent" BorderThickness="0">
                            <ProgressBar.Foreground>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#E2E8F0" Offset="0.0"/>
                                    <GradientStop Color="#FFFFFF" Offset="1.0"/>
                                </LinearGradientBrush>
                            </ProgressBar.Foreground>
                        </ProgressBar>
                    </Border>

                    <!-- Status Text e.g. "Scanning memory... • 50%" -->
                    <TextBlock Name="TxtProgressStatus" Text="Scanning memory... • 0%" Foreground="#94A3B8" FontSize="12" HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- VIEW 3: RESULTS SUMMARY -->
                <StackPanel Name="ResultsView" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" Width="460">
                    <!-- Shark Logo -->
                    <TextBlock Text="}&lt;(((*&gt;" Foreground="#CBD5E1" FontSize="30" FontWeight="Bold" FontFamily="Consolas, Courier New" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                    
                    <TextBlock Name="TxtResultTitle" Text="Scan Complete" Foreground="#F8FAFC" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                    <TextBlock Name="TxtResultSubtitle" Text="All forensic tests concluded." Foreground="#34D399" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,0,0,14"/>

                    <!-- Last Played Instance Box -->
                    <Border Background="#161822" CornerRadius="8" BorderBrush="#25293A" BorderThickness="1" Padding="14,10" Margin="0,0,0,14">
                        <StackPanel>
                            <DockPanel Margin="0,0,0,4">
                                <TextBlock Text="LAST PLAYED INSTANCE" Foreground="#94A3B8" FontSize="10.5" FontWeight="Bold"/>
                                <TextBlock Name="TxtResultTime" Text="N/A" Foreground="#38BDF8" FontSize="10.5" FontWeight="Bold" HorizontalAlignment="Right"/>
                            </DockPanel>
                            <TextBlock Name="TxtResultLauncher" Text="Launcher : None detected" Foreground="#E2E8F0" FontSize="11.5" Margin="0,1"/>
                            <TextBlock Name="TxtResultProfile" Text="Profile  : Standard" Foreground="#94A3B8" FontSize="11" Margin="0,1"/>
                            <TextBlock Name="TxtResultServer" Text="Server   : None" Foreground="#38BDF8" FontSize="11" Margin="0,1"/>
                        </StackPanel>
                    </Border>

                    <!-- Detections Pill -->
                    <TextBlock Name="TxtDetectionsBadge" Text="No Cheats Detected" Foreground="#34D399" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,14"/>

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

                <!-- VIEW 4: EXPANDED DETAILS INSPECTOR -->
                <Grid Name="DetailsView" Visibility="Collapsed" Height="330" Margin="4,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,8">
                        <TextBlock Text="DEEP SCAN FORENSIC DETAILS" Foreground="#F8FAFC" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button Name="BtnBackFromDetails" Content="← Back" Background="Transparent" Foreground="#38BDF8" BorderThickness="0" FontSize="12" FontWeight="SemiBold" Cursor="Hand" HorizontalAlignment="Right"/>
                    </DockPanel>

                    <!-- Scrollable inspection log -->
                    <Border Grid.Row="1" Background="#0C0D11" CornerRadius="8" BorderBrush="#1C1E26" BorderThickness="1" Padding="8">
                        <ListBox Name="DetailsListBox" Background="Transparent" BorderThickness="0" FontFamily="Consolas, Segoe UI" FontSize="11.5" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                            <ListBox.ItemContainerStyle>
                                <Style TargetType="ListBoxItem">
                                    <Setter Property="Padding" Value="2,2"/>
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

                    <!-- Export button in details -->
                    <DockPanel Grid.Row="2" Margin="0,8,0,0">
                        <TextBlock Name="TxtSummaryStats" Text="0 Flags | 0 Clean Checks" Foreground="#64748B" FontSize="11" VerticalAlignment="Center"/>
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

            <!-- FOOTER WATERMARK (Matching screenshot) -->
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
    $titleBarGrid       = $window.FindName("TitleBarGrid")
    $btnMin             = $window.FindName("BtnMin")
    $btnClose           = $window.FindName("BtnClose")
    $homeView           = $window.FindName("HomeView")
    $progressView       = $window.FindName("ProgressView")
    $resultsView        = $window.FindName("ResultsView")
    $detailsView        = $window.FindName("DetailsView")
    $btnScan            = $window.FindName("BtnScan")
    $btnDetails         = $window.FindName("BtnDetails")
    $btnRescan          = $window.FindName("BtnRescan")
    $btnBackFromDetails = $window.FindName("BtnBackFromDetails")
    $btnExportJson      = $window.FindName("BtnExportJson")
    $scanProgress       = $window.FindName("ScanProgress")
    $txtProgressStatus  = $window.FindName("TxtProgressStatus")
    $txtResultTitle     = $window.FindName("TxtResultTitle")
    $txtResultSubtitle  = $window.FindName("TxtResultSubtitle")
    $txtResultTime      = $window.FindName("TxtResultTime")
    $txtResultLauncher  = $window.FindName("TxtResultLauncher")
    $txtResultProfile   = $window.FindName("TxtResultProfile")
    $txtResultServer    = $window.FindName("TxtResultServer")
    $txtDetectionsBadge = $window.FindName("TxtDetectionsBadge")
    $detailsListBox     = $window.FindName("DetailsListBox")
    $txtSummaryStats    = $window.FindName("TxtSummaryStats")

    # Drag Move
    $titleBarGrid.Add_MouseLeftButtonDown({
        param($s, $e)
        if ($e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            $window.DragMove()
        }
    })

    $btnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnClose.Add_Click({ $window.Close() })

    # Navigation Handlers
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
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    }

    # GUI Logger Hook
    $Global:GuiLoggerCallback = {
        param($entry)
        $window.Dispatcher.Invoke([Action]{
            $sp = [System.Windows.Controls.StackPanel]::new()
            $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $sp.Margin = [System.Windows.Thickness]::new(0, 1, 0, 1)

            $tbTime = [System.Windows.Controls.TextBlock]::new()
            $tbTime.Text = "$($entry.Timestamp) "
            $tbTime.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $sp.Children.Add($tbTime) | Out-Null

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
            $sp.Children.Add($tbBadge) | Out-Null

            $tbMsg = [System.Windows.Controls.TextBlock]::new()
            $tbMsg.Text = $entry.Message
            $tbMsg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9")
            $sp.Children.Add($tbMsg) | Out-Null

            if ($entry.Detail) {
                $tbDet = [System.Windows.Controls.TextBlock]::new()
                $tbDet.Text = " -> $($entry.Detail)"
                $tbDet.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
                $sp.Children.Add($tbDet) | Out-Null
            }

            $detailsListBox.Items.Add($sp) | Out-Null
        })
    }

    $Global:GuiStatusCallback = {
        param([string]$status, [double]$pct)
        $window.Dispatcher.Invoke([Action]{
            if ($pct -ge 0) {
                $scanProgress.Value = $pct
                $txtProgressStatus.Text = "$status • $([int]$pct)%"
            } else {
                $txtProgressStatus.Text = $status
            }
        })
        Pump-WpfEvents
    }

    # Main Scan Logic
    $btnScan.Add_Click({
        $homeView.Visibility = [System.Windows.Visibility]::Collapsed
        $progressView.Visibility = [System.Windows.Visibility]::Visible
        $detailsListBox.Items.Clear()

        # Reset counters & detections
        $Global:ReportData.Scorecard.Flags = 0
        $Global:ReportData.Scorecard.Warnings = 0
        $Global:ReportData.Scorecard.Clean = 0
        $Global:ReportData.Scorecard.Info = 0
        $Global:ReportData.CheatClients = @()
        $Global:ReportData.LegitClients = @()

        # Phase 1: Last Instance (15%)
        Update-ScanStatus "Detecting last played instance..." 15
        Scan-LastPlayedInstance
        Pump-WpfEvents

        # Phase 2: Memory & Running Processes (35%)
        Update-ScanStatus "Scanning memory..." 35
        Scan-JavaProcesses
        Pump-WpfEvents

        # Phase 3: Prefetch Traces (55%)
        Update-ScanStatus "Analyzing Prefetch history..." 55
        Scan-PrefetchTraces -Hours $HoursPrefetch
        Pump-WpfEvents

        # Phase 4: BAM / DAM Registry (70%)
        Update-ScanStatus "Checking BAM execution records..." 70
        Scan-BAMRegistry -Hours $HoursBAM
        Pump-WpfEvents

        # Phase 5: UserAssist & File Systems (85%)
        Update-ScanStatus "Auditing UserAssist and file system..." 85
        Scan-UserAssist
        Scan-FileSystem -Hours $HoursFiles
        Pump-WpfEvents

        # Phase 6: Hardware & USB (95%)
        Update-ScanStatus "Checking hardware & USB devices..." 95
        Scan-USBStorage
        Pump-WpfEvents

        # Finalizing (100%)
        Update-ScanStatus "Finalizing scan results..." 100
        Start-Sleep -Milliseconds 400

        # Populate Results View
        $inst = $Global:ReportData.LastPlayedInstance
        if ($inst -and $inst.LastPlayedTime) {
            $txtResultTime.Text = "$($inst.LastPlayedTime)"
            $txtResultLauncher.Text = "Launcher : $($inst.LauncherName)"
            $txtResultProfile.Text = "Profile  : $($inst.ProfileName) ($($inst.Version))"
            if ($inst.ConnectedServers -and $inst.ConnectedServers.Count -gt 0) {
                $txtResultServer.Text = "Server   : $($inst.ConnectedServers -join ', ')"
            } else {
                $txtResultServer.Text = "Server   : Singleplayer / Unrecorded"
            }
        } else {
            $txtResultTime.Text = "No Instance Found"
            $txtResultLauncher.Text = "Launcher : N/A"
            $txtResultProfile.Text = "Profile  : N/A"
            $txtResultServer.Text = "Server   : N/A"
        }

        # Populate Detections
        $flags = $Global:ReportData.Scorecard.Flags
        if ($flags -gt 0) {
            $txtResultTitle.Text = "Cheats Detected"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
            $txtResultSubtitle.Text = "$flags suspicious or cheat artifacts identified"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
            $txtDetectionsBadge.Text = "$flags CHEAT ARTIFACTS FLAGGED"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
        } else {
            $txtResultTitle.Text = "Scan Complete"
            $txtResultTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F8FAFC")
            $txtResultSubtitle.Text = "No cheat clients or injection tools detected"
            $txtResultSubtitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtDetectionsBadge.Text = "VERIFIED CLEAN"
            $txtDetectionsBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        }

        $txtSummaryStats.Text = "$flags Flags | $($Global:ReportData.Scorecard.Warnings) Warnings | $($Global:ReportData.Scorecard.Clean) Clean Checks"

        # Transition to Results View
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
