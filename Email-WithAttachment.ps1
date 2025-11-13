<#
.Synopsis
    Email Newly Created Users an Attachment
.DESCRIPTION
    Grab newly created users from MsGraph and send them an email containing an attachment
.EXAMPLE
    Run via scheduled task. ! Use PowerShell 7 !
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
.NOTES
    Version 1.0 | 11/13/2025

#>

#region Import Modules Declare Variables and Functions
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop

#Email Configs
$EmailFrom = "<enter sender email address>"
$Subject = "<enter subject>"
$Body = "<enter body>"
$AttachmentPath = "<enter path to file>" 
$SmtpServer = "<enter SMTP server>"

#Email Creds
$UserName = Get-Content "<path to encrypted username>"
$EncryptedPassword = Get-Content "<path to encrepted password>"
$key = Get-Content "<path to encryption key>"
$SecurePassword = ConvertTo-SecureString $EncryptedPassword -Key $key
$Cred = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)

#Tenant & App Ids
$appId = "<enter app registration ID"
$tenantId = "<enter tenant ID>"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info",
        [string]$LogFile = "C:\Scripts\Logs\Email.log"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry -Force
}
#endregion

#region Connecting to Microsoft Graph
Write-Log -Message "Loading encrypted client secret and AES key"
$keyPath = "<enter path to AES key>"
$secretPath = "<enter path to secret>"
$key = [System.IO.File]::ReadAllBytes($keyPath)
$encSecret = Get-Content -Path $secretPath -Raw
$secureSecret = $encSecret | ConvertTo-SecureString -Key $key

Write-Log -Message "Connecting to Microsoft Graph using ClientSecretCredential"
$clientSecretCredential = [PSCredential]::new($appId, $secureSecret)
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $clientSecretCredential
Write-Log -Message "Connection to Microsoft Graph successful"
#endregion

#region Get User | Send Email
Write-Log -Message "Getting Newly Created Users"
$Users = Get-MgUser -All -Property UserPrincipalName, CreatedDateTime | Where-Object {$_.CreatedDateTime -ge (Get-Date).AddDays(-1)} | Select-Object UserPrincipalName, CreatedDateTime
foreach ($User in $Users){
Try{
    Write-Log -Message "Found New User: $($User.UserPrincipalName)"
    Write-Log -Message "Sending Email to $($User.UserPrincipalName)"
    Send-MailMessage `
        -To $User.UserPrincipalName `
        -From $EmailFrom `
        -Subject $Subject `
        -Body $Body `
        -Attachments $AttachmentPath `
        -SmtpServer $SmtpServer `
        -Credential $Cred `
        -UseSsl
    }
    Catch {
        Write-Log -Message  "ERROR! : " $_
    }
}
#endregion
