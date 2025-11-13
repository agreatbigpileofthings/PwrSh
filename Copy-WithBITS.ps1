<#
.Synopsis
   Use BITS to copy and monitor large transfers
.DESCRIPTION
   Connect to a non-domain joined machine, copy files from server A to server B
.EXAMPLE
   .\Copy-BITS.ps1  -Repo <path to server A> -Server <path to server B> -Log <path to log> -AESKey <path to AES key> -JSONKey <path to JSON key>
   .\Copy-BITS.ps1 -Repo "\\192.168.X.X\share" -Server "\\192.168.X.X\share" -Log "C:\temp" -AESKey "C:\temp\Scripts\Keys\aeskey.bin" -JSONKey "C:\temp\Scripts\keys\jsonkey.json"
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com   
#>

param(
    [parameter(Mandatory=$true)]
        [string]$Server,
    [parameter(Mandatory=$true)]
        [string]$Repo,
    [parameter(Mandatory=$true)]
        [string]$Log,
    [parameter(Mandatory=$true)]
        [string]$AESKey,
    [parameter(Mandatory=$true)]
        [string]$JSONKey

)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info",
        [string]$LogFile = "$LogPath\PPCopy-$(Get-Date -format yyyy-MM-dd).log"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry -Force

}

$key = Get-Content $AESKey -Encoding Byte
$j = Get-Content $JSONKey | ConvertFrom-Json
$securePwd = $j.EncryptedPassword | ConvertTo-SecureString -Key $key
$cred = New-Object System.Management.Automation.PSCredential ($j.User, $securePwd)

New-PSDrive  -Name "CopyDrive" -PSProvider FileSystem -Root "$($Server)" -Credential $cred 

$Storagebox = Get-ChildItem -Path $Server -Directory | Select-Object Name, FullName       
$Repository = Get-ChildItem -Path $Repo -Recurse | Sort-Object -Property LastWriteTime | Select-Object Name, FullName, LastWriteTime
$LogPath = $Log

Write-Log -Message "Initializing | Finding Files in Repository"
foreach($file in $Repository){
    if($file.LastWriteTime -ge (Get-date).AddDays(-1)){
        Write-Log -Message "Found $($file.Name)"
        $BKFile = $file.Name.Split(".")[0]
        if($Storagebox -eq $null){
            if(Test-Path "$($Server)\$BKFile"){
                Write-Log -Message "$($Server)\$BKFile exists"
            }
            Else {
                Write-Log -Message "Creating directory: $($Server)\$BKFile"
                New-Item "$($Server)\$BKFile" -ItemType Directory -Force
                $Storagebox = Get-ChildItem -Path $Server -Directory | Select-Object Name, FullName   
            }
        }
        foreach($share in $Storagebox){
            Write-Log -Message "Acting on $($share.Name)"
           $BKShare = $share.Name.Split("\")[0]
            $LegacyFiles = Get-ChildItem -Path $share.FullName
                foreach($oldfile in $LegacyFiles){                    
                    if($oldfile.LastWriteTime -lt $(Get-Date).AddDays(-2)){
                        Write-Log -Message "Removing last copy's files from $($BKShare)"
                        $LegacyFiles | Remove-Item
                    } 
                    Else {
                        Write-Log "No files found to clean up in $($BKShare)"
                    }
                }
            if($BKFile -match $BKShare){
                Write-Log -Message "Acting on $BKFile"                
                $Job = Start-BitsTransfer -Source $file.FullName -Destination $Share.FullName -Asynchronous
                while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) {
                    Start-Sleep -Seconds 15
                    Write-Log -Message "BITS Job $($Job.JobId) Status: $($Job.JobState) Progress: $([math]::Round($Job.BytesTransferred / 1GB, 2)) GB / $([math]::Round($Job.BytesTotal / 1GB, 2)) GB"
                }
                Switch($Job.JobState) {
                    "Transferred"   { Write-Log -Message "BITS Job $($Job.JobId) is complete."; Complete-BitsTransfer -BitsJob $Job }
                    "Error"         { Write-Log -Message "BITS Job $($Job.JobId) errored out with: $($Job.Description)" }
                    "Suspended"     { Write-Log -Message "BITS Job $($Job.JobId) is suspended. Resuming..."; Resume-BitsTransfer -BitsJob $Job -Asynchronous}
                    "Cancelled"     { Write-Log -Message "BITS Job $($Job.JobId) was cancelled." }
                    "TransientError"{ Write-Log -Message "BITS Job $($Job.JobId) hit a transient error. Retrying..."; Resume-BitsTransfer -BitsJob $Job -Asynchronous  }
                    default         { Write-Log -Message "BITS Job $($Job.JobId) ended with unexpected state: $($Job.JobState)" }
                }
                } 
            }
        } 
    Else {
        Write-Log -Message "No recent files found on $($Repo)"
    }
}
Write-Log -Message "Removing Mapped Drive"
Remove-PSDrive -Name "CopyDrive" -PSProvider FileSystem -Force
Write-Log -Message "Done!"
