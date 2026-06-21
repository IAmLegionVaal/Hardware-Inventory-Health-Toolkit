# Hardware Inventory Health Toolkit

A PowerShell toolkit for Windows hardware inventory, health checks and selected guarded repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Hardware_Inventory_Health_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Hardware_Repair_Toolkit.ps1 -RescanDevices -DryRun
```

Examples:

```powershell
.\Hardware_Repair_Toolkit.ps1 -RescanDevices
.\Hardware_Repair_Toolkit.ps1 -RestartDeviceInstanceId 'PCI\VEN_...'
.\Hardware_Repair_Toolkit.ps1 -EnableDeviceInstanceId 'USB\VID_...'
.\Hardware_Repair_Toolkit.ps1 -ScanVolume C
```

## What the repair does

- Rescans Plug and Play devices.
- Restarts one explicitly selected device by instance ID.
- Enables one explicitly selected disabled device.
- Runs an online scan of one selected volume.
- Captures unhealthy device, disk and volume state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Safety

Restarting a device can interrupt networking, storage, audio or input. The tool does not uninstall drivers, update firmware, format disks or disable arbitrary hardware automatically.

## Author

Dewald Pretorius — L2 IT Support Engineer
