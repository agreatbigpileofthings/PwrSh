<#
.DESCRIPTION
   Find and delete nested files
   ! RUN WITH POWERSHELL 7 !
.EXAMPLE
   SearchAndDestroy-File -folderPath "X:\folderpath" -fileName "File Name.ext"

#>

function SearchAndDestroy-File {
param(
    [string]$folderPath,
    [string]$fileName
)
New-PSDrive "F" -PSProvider FileSystem -Root "$($folderPath)"
$files = Get-ChildItem -LiteralPath "F:\" -File "$($fileName)" -Recurse
foreach($file in $files){
    Remove-Item $file -Force -Verbose
}
Remove-PSDrive "F"
}
