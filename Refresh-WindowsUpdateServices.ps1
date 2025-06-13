<#
.Synopsis
    Refresh Windows Updates components
.DESCRIPTION
    Refresh the components for Windows Updates
.EXAMPLE
    Run locally or deploy via MECM to individual machines
#>


<# Variable Declaration #>
$WUservice = Get-WmiObject -Class Win32_Service -Filter "Name='wuauserv'" 
$BITSservice = Get-WmiObject -Class Win32_Service -Filter "Name='BITS'"
$Cryptsvc = Get-WmiObject -Class Win32_service -Filter "Name='cryptsvc'"
$Msiserver = Get-WmiObject -Class Win32_service -Filter "Name='msiserver'"
$gpupdate = Get-WmiObject -Class Win32_service -Filter "Name='gpupdate'"
$gupdatemr = Get-WmiObject -Class Win32_service -Filter "Name='gupdatem'"
$edgeupdate = Get-WmiObject -Class Win32_service -Filter "Name='edgeupdate'"
$edgeupdatem = Get-WmiObject -Class Win32_service -Filter "Name='edgeupdatem'"
$gpsvc = Get-WmiObject -Class Win32_service -Filter "Name='gpsvc'"
$MpsSvc = Get-WmiObject -Class Win32_service -Filter "Name='MpsSvc'"


<# Handle Services & Search SCCM for Updates #>
#write-host "Restarting Services"
If($gpupdate){
    Restart-Service gpupdate -Force
    Start-Sleep -Seconds 2
}
If($gupdatem){
    Restart-Service gupdatem -Force
    Start-Sleep -Seconds 2
}
If($edgeupdate){
    Restart-Service edgeupdate -Force
    Start-Sleep -Seconds 2
}
If($edgeupdatem){
    Restart-Service edgeupdatem -Force
    Start-Sleep -Seconds 2
}
If($gpsvc){
    Restart-Service gpsvc -Force
    Start-Sleep -Seconds 2
}
If($wuauserv){
    Restart-Service wuauserv -Force
    Start-Sleep -Seconds 2
}
If($BITS){
    Restart-Service BITS -Force
    Start-Sleep -Seconds 2
}
If($cryptsvc){
    Restart-Service cryptsvc -Force
    Start-Sleep -Seconds 2
}
If($msiserver){
    Restart-Service msiserver -Force
    Start-Sleep -Seconds 2
}
If($MpsSvc){
    Restart-Service MpsSvc -Force
    Start-Sleep -Seconds 2
}
#write-host "Kicking off Config Mgr Software Update Deployment Eval"
Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000108}" 
