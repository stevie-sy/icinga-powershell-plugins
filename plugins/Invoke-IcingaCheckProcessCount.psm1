<#
.SYNOPSIS
    Checks how many processes of a process exist.
.DESCRIPTION
    Invoke-IcingaCheckDirectory returns either 'OK', 'WARNING' or 'CRITICAL', based on the thresholds set.
    e.g there are three conhost processes running, WARNING is set to 3, CRITICAL is set to 4. In this case the check will return WARNING.
    More Information on https://github.com/Icinga/icinga-powershell-plugins
.FUNCTIONALITY
    This module is intended to be used to check how many processes of a process exist.
    Based on the thresholds set the status will change between 'OK', 'WARNING' or 'CRITICAL'. The function will return one of these given codes.
.ROLE
    ### WMI Permissions

    * root\cimv2

    ### Performance Counter

    * Processor(*)\% processor time

    ### Required User Groups

    * Performance Monitor Users
.EXAMPLE
    PS>Invoke-IcingaCheckProcessCount -Process conhost -Warning 5 -Critical 10
    [OK]: Check package "Process Check" is [OK]
    | 'Process Count "conhost"'=3;;
.EXAMPLE
    PS>Invoke-IcingaCheckProcessCount -Process conhost,wininit -Warning 5 -Critical 10 -Verbosity 3
    [OK]: Check package "Process Check" is [OK] (Match All)
        \_ [OK]: Process Count "conhost" is 3
        \_ [OK]: Process Count "wininit" is 1
    | 'Process Count "conhost"'=3;5;10 'Process Count "wininit"'=1;5;10
.PARAMETER Warning
    Used to specify a Warning threshold. In this case an integer value.
.PARAMETER Critical
    Used to specify a Critical threshold. In this case an integer value.
.PARAMETER Process
    Used to specify an array of processes to count and match against. e.g. conhost,wininit
.PARAMETER Verbosity
    Changes the behavior of the plugin output which check states are printed:
    0 (default): Only service checks/packages with state not OK will be printed
    1: Only services with not OK will be printed including OK checks of affected check packages including Package config
    2: Everything will be printed regardless of the check state
    3: Identical to Verbose 2, but prints in addition the check package configuration e.g (All must be [OK])
.INPUTS
    System.String
.OUTPUTS
    System.String
.LINK
    https://github.com/Icinga/icinga-powershell-plugins
.NOTES
#>

function Invoke-IcingaCheckProcessCount()
{
    param (
        $Warning            = $null,
        $Critical           = $null,
        [array]$Process     = @(),
        [switch]$NoPerfData = $FALSE,
        [ValidateSet(0, 1, 2, 3)]
        [int]$Verbosity     = 0
    );

    $ProcessInformation = (Get-IcingaProcessData -Process $Process)
    $ProcessPackage     = New-IcingaCheckPackage -Name 'Process Check' -OperatorAnd -Verbose $Verbosity -NoPerfData $NoPerfData -AddSummaryHeader;

    if ($Process.Count -eq 0) {
        $ProcessCount = $ProcessInformation['Process Count'];
        $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Process Count')) -Value $ProcessCount;
        $IcingaCheck.WarnOutOfRange($Warning).CritOutOfRange($Critical) | Out-Null;
        $ProcessPackage.AddCheck($IcingaCheck);
    } else {
        foreach ($proc in $process) {
            $ProcessCount = $ProcessInformation.Processes[$proc].ProcessList.Count;
            $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Process Count "{0}"', $proc)) -Value $ProcessCount;
            $IcingaCheck.WarnOutOfRange($Warning).CritOutOfRange($Critical) | Out-Null;
            $ProcessPackage.AddCheck($IcingaCheck);
        }
    }

    return (New-IcingaCheckResult -Check $ProcessPackage -NoPerfData $NoPerfData -Compile);
}
