<#
.Synopsis
   Delete Files\Folders in a Network Share Older Than 30 Days
.DESCRIPTION
   Delete Files\Folders in a Network Share Older Than 30 Days
.EXAMPLE
   Run locally or deploy task scheduler
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>

   function Write-Log {
        param(
            [string]$Message,
            [string]$Level = "Info",
            [string]$LogFile = "\\Path\FileDeletionLog - $(Get-Date -format yyyy-MM-dd).log"
        )
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogEntry = "$Timestamp [$Level] $Message"
        Add-Content -Path $LogFile -Value $LogEntry -Force

    }

###$folderpath = "c:\temp"
$folderpath = "\\SHARE\"

$exclusions = @(
    <#enter exclusion paths here. example: \\share\folder or \\share\folder\file #>
)

# Normalize all exclusion paths for consistent comparison
$exclusions = $exclusions | ForEach-Object { $_.ToLower() }

$files = Get-ChildItem -Path $folderpath -Recurse -Force | Where-Object {
    $currentPath = $_.FullName.ToLower()
    # Exclude any items whose path starts with or equals any exclusion
    -not ($exclusions | Where-Object { $currentPath -like "$_*" })
}

foreach($file in $files){
    If ($file.LastWriteTime -lt (Get-Date).AddDays(-30)){
        Remove-Item $file.FullName  -Recurse -WhatIf ### Remove -WhatIF when ready to deploy
        Write-Host $file
        Start-Sleep -Seconds 1 
        $output = "Deleting file: " + $file.FullName
        Write-Log -Message $output  
    }
}


$folders = Get-ChildItem -Path $folderpath -Force -Recurse -Directory| Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -File | Measure-Object).Count -eq 0 }
foreach($folder in $folders){
    Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue -WhatIf ### Remove -WhatIF when ready to deploy
    Start-Sleep -Seconds 1 
    $output = "deleting folder: " + $folder.FullName
    Write-Log -Message $output
}

