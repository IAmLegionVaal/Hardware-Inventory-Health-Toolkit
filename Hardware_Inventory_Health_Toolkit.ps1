#requires -Version 5.1
<#
.SYNOPSIS
    Hardware Inventory Health Toolkit.
.DESCRIPTION
    Read-only hardware inventory and health context reporter for Windows support.
#>
[CmdletBinding()]
param([string]$OutputPath)

$RunStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Hardware_Inventory_Reports' }
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
function Export-Data { param($Name,$Data) $Data | Export-Csv (Join-Path $OutputPath "$Name.csv") -NoTypeInformation -Encoding UTF8; $Data | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $OutputPath "$Name.json") -Encoding UTF8 }
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed
$summary = [PSCustomObject]@{Computer=$env:COMPUTERNAME;Manufacturer=$cs.Manufacturer;Model=$cs.Model;MemoryGB=[math]::Round($cs.TotalPhysicalMemory/1GB,2);OS=$os.Caption;Build=$os.BuildNumber;BIOS=$bios.SMBIOSBIOSVersion;Serial=$bios.SerialNumber;Generated=Get-Date}
$disks = Get-CimInstance Win32_DiskDrive | Select-Object Model,InterfaceType,MediaType,Size,Status,SerialNumber
$logical = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,VolumeName,FileSystem,Size,FreeSpace
$battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object Name,Status,BatteryStatus,EstimatedChargeRemaining,EstimatedRunTime
$nics = Get-NetAdapter -ErrorAction SilentlyContinue | Select-Object Name,Status,LinkSpeed,MacAddress,InterfaceDescription
Export-Data -Name "hardware_summary_$RunStamp" -Data @($summary)
Export-Data -Name "cpu_$RunStamp" -Data $cpu
Export-Data -Name "disk_drives_$RunStamp" -Data $disks
Export-Data -Name "logical_disks_$RunStamp" -Data $logical
Export-Data -Name "battery_$RunStamp" -Data $battery
Export-Data -Name "network_adapters_$RunStamp" -Data $nics
$html = "<h1>Hardware Inventory - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary) | ConvertTo-Html -Fragment)<h2>Disks</h2>$($disks | ConvertTo-Html -Fragment)<h2>Network Adapters</h2>$($nics | ConvertTo-Html -Fragment)"
$html | ConvertTo-Html -Title 'Hardware Inventory Health' | Set-Content (Join-Path $OutputPath "hardware_inventory_$RunStamp.html") -Encoding UTF8
$summary | Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
