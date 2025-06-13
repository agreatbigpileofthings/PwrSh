<#
.Synopsis
    Delete AD computer objects from a .csv
.EXAMPLE
    Run locally
#>

$PCs = Import-Csv "PATH\FILE.csv" | Select -ExpandProperty ObjectGUID
$StartCount = 0
$TotalCount = $PCs.Count
foreach ($PC in $PCs){
    if(Get-ADComputer -Identity $PC -ErrorAction SilentlyContinue){
        $StartCount += 1
        Write-Progress -Activity "Processing record $StartCount of $TotalCount : $PC" -Status "Progress:" -PercentComplete (($StartCount / $TotalCount) * 100)
        Remove-ADObject -Identity $PC -Recursive -Confirm:$false -ErrorAction SilentlyContinue
    }
}
