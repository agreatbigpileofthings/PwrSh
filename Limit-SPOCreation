<#
.Synopsis
   Lockdown who can create SharePoint groups
.DESCRIPTION
   This was originally provided by Microsoft: https://learn.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide
.EXAMPLE
   Run locally
#>

Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Beta.Groups

Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Group.Read.All"

$GroupName = "GROUPNAME"  # Set a valid group name
$AllowGroupCreation = $false  # Boolean value (not string)

# Fetch the settings object ID
$settingsObjectID = (Get-MgBetaDirectorySetting | Where-Object {$_.Displayname -eq "Group.Unified"}).Id

# If settings object is not found, create one
if(!$settingsObjectID) {
    $params = @{
        templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
        values = @(
            @{
                name = "EnableMSStandardBlockedWords"
                value = "true"
            }
        )
    }
    
    New-MgBetaDirectorySetting -BodyParameter $params
    
    # Fetch the settings object ID again after creation
    $settingsObjectID = (Get-MgBetaDirectorySetting | Where-Object {$_.Displayname -eq "Group.Unified"}).Id
}

# Fetch the Group ID
$groupId = (Get-MgBetaGroup | Where-Object {$_.Displayname -eq $GroupName}).Id

# Define parameters for updating settings
$params = @{
    templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
    values = @(
        @{
            name = "EnableGroupCreation"
            value = $AllowGroupCreation
        },
        @{
            name = "GroupCreationAllowedGroupId"
            value = $groupId
        }
    )
}

# Update the directory setting
Update-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID -BodyParameter $params

# Output the updated settings values
(Get-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID).Values
