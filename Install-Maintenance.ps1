<#
.Synopsis
   Creates a scheduled task for performing maintenance on a PCs.
#>

[CmdletBinding(DefaultParameterSetName='Auto')]
param (
    # Specifies the day of the week that the Maintenance.ps1 script will be ran. If no time and day are specified, a random time is chosen.
    [Parameter(Mandatory=$true,
        Position=0,
        ParameterSetName='TimeSpecified')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MON','TUE','WED','THU','FRI','SAT','SUN')]
    [string]$Day,
    
    # Specifies the time that the Maintenance.ps1 script will be ran. If no time and day are specified, a random time is chosen.
    [Parameter(Mandatory=$true,
        Position=1,
        ParameterSetName='TimeSpecified')]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]$')]
    [string]$Time
)

if ($PsCmdlet.ParameterSetName -eq 'Auto') {
    $Day = 'MON','TUE','WED','THU','FRI','SAT','SUN' | Get-Random
    $hour = 1..4 | Get-Random
    $minutes = 0..59 | Get-Random
    if ($hour -eq 4) {
        $minutes = 0..30 | Get-Random
    }
    
    $Time = '{0:00}:{1:00}' -f $hour,$minutes
}

$ScriptInstallPath = "$env:SystemRoot\Maintenance.ps1"

if ( !($PSScriptRoot)) {
	$PSScriptRoot = split-path $MyInvocation.MyCommand.Path -Parent
}
Copy-Item -Path "$PsScriptRoot\Maintenance.ps1" -Destination $ScriptInstallPath -Verbose

$task = "Powershell.exe -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File $ScriptInstallPath"
SCHTASKS /CREATE /TN 'Maintenance' /TR $task /SC WEEKLY /D $Day /ST $Time /RU SYSTEM /RL HIGHEST /F | Out-String
