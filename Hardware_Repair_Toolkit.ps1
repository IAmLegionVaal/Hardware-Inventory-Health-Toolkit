[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [switch]$RescanDevices,
 [string]$RestartDeviceInstanceId,
 [string]$EnableDeviceInstanceId,
 [ValidatePattern('^[A-Z]$')][string]$ScanVolume,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'HardwareRepairReports')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;Devices=Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue|Where-Object Status -ne 'OK'|Select-Object Status,Class,FriendlyName,InstanceId;Disks=Get-PhysicalDisk -ErrorAction SilentlyContinue|Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,Size;Volumes=Get-Volume|Select-Object DriveLetter,FileSystem,HealthStatus,OperationalStatus,SizeRemaining,Size}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 6|Set-Content $before -Encoding UTF8
if(-not($RescanDevices -or $RestartDeviceInstanceId -or $EnableDeviceInstanceId -or $ScanVolume)){Write-Error 'Choose at least one repair action.';exit 2}
if(-not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected hardware repairs? Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($RescanDevices){Act 'Rescanning Plug and Play devices' {& pnputil.exe /scan-devices|Out-Null;if($LASTEXITCODE){throw "pnputil exited $LASTEXITCODE"}}}
if($RestartDeviceInstanceId){$d=Get-PnpDevice -InstanceId $RestartDeviceInstanceId -ErrorAction Stop;Act "Restarting device $($d.FriendlyName)" {Disable-PnpDevice -InstanceId $RestartDeviceInstanceId -Confirm:$false;Start-Sleep 2;Enable-PnpDevice -InstanceId $RestartDeviceInstanceId -Confirm:$false}}
if($EnableDeviceInstanceId){$d=Get-PnpDevice -InstanceId $EnableDeviceInstanceId -ErrorAction Stop;Act "Enabling device $($d.FriendlyName)" {Enable-PnpDevice -InstanceId $EnableDeviceInstanceId -Confirm:$false}}
if($ScanVolume){Act "Scanning volume ${ScanVolume}:" {Repair-Volume -DriveLetter $ScanVolume -Scan -ErrorAction Stop|Out-Null}}
Start-Sleep 2;State|ConvertTo-Json -Depth 6|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
