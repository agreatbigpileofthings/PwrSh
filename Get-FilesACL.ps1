<#
.Synopsis
    Get File ACL in Folder
.DESCRIPTION
    Get file permission specifics for each file in a folder
.EXAMPLE
    Run manually/ No Automation
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>

$FolderPath = "FOLDERPATH"
$Folders = Get-ChildItem -Path $FolderPath -Depth 1 -Recurse -Force
$Output = @()

foreach ($Folder in $Folders) {
    $Acl = Get-Acl -Path $Folder.FullName
    foreach ($Access in $Acl.Access) {
        $Properties = [ordered]@{
            "Folder Name" = $Folder.FullName
            "Group/User" = $Access.IdentityReference
            "Permissions" = $Access.FileSystemRights
            "Inherited" = $Access.IsInherited
        }

        $Output += New-Object -TypeName PSObject -Property $Properties
    }
}
$Output | Export-Csv -Path "C:\temp\PermissionsReport_SRecurse.csv" -NoTypeInformation
