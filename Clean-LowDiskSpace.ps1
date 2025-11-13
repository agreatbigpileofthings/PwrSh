<#
.Synopsis
    Cleanup PCs with low disk space
.DESCRIPTION
    Cleanup PCs that may be low on disk space by several means: 
    1. Cleanup Stale Profiles 90 days old | 2. Cleanup Recycling Bin | 3. Clean up Temp locations
.EXAMPLE
    Run Locally or via automation like MECM on individual machines
.AUTHOR
Ryan Martin | agreatbigpileofthings.com

#>

##### Clean up stale profiles #####
function WriteLog
{
    Param ([string]$LogString)
    $LogFile = "$env:windir\Logs\Software\$env:COMPUTERNAME Disk Space Cleanup $(get-date -f yyyyMMddHHmm).log"
    $DateTime = "[{0:MM/dd/yy}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $LogFile -value $LogMessage
}
$BeforeClean = get-PSDrive C | Select-object @{E={$_.Free/1GB}}
WriteLog -LogString  "Low Free Disk = $($BeforeClean.'$_.Free/1GB')"
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
    WriteLog -LogString   "$($ProfileInfo.ProfilePath) : Profile unload time = $DateTime" 
#Ignore Autologon
    If($ProfileInfo.ProfilePath -contains $env:COMPUTERNAME){
        WriteLog -LogString  "$($ProfileInfo.ProfilePath) is an AUTOLOGON account  " 
    }
#Remove is Reg DateTime indicates stale
    ElseIf ($DateTime -lt $StaleDate -and $DateTime -ne $Null){
        WriteLog -LogString  "Removing Profile $($ProfileInfo.ProfilePath) based on unload time $DateTime  " 
        Try{
            $Stale = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID)
            $Stale | Remove-wmiobject
        }
        Catch {
            WriteLog -LogString  "Error removing Profile: $ProfileInfo.ProfilePath" 
            WriteLog -LogString  $Error[0]
        }
    }
#After IPU RegTime was not reapplied in reg if profile was stale. Keying off of WMI.
    Elseif($DateTime -eq $Null){
       $WMIInfo = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID) | Select-object sid, localpath, @{Label='LastUseTime';Expression={$_.ConvertToDateTime($_.LastUseTime)}}
       WriteLog -LogString  "$($ProfileInfo.ProfilePath) : WMI LastUseTime = $($WMIInfo.LastUseTime)" 

       Try{
           if($WMIInfo.LastUseTime -lt $StaleDate -and $WMIInfo.LastUseTime -ne $Null ){
               WriteLog -LogString  "Removing profile $($ProfileInfo.ProfilePath) based on WMI time : $($WMIInfo.LastUseTime)" 
            $Stale = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID)
            $Stale | Remove-wmiobject
           }
#WMITime for all profiles gets updated after updates/installs. Keying off browser cache.
           Elseif ($WMIInfo.LastUseTime -ge $StaleDate -or $WMIInfo.LastUseTime -eq $Null){
               WriteLog -LogString  "$($ProfileInfo.ProfilePath) : Final Check: Keying off of browser cache" 
               $EdgePath = Join-path -Path $($WMIInfo.Localpath)  -ChildPath "\AppData\Local\Microsoft\Edge\User Data\Default\Cache\Cache_Data"
               $ChromePath = Join-path -Path $($WMIInfo.Localpath)  -ChildPath "\AppData\Local\Google\Chrome\User Data\Default\Cache\Cache_Data"
               if(Test-path $EdgePath){
                   $EdgeTime = Get-Item -Path $EdgePath | Select-Object LastWriteTime
                   WriteLog -LogString  "$($ProfileInfo.ProfilePath) : Edge Cache Time = '$($EdgeTime.LastWriteTime)'"    
                }
                Else {
                    WriteLog -LogString  "$($ProfileInfo.ProfilePath) : No cache for Edge" 
                } 
                if(Test-path $ChromePath){
                   $ChromeTime = Get-Item -Path $ChromePath | Select-object LastWriteTimeUtc
                   WriteLog -LogString  "$($ProfileInfo.ProfilePath) : Chrome Cache Time = $($ChromeTime.LastWriteTime)" 
                }
                Else {
                    WriteLog -LogString  "$($ProfileInfo.ProfilePath) : No cache for Chrome" 
                }   
                If($EdgeTime.LastWriteTime -lt $StaleDate -and $ChromeTime.LastWriteTime -lt $StaleDate){
                   WriteLog -LogString  "Removing $($ProfileInfo.ProfilePath) based on user's browser cache" 
                   $Stale = Get-wmiobject win32_userprofile | ? sid -eq $($ProfileInfo.SID)
                   $Stale | Remove-wmiobject
                }
                Else {
                    WriteLog -LogString  "DEBUG FLAG: Profile = $($ProfileInfo.ProfilePath) | Edge Cache Time = '$($EdgeTime.LastWriteTime)' | Chrome Cache Time = '$($ChromeTime.LastWriteTime)'" 
                }
            }
            Else {
               WriteLog -LogString  "WARNING: $($ProfileInfo.ProfilePath) has no valid timestamp to key off of!" 
            }
        }
        Catch {
           WriteLog -LogString  "$($ProfileInfo.ProfilePath) : Error removing Profile" 
           WriteLog -LogString  $Error[0]
        } 
    }
    Else { 
        WriteLog -LogString  "$($ProfileInfo.ProfilePath) is not stale." 
    }
    WriteLog -LogString  "End for $($ProfileInfo.ProfilePath)" 
#Reset Dynamic Variables
    $ProfileInfo = @{}
    $EdgeTime = $Null
    $EdgePath = $Null
    $ChromeTime = $Null
    $ChromePath = $Null
    $Stale = $Null

}

##### Clean Recycling Bin & Temp Files #####

#Clean Recycling Bin
$Path = 'C' + ':\$Recycle.Bin' ####check for new variable
WriteLog -LogString  "Cleaning Recycling Bin"
Get-ChildItem $Path -Force -Recurse -ErrorAction SilentlyContinue |
Remove-Item -Recurse -Exclude *.ini -ErrorAction SilentlyContinue

#Clean Temps
WriteLog -LogString  "Erasing temporary files from various locations"
$Path1 = "$env:windir\temp"
$Path2 = "$env:windir\Prefetch"
WriteLog -LogString  "Remove all items (files and directories) from the Windows Temp folder"
Get-ChildItem $Path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue  
WriteLog -LogString  "Remove all items (files and directories) from the Windows Prefetch folder"
Get-ChildItem $Path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue  
WriteLog -LogString  "Running Cleanmgr /verylowdisk"
cleanmgr /verylowdisk
WriteLog -LogString  "Running Cleanmgr /autoclean"
cleanmgr /autoclean 
WriteLog -LogString  "Complete!"

$AfterClean = get-PSDrive C | Select-object @{E={$_.Free/1GB}}
WriteLog -LogString  "Low Free Disk = $($AfterClean.'$_.Free/1GB')"
$FreedSpace = $AfterClean.'$_.Free/1GB' - $BeforeClean.'$_.Free/1GB'

WriteLog -LogString  "Completed! | Cleaned Space = $FreedSpace"
