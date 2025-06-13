Function Get-DefenderEvents{
<#
.Synopsis
    Find events for Windows Defender
.DESCRIPTION
    Find logs in Event Viewer for Windows Defender sub for past 10 days
.EXAMPLE
    Get-DefenderEvents -ComputerName "MACHINENAME"
#>
       Param([parameter(Mandatory=$true)][alias("Computer")]$ComputerName)
$xmlQuery = @'
<QueryList>
<Query Path="Microsoft-Windows-Windows Defender/Operational">
<Select Path="Microsoft-Windows-Windows Defender/Operational">*[System[(Level=1  or Level=2 or Level=3 or Level=4) and TimeCreated[timediff(@SystemTime) &lt;= 864000000]]]</Select>
</Query>
</QueryList>
'@

#Get events with FilterXML
$Events= Get-WinEvent -ComputerName $ComputerName -FilterXML $xmlQuery

#Export the Application events to the CSV file
$Events | Select-Object -Property TimeCreated,Message,ID | Export-CSV "C:\Temp\DefenderEvents-$ComputerName.CSV" -NoTypeInformation -Encoding UTF8
}
