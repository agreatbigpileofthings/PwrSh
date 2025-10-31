function Get-FolderProperties {
<#
.DESCRIPTION
  Grab folder permissions for folders in parent directory
   
.EXAMPLE
   Get-FolderProperties -FolderPath <path to folder> -Depth 1 -OutputPath <path to dump output csv>

#>
param(
    [parameter(Mandatory=$true)]
    [string]$FolderPath,
    [parameter(Mandatory=$true)]
    [int]$Depth,
    [parameter(Mandatory=$true)]
    [string]$OutputPath    
)

$Folders = Get-ChildItem -Path $FolderPath -Depth $Depth -Recurse -Force
$OutputData = @()
foreach ($Folder in $Folders) {
    $Acl = Get-Acl -Path $Folder.FullName
    foreach ($Access in $Acl.Access) {
        $Properties = [ordered]@{
            "Folder Name" = $Folder.FullName
            "Group/User" = $Access.IdentityReference
            "Permissions" = $Access.FileSystemRights
            "Inherited" = $Access.IsInherited
        }
        $OutputData += New-Object -TypeName PSObject -Property $Properties
    }
}
$OutputData | Export-Csv -Path "$($OutputPath)\FolderPermissionsExport-$(Get-Date -format yyyy-MM-dd).csv" -NoTypeInformation
}
