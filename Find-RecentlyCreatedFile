# Parameters
$folderPath = "FOLDERPATH"
$topCount = 10

# Validate path
if (-Not (Test-Path $folderPath)) {
    Write-Host "The path $folderPath does not exist or is not accessible." -ForegroundColor Red
    return
}

# Create a priority queue-like list
$recentFiles = @()

# Use .NET for faster directory traversal
Add-Type -AssemblyName System.IO
$files = [System.IO.Directory]::EnumerateFiles($folderPath, '*', [System.IO.SearchOption]::AllDirectories)

foreach ($file in $files) {
    try {
        $fileInfo = Get-Item -LiteralPath $file -ErrorAction Stop
        if ($recentFiles.Count -lt $topCount) {
            $recentFiles += $fileInfo
        } else {
            # Find the oldest in the list
            $oldest = $recentFiles | Sort-Object LastWriteTime | Select-Object -First 1
            if ($fileInfo.LastWriteTime -gt $oldest.LastWriteTime) {
                $recentFiles = $recentFiles | Where-Object { $_.FullName -ne $oldest.FullName }
                $recentFiles += $fileInfo
            }
        }
    } catch {
        # Skip files that throw errors (e.g., permission issues)
    }
}

# Final sort of the top results
$recentFiles = $recentFiles | Sort-Object LastWriteTime -Descending

# Output result
$recentFiles | Select-Object Name, Directory, LastWriteTime | Format-Table -AutoSize
