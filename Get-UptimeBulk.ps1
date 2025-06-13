<#
.Synopsis
    Get Uptime for list of PCs
.DESCRIPTION
    Read off of a .txt file and report back update if host is online
.EXAMPLE
   Run locally

#>

foreach($PC in (Get-Content -Path "PATH\FILE.txt")){
    if ( test-connection $PC -count 1 -quiet ){
        $Uptime = Get-WmiObject win32_operatingsystem -ComputerName $PC | select csname, @{LABEL=’LastBootUpTime’ ;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}} 
        Write-host "`n $Uptime `n"
        $Uptime | Export-Csv -Path "c:\temp\Uptime\UptimeOut.txt" -Append -NoClobber -NoTypeInformation
    } Else {
         $status = " is unreachable"
         $PC + $status | Export-Csv -Path "c:\temp\Uptime\UptimeOut_Offline.txt" -Append -NoClobber -NoTypeInformation
    }
}
