### Pull ALL GPO Reports for upload to Intune
Get-GPO -All | ForEach-Object {
    Get-GPOReport -Name $_.DisplayName -ReportType Xml -Path "C:\temp\GPOReports\$($_.DisplayName).xml"
}
