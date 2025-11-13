<#
.Synopsis
    Delete stale profiles on machines that are inactive for 90 days
.DESCRIPTION
    Delete stale profiles hogging up space on machines based on several factors:
    1. Reg load/unload timestamps | 2. WMI | 3. Browser cache data
.EXAMPLE
    Deploy by automation to run on individual machines
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com    
#>

function WriteLog
{
    Param ([string]$LogString)
    $LogFile = "C:\temp\ProfileLog\$env:COMPUTERNAME $(get-date -f yyyyMMddHHmm).log"
    $DateTime = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $LogFile -value $LogMessage
}

$StaleDate = [datetime]::Today.AddDays(('-90'))
$ProfilePath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
$Profiles = Get-ChildItem $ProfilePath -Recurse | ? {$_.GetValue('ProfileImagePath') -notlike 'c:\windows*'}  # ! Filter out system profiles ! DO NOT REMOVE !
foreach($Profile in $Profiles){
    $ProfileInfo = @{
        SID = $Profile.Name.replace("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\","")
        LoadTimeLow = $Profile.GetValue('LocalProfileLoadTimeLow')
        LoadTimeHigh = $Profile.GetValue('LocalProfileLoadTimeHigh')
        ProfilePath = $Profile.GetValue('ProfileImagePath').replace("C:\Users\","")
        }
        
#Convert Reg DateTime to readable
    $UnloadTimeHigh = "{0:x}" -f $ProfileInfo.LoadTimeHigh
      $UnloadTimeLow = "{0:x}" -f $ProfileInfo.LoadTimeLow
      If ($UnloadTimeHigh -ne "$Null" -and $UnloadTimeLow -ne "$Null") {
      $Work = nltest /time:$UnloadTimeLow $UnloadTimeHigh
      [DateTime]$DateTime=($work.split("=")[1])
    }
    WriteLog  "$($ProfileInfo.ProfilePath) : Profile unload time = $DateTime" 

#Ignore Autologon
    If($ProfileInfo.ProfilePath -contains $env:COMPUTERNAME){
        WriteLog "$($ProfileInfo.ProfilePath) is an AUTOLOGON account  " 
    }

#Remove is Reg DateTime indicates stale
    ElseIf ($DateTime -lt $StaleDate -and $DateTime -ne $Null){
        WriteLog "Removing Profile $($ProfileInfo.ProfilePath) based on unload time $DateTime  " 
        Try{
            $Stale = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID)
            $Stale | Remove-wmiobject
        }
        Catch {
            WriteLog "Error removing Profile: $ProfileInfo.ProfilePath" 
            WriteLog $Error[0]
        }
    }
#After IPU RegTime was not reapplied in reg if profile was stale. Keying off of WMI.
    Elseif($DateTime -eq $Null){
       $WMIInfo = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID) | Select-object sid, localpath, @{Label='LastUseTime';Expression={$_.ConvertToDateTime($_.LastUseTime)}}
       WriteLog "$($ProfileInfo.ProfilePath) : WMI LastUseTime = $($WMIInfo.LastUseTime)" 

       Try{
           if($WMIInfo.LastUseTime -lt $StaleDate -and $WMIInfo.LastUseTime -ne $Null ){
               WriteLog "Removing profile $($ProfileInfo.ProfilePath) based on WMI time : $($WMIInfo.LastUseTime)" 
            $Stale = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID)
            $Stale | Remove-wmiobject
           }

#WMITime for all profiles gets updated after updates/installs. Keying off browser cache.
           Elseif ($WMIInfo.LastUseTime -ge $StaleDate -or $WMIInfo.LastUseTime -eq $Null){
               WriteLog "$($ProfileInfo.ProfilePath) : Final Check: Keying off of browser cache" 
               $EdgePath = Join-path -Path $($WMIInfo.Localpath)  -ChildPath "\AppData\Local\Microsoft\Edge\User Data\Default\Cache\Cache_Data"
               $ChromePath = Join-path -Path $($WMIInfo.Localpath)  -ChildPath "\AppData\Local\Google\Chrome\User Data\Default\Cache\Cache_Data"
               if(Test-path $EdgePath){
                   $EdgeTime = Get-Item -Path $EdgePath | Select-Object LastWriteTime
                   WriteLog "$($ProfileInfo.ProfilePath) : Edge Cache Time = '$($EdgeTime.LastWriteTime)'"    
                }
                Else {
                    WriteLog "$($ProfileInfo.ProfilePath) : No cache for Edge" 
                } 
                if(Test-path $ChromePath){
                   $ChromeTime = Get-Item -Path $ChromePath | Select-object LastWriteTimeUtc
                   WriteLog "$($ProfileInfo.ProfilePath) : Chrome Cache Time = $($ChromeTime.LastWriteTime)" 
                }
                Else {
                    WriteLog "$($ProfileInfo.ProfilePath) : No cache for Chrome" 
                }   
                If($EdgeTime.LastWriteTime -lt $StaleDate -and $ChromeTime.LastWriteTime -lt $StaleDate){
                   WriteLog "Removing $($ProfileInfo.ProfilePath) based on user's browser cache" 
                   $Stale = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID)
                   $Stale | Remove-wmiobject
                }
                Else {
                    WriteLog "DEBUG FLAG: Profile = $($ProfileInfo.ProfilePath) | Edge Cache Time = '$($EdgeTime.LastWriteTime)' | Chrome Cache Time = '$($ChromeTime.LastWriteTime)'" 
                }
            }
            Else {
               WriteLog "WARNING: $($ProfileInfo.ProfilePath) has no valid timestamp to key off of!" 
            }
        }
        Catch {
           WriteLog "$($ProfileInfo.ProfilePath) : Error removing Profile" 
           WriteLog $Error[0]
        } 
    }
    Else { 
        WriteLog "$($ProfileInfo.ProfilePath) is not stale." 
    }
    WriteLog "End for $($ProfileInfo.ProfilePath)" 
#Reset Dynamic Variables
    $ProfileInfo = @{}
    $EdgeTime = $Null
    $EdgePath = $Null
    $ChromeTime = $Null
    $ChromePath = $Null
    $Stale = $Null

}
