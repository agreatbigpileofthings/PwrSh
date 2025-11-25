function Get-PasswordExpiration {
<#
.Synopsis
   Output password expiration date
.EXAMPLE
   Get-PasswordExpiration -User testuser
.Author
    Ryan Martin | agreatbigpileofthings.com
#>

    param (
        [string] $User,
        [int] $ExpirationDays = 90 ### change this value accordingly
    )

    $ADUser = Get-ADUser -Identity $User -Properties PasswordLastSet, UserPrincipalName
    $NextExpiry = (Get-Date  -Date $ADUser.PasswordLastSet).AddDays($ExpirationDays)
    $DaysUntilExpiry = (New-TimeSpan -Start (get-date) -End $NextExpiry).Days

    if($DaysUntilExpiry -ge 21) {
        Write-Host "User: $($ADUSer.UserPrincipalName) | Password Expires in $DaysUntilExpiry days on $($NextExpiry)" -ForegroundColor Green
     }
     elseif($DaysUntilExpiry -ge 7) {
        Write-Host "User: $($ADUSer.UserPrincipalName) | Password Expires in $DaysUntilExpiry days on $($NextExpiry)" -ForegroundColor Yellow
     }
    Else{
        Write-Host "User: $($ADUSer.UserPrincipalName) | Password Expires in $DaysUntilExpiry days on $($NextExpiry)" -ForegroundColor Red
    }
}
