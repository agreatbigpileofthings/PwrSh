<#
.Synopsis
   Delete Saved Passwords from Google Chrome
.DESCRIPTION
   Delete stored password file for Google Chrome. This will clear out all saved passwords in app.
.EXAMPLE
   Run locally or deploy via MECM
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>

function Write-Log {
    param(
        [string]$Message,
        [string]$LogPath = "C:\Windows\Logs\Software\ChromePasswordsRemovalLog.txt"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogPath -Append
}

$Profiles = Get-WmiObject -Class Win32_Userprofile | ? LocalPath -NotLike "C:\Windows*" |Select-Object LocalPath -ExpandProperty LocalPath
foreach ($Profile in $Profiles){
    Write-Log "checking $Profile"
    if(Test-Path "$Profile\AppData\Local\Google\Chrome\User Data\Default\Login Data"){
        Write-log "Found in Profile $Profile"
        Write-Log "Stopping Chrome"
        Stop-Process -Name chrome -Force
        Write-Log "Removing Password File"
        Remove-Item "$Profile\AppData\Local\Google\Chrome\User Data\Default\Login Data" -Force
    }
}
