<#
.Synopsis
   Get Office 365 Version
.DESCRIPTION
   Get Office 365 version on local PC
.EXAMPLE
   Run locally against remote machine
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>


$PCs = Get-ADComputer -Filter 'Name -like "*"' -Properties * | Where-object {($_.OperatingSystem -NotLike "*Server*") -and ($_.OperatingSystem -NotLike $null)} | Select-Object CN
Foreach ($PC in $PCs){
    Write-host "Getting Office Info on $($PC.CN)"
    Invoke-Command -ComputerName $PC.CN -ScriptBlock {
        $OfficeProperties =   Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name VersionToReport, ProductReleaseIDs | select-object VersionToReport, ProductReleaseIds
        $Export = [pscustomobject]@{
            ComputerName = $PC.CN
            Version = $OfficeProperties.VersionToReport
            Products = $OfficeProperties.ProductReleaseIDs
        }

        $Export | Export-csv -Path "\\PATH\OfficeVersions.csv"

    }
}
