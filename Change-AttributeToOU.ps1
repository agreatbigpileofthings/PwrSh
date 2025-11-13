<#
.DESCRIPTION
   Comb through AD, grab OU, apply to extensionAttribute1
.EXAMPLE
   Just Run It
.AUTHOR
 Ryan Martin | agreatbigpileofthings.com
#>

$Users = Get-ADUser -Filter * -Properties SamAccountName, extensionAttribute1
foreach($user in $Users){
    $DistinguishedNames = Get-ADUser -Identity $user | Where-Object DistinguishedName -Like "*OU=Users*" | Select-Object -ExpandProperty DistinguishedName 
    foreach($name in $DistinguishedNames){
        $OU = $name.Split("=")[3]
        $CleanName = $OU.Split(",")[0]
        write-host "$($user.Name) | $CleanName"
        Set-ADUser -Identity $user -Add @{"extensionAttribute1"="$CleanName"}
    }
}
