<#
.Synopsis
   Find Win10 Devices
.DESCRIPTION
   Don't have enterprise tools? Run this script to find Win10 and older machines in your env.
.EXAMPLE
   Run locally
#>


$PCs = Get-ADComputer -Filter 'Name -like "*"' -Properties * | Where-object {($_.OperatingSystem -NotLike "*Windows 11*") -and ($_.OperatingSystem -NotLike "*Server*") -and ($_.OperatingSystem -NotLike $null)} | Select-Object CN, Enabled, OperatingSystem, OperatingSystemVersion
Foreach ($PC in $PCs){
    If(Test-Connection -ComputerName $PC.CN -count 1 -quiet){
        $Active = "True"
    } Else {
        $Active = "False"
        }
    $Export = [pscustomobject]@{
        ComputerName = $PC.CN
        Enabled = $PC.Enabled
        OperatingSystem = $PC.OperatingSystem
        OperatingSystemVersion = $PC.OperatingSystemVersion
        Pingable = $Active
    }
    $Export | Export-csv -Path "c:\temp\NonWin11Machines.csv" -Append    
}
