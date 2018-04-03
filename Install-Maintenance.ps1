<#
.Synopsis
   Creates a scheduled task for performing maintenance on a PCs.


.Example
.\Install-Maintenance.ps1

Installs the maintenance script and schedules a task. Randomly selecting a time between 1:30am and 4:30am.

.Example
.\Install-Maintenance.ps1 -Day SUN -Time 03:00

Specifies the time to run as Sunday at 3am.

.Example
Install-Maintenance.ps1 -EarliestTime 00:00 -LatestTime 06:00

Randomly selects a time, any day of the week, between midnight and 6am.

.Example
.\Install-Maintenance.ps1 -DayOptions Sat,Sun -EarliestTime 00:00 -LatestTime 06:00

Randomly selects a time, on a weekend, between midnight and 6am.

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
    [string]$Time,

    # Array specifing the possible days, of which one will be randomly chosen. Possible options are 'MON','TUE','WED','THU','FRI','SAT','SUN'.
    [Parameter(ParameterSetName='Auto')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MON','TUE','WED','THU','FRI','SAT','SUN')]
    [string[]]$DayOptions = @('MON','TUE','WED','THU','FRI','SAT','SUN'),

    # When chosing a time automatically, this is the earliest time that will be chosen, in 24 hour format. Defaults to 01:30.
    [Parameter(ParameterSetName='Auto')]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]$')]
    # HH:mm
    [string]$EarliestTime = '01:30',

    # When chosing a time automatically, this is the latest time that will be chosen, in 24 hour format. Defaults to 04:30.
    [Parameter(ParameterSetName='Auto')]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[0-2][0-9]:[0-5][0-9]$')]
    # HH:mm
    [string]$LatestTime   = '04:30',

    # This is where the Maintenance.ps1 script will be placed, then ran from by the scheduled task.
    [string]$InstallPath = "$env:ProgramFiles\Peckham\WsMaintenance"

)

if ($PsCmdlet.ParameterSetName -eq 'Auto') {
    $Day = $DayOptions | Get-Random

    $minimumTicks = (Get-Date $EarliestTime).Ticks
    $maximumTicks = (Get-Date $LatestTime).Ticks
    $randomTick   = Get-Random -Minimum $minimumTicks -Maximum $maximumTicks
    $randomTime   = New-Object System.DateTime -ArgumentList $randomTick
    $Time = $randomTime.ToString('HH:mm')
}


if ((Test-Path $InstallPath) -ne $true) {
    New-Item -Path $InstallPath -ItemType Directory -Verbose:$Verbose | Out-Null
}

$ScriptInstallPath = Join-Path $InstallPath 'Maintenance.ps1'

if ( !($PSScriptRoot)) {
	$PSScriptRoot = split-path $MyInvocation.MyCommand.Path -Parent
}

Write-Verbose "Copying maintenance script to $ScriptInstallPath."
Copy-Item -Path "$PsScriptRoot\Maintenance.ps1" -Destination $ScriptInstallPath

Write-Verbose "Scheduling maintenance task for $Day at $Time."
$task = 'Powershell.exe -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File \"{0}\"' -f $ScriptInstallPath
$rtn = SCHTASKS /CREATE /TN 'Maintenance' /TR $task /SC WEEKLY /D $Day /ST $Time /RU SYSTEM /RL HIGHEST /F

exit $LASTEXITCODE
