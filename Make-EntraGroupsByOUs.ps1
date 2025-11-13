<#
.DESCRIPTION
   Make Entra groups based on on-prem OUs
.EXAMPLE
   Just Run It
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>

Connect-MgGraph -Scopes "Group.ReadWrite.All"

$BadOUs = @(
    <# enter in OUs to ignore here #>
)

$OUNames = Get-ADOrganizationalUnit -filter * -SearchScope OneLevel | Where-Object Name -NotIn $BadOUs | Select-Object Name 
foreach($OU in $OUNames){
    $OUNameNoSpace = $OU.Name.Replace(" ","")
    write-host "Creating Group $($OU.Name) in M365"
    $parameters = @{
        GroupTypes = @('DynamicMembership')
        Description = "$($OU.Name) Users"
        DisplayName = "Groups - $($OU.Name)"
        MailEnabled = $false
        SecurityEnabled = $true
        MailNickname = "$OUNameNoSpace"
        MembershipRuleProcessingState = "On"
        MembershipRule = "(user.extensionAttribute1 -eq `"$($OU.Name)`")"
        "Owners@odata.bind" = @("https://graph.microsoft.com/v1.0/me")

        }
     Try{
        New-MgGroup -BodyParameter $parameters
    }
    Catch {
        Write-Host "Failed to create group for $($OU.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}
Disconnect-MgGraph
