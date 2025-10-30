function Change-DateModified {
<#
.DESCRIPTION
  Change date mofdified of file to now
   
.EXAMPLE
   Change-DateModified -File <path to file>

#>
    param(
        [parameter(Mandatory=$true)]
            [string]$File
    )
    $Update = Get-Item -Path $File 
        $Update.LastWriteTime = Get-Date
}
