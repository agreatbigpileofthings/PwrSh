<#
.Synopsis
   Swap M365 Licensing from Biz Standard to Biz Prem
.DESCRIPTION
   Find all users with Biz Standard licensing, apply biz prem license and remove biz standard license.
.EXAMPLE
   Run locally as admin
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com   
#>

#region Handle Modules

#install-Module microsoft.graph
Import-Module Microsoft.Graph

#endregion

Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All

$AddSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'
$RemoveSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'O365_BUSINESS_STANDARD'

#region Find Users

$AllUsers = Get-MgUser -All | Select-object Id, Mail
$FullList =@()
foreach($user in $AllUsers){
    $License = Get-MgUserLicenseDetail -UserId $user.Id
    $Properties = [pscustomobject]@{
        UPN = $user.Mail
        UPID = $user.Id
        SkuID = $License.SkuId
        SkuPartNo = $License.SkuPartNumber
    }
    $FullList += $Properties
}
$FinalList = $FullList | Where-Object SkuPartNo -eq 'O365_BUSINESS_STANDARD'

#endregion

#region Apply License Change

Foreach($item in $FinalList){
Set-MgUserLicense -UserId $item.UPID -AddLicenses @{SkuId = $AddSku.SkuId} -whatif
Set-MgUserLicense -UserId $item.UPID -RemoveLicenses @{SkuId = $Sku.SkuId} -whatif
}

#endregion
