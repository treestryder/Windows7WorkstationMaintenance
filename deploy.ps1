<#
.Synopsis
Copies Windows 7 Maintenance and Install script to production location.
#>

$Destination = '\\nhartley\shared\SCCM\WorkstationMaintenance\Windows7'

New-Item -Path $Destination -ItemType Directory -Force | Out-Null

Copy-Item -Path "$PSScriptRoot\Install-Maintenance.ps1" -Destination $Destination -Verbose
Copy-Item -Path "$PSScriptRoot\Maintenance.ps1" -Destination $Destination -Verbose
