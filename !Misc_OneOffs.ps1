### Pull ALL GPO Reports for upload to Intune
Get-GPO -All | ForEach-Object {
    Get-GPOReport -Name $_.DisplayName -ReportType Xml -Path "C:\GPOReports\$($_.DisplayName).xml"
}
