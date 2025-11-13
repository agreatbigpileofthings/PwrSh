function Copy-MECMLogs{
<#
.Synopsis
    Search error codes in MECM logs
.DESCRIPTION
    Search MECM logs for error code and copy log file to local machine
.EXAMPLE
    Copy-MECMLogs -Computer "MACHINENAME" -ErrorCode "ERRORCODE"
.AUTHOR
    Ryan Martin | agreatbigpileofthings.com
#>
    param($Computer , $ErrorCode)

    $ParentPath ="\\$Computer\C$\Windows\CCM\Logs"
    $Outfile = $Computer + "_Error_"+$ErrorCode+".txt"
    $LogFiles = Get-ChildItem -path $ParentPath -filter "*.log" -recurse
    $LogOutputPath = "C:\temp\MECM Error Logs\"+$Computer

    foreach ($file in $LogFiles){
        #write-host "Checking $file for $errorcode"
        $Search = Get-Content -path "$ParentPath\$file" | ? { ($_ | Select-String $ErrorCode)} 
        if($Search){
            write-host "<<<<<<< Found $errorcode in $file >>>>>>>" -ForegroundColor Green | Out-file -FilePath "$FilePath\$Outfile" -Append
            New-Item -ItemType Directory -Force -Path $LogOutputPath
            Copy-Item -path "$ParentPath\$file" -Destination $LogOutputPath -Verbose
        } Else {
            write-host "$errorcode not found in $file" -ForegroundColor Gray
            }
    }
}
