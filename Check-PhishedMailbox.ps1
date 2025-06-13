<#
.Synopsis
    Cmdlets to verify items that often indicate a compromised mailbox
.DESCRIPTION
    I got these liners from MSFT. Just compiled them here. https://learn.microsoft.com/en-us/defender-office-365/responding-to-a-compromised-email-account
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>


### Install-Module -Name ExchangeOnlineManagement -RequiredVersion 3.6.0 -Force

Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName <#Enter UPN#>
Get-Mailbox -Identity <#identity#> | Format-List Forwarding*Address,DeliverTo*
Get-InboxRule -Mailbox <#identity#> -IncludeHidden | Format-List Name,Enabled,RedirectTo,Forward*,Identity
