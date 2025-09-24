$Import = Import-Csv -Path "c:\temp\org.csv"
foreach ($User in $Import){
    #region Define Variables
    $Name = $User.Name
    $JobTitle = $User.JobTitle
    $Company = $User.Company
    $Mgr = $User.Manager
    If($Mgr -notlike $null){
        $Manager = get-aduser -Filter "Name -like '$Mgr'"
    } Else {
        $Manager = $null
    }
    #endregion

    #region Apply to user
    $adUser = Get-ADUser -Filter "Name -like '$Name'" -Properties DistinguishedName, Name, Title, Department, Company, Manager
    If ($adUser) {
        If($JobTitle -notlike $null){
            write-host "Updating $($adUser.Name) : $($adUser.Title) to $JobTitle"
            Set-ADUser -Identity $adUser -title $JobTitle
        }
        If($Company -notlike $null){
            write-host "Updating $($adUser.Name) : $($adUser.Company) to $Company"
            Set-ADUser -Identity $adUser -Company $Company
        }
        If($Manager -notlike $null){
            $ManagerName = $Manager.Name
            write-host "Updating $($adUser.Name) : $ManagerName to $($Manager.Name)"
            Set-ADUser -Identity $adUser -Manager $Manager
        }

        } Else {
            Write-Warning "User $Name not found in AD."
        }
    

}
#endregion
