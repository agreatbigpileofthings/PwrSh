<#
.Synopsis
    Update Department Field in AD
.DESCRIPTION
    Based on a pre-configured list, update department field in AD. Need to grab UserPrincipalName from AD and compile list first.
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>

Import-Csv -Path 'FILE.csv' | ForEach-Object {
    $userPrincipalName = $_.UserPrincipalName
    $newDepartment = $_.Department

    $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$userPrincipalName'" -Properties Department

    if ($adUser) {
        Set-ADUser -Identity $adUser.DistinguishedName -Department $newDepartment
        Write-Host "Will update $userPrincipalName to Department '$newDepartment'"
    } else {
        Write-Warning "User $userPrincipalName not found in AD."
    }
}
