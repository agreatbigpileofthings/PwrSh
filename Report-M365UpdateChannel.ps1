<#
.Synopsis
    Report Back M365 Update Channel
.EXAMPLE
    Run via automation on individual machines or run locally
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>

$RegChannel = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name "CDNBaseUrl"
If ($Reg.CDNBaseUrl -eq "http://officecdn.microsoft.com/pr/55336b82-a18d-4dd6-b5f6-9e5095c314a6"){
    $Channel = "Monthly Enterprise Channel"
}
Elseif ($Reg.CDNBaseUrl -eq "http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60"){
    $Channel = "Current Channel"
}
Elseif ($Reg.CDNBaseUrl -eq "http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be"){
    $Channel = "Current   Channel (Preview)"
}
Elseif ($Reg.CDNBaseUrl -eq "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"){
    $Channel = "Semi-Annual Enterprise Channel"
}
Elseif ($Reg.CDNBaseUrl -eq "http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf"){
    $Channel = "Semi-Annual   Enterprise Channel (Preview)"
}
Elseif ($Reg.CDNBaseUrl -eq "http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f"){
    $Channel = "Beta Channel"
}
return $Channel
$Version = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name "ClientVersionToReport"
return $Version
