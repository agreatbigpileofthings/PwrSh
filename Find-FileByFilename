<# Lost file? find it quick if you know the name and general location! #>

param (
    [string]$folderPath = "FOLDERPATH",
    [string]$fileName = "FILENAME"  # Change to your target file name
)

# Validate the folder path
if (-not (Test-Path $folderPath)) {
    Write-Host "The path $folderPath does not exist." -ForegroundColor Red
    return
}

# Use .NET's fast file enumeration
try {
    $matchingFiles = [System.IO.Directory]::EnumerateFiles($folderPath, "*", [System.IO.SearchOption]::AllDirectories) |
        Where-Object { [System.IO.Path]::GetFileName($_) -ieq $fileName }

    if ($matchingFiles) {
        Write-Host "Found:" -ForegroundColor Green
        $matchingFiles
    } else {
        Write-Host "No file named '$fileName' was found in $folderPath." -ForegroundColor Yellow
    }
} catch {
    Write-Host "An error occurred during search: $_" -ForegroundColor Red
}
