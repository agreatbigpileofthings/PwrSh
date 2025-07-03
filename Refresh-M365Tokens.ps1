<#
.Synopsis
   Puruse through M365 users and reset M365 Tokens
.DESCRIPTION
   Using a registered app, reset M365 tokens for all included users in tenant.
.EXAMPLE
   Run this manually or via task scheduler
#>

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info",
        [string]$LogFile = "C:\Scripts\Logs\RevokeAllSessions - $(Get-Date -Format yyyy-MM-dd).log"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry -Force
}

Write-Log -Message "Importing Microsoft Graph modules"

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop

Write-Log -Message "Modules imported successfully"

Write-Log -Message "Loading encrypted client secret and AES key"

# Load encryption key and encrypted secret
$keyPath = <#path to .key file #>
$secretPath = <# path to secret key file #>

$key = [System.IO.File]::ReadAllBytes($keyPath)
$encSecret = Get-Content -Path $secretPath -Raw
$secureSecret = $encSecret | ConvertTo-SecureString -Key $key

# Set AppId and TenantId
$appId = <# enter appID here in double quotes#>
$tenantId = <# enter tenantID here in double quotes#>

Write-Log -Message "Connecting to Microsoft Graph using ClientSecretCredential"

# Construct PSCredential from App ID and secure secret
$clientSecretCredential = [PSCredential]::new($appId, $secureSecret)

# Connect with App-only authentication
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $clientSecretCredential

Write-Log -Message "Connection to Microsoft Graph successful"

# Define accounts to exclude
$ExcludeAccts = @( <#enter accounts here#> )

Write-Log -Message "Retrieving users from Microsoft Graph"

# Get all users, excluding the accounts listed above
$allUsers = Get-MgUser -All | Where-Object { $ExcludeAccts -notcontains $_.UserPrincipalName }

foreach ($user in $allUsers) {
    Write-Log -Message "Revoking sessions for $($user.UserPrincipalName) (ID: $($user.Id))"
    try {
        # Uncomment the line below once your app has the proper delegated or application permissions
        Revoke-MgUserSignInSession -UserId $user.Id

        Write-Log -Message "Revoked sessions successfully for $($user.UserPrincipalName)"
    }
    catch {
        Write-Log -Message "Failed to revoke sessions for $($user.UserPrincipalName): $_" -Level "Error"
    }
}

Write-Log -Message "All users processed"
