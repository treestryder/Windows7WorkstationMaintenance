WorkstationMaintenance.ps1
$RebootRequired = $false

function Main {
    $RebootRequired = DiskCleanUp
    # Force reboot, remove to reboot only after a successful purge of Windows Update packages. 
    $RebootRequired = $true
}

function DiskCleanUp {
    # Clear settings
    Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*' -Name StateFlags0001 -ErrorAction SilentlyContinue | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue -Verbose
    # Enable Update Cleanup
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0001 -Value 2 -PropertyType DWord -Verbose
    Write-Host 'Starting CleanMgr.exe'
    Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -WindowStyle Hidden -Wait -Verbose
    Write-Host 'Waiting for CleanMgr and DismHost processes.'
    Get-Process -Name cleanmgr,dismhost | Wait-Process
    $status = Select-String -Path C:\Windows\Logs\CBS\DeepClean.log -Pattern 'Total size of superseded packages:'
    $didCleanup = $status -ne $null
    return $didCleanup
}

function Reboot {
    Write-Host 'Rebooting.'
    SHUTDOWN.EXE /r /f /t 0 /c 'Reboot initiated by Maintenance.ps1'
}

Start-Transcript -Path "$env:SystemRoot\Logs\Maintenance.ps1.log"
. Main
Stop-Transcript 

if ($RebootRequired) { Reboot }
