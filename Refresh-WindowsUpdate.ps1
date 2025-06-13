<#
.Synopsis
    Refresh components for Windows Update
.DESCRIPTION
    Refresh components to help trigger patching via MECM
.EXAMPLE
    Run locally or deploy via MECM

#>

<# Variable Declaration #>
$WUservice = Get-WmiObject -Class Win32_Service -Filter "Name='wuauserv'" 
$BITSservice = Get-WmiObject -Class Win32_Service -Filter "Name='BITS'"
$Cryptsvc = Get-WmiObject -Class Win32_service -Filter "Name='cryptsvc'"
$Msiserver = Get-WmiObject -Class Win32_service -Filter "Name='msiserver'"
$SFTDistBK = "c:\windows\SoftwareDistribution.bak"
$SFTDist = "c:\windows\SoftwareDistribution"
$CatrootDir= "c:\windows\system32\catroot2"
$CatrootDirBK = "C:\windows\system32\catroot2.old"

<# Stop Services & Rename Folder #>
Try{
    Try{
        #write-host "Stopping Services: $WUservice.Name"
        if($WUservice.State = "Running"){
            Stop-Service wuauserv
 
        }
        Else {
            Start-Service wuauserv 
            Start-Sleep -Seconds 10
            Stop-Service wuauserv 
        }
        } Catch {
            write-error "$WUservice.Name Service failed to stop" -ErrorId "3"
        }
    Try{
        #write-host "Stopping Services: $BITSservice.Name"
        if($BITSservice.State = "Running"){
            Stop-Service BITS 
        }
        Else {
            Start-Service BITS 
            Start-Sleep -Seconds 10
            Stop-Service BITS 
        } 
    } Catch {
        write-error "$BITSservice.Name service failed to stop" -ErrorId "4"
        Start-Service wuauserv 
    }
    Try{
        #write-host "Stopping Services: $Cryptsvc.Name"
        if($Cryptsvc.State = "Running"){
            Stop-Service cryptsvc
        }
        Else { 
            Start-Service cryptsvc 
            Start-Sleep -Seconds 10
            Stop-Service cryptsvc 
    } 
    } Catch {
        write-error "$Cryptsvc.Name service failed to stop" -ErrorId "5"
        Start-Service wuauserv
        Start-service BITS
    }    
        Try{
        #write-host "Stopping Services: $Msiserver.Name"
        if($Msiserver.State = "Running"){
            Stop-Service Msiserver
        }
        Else { 
            Start-Service Msiserver 
            Start-Sleep -Seconds 10
            Stop-Service Msiserver 
    } 
    } Catch {
        write-error "$Msiserver.Name service failed to stop" -ErrorId "5"
        Start-Service wuauserv
        Start-service BITS
        Start-Service cryptsvc
    }
    $FolderFlagSF = Test-Path $SFTDistBK
    if($WUservice.State = "Stopped" -and ($BITSservice.State = "Stopped")){
        #write-host "Renaming SoftwareDistribution folder"
        Try {
            if(!($FolderFlagSF)){
                Rename-Item -path $SFTDist -NewName $SFTDistBK -Force 
            }
        Else {
            Remove-Item $SFTDistBK -Force -Recurse
            Rename-Item -Path $SFTDist -NewName $SFTDistBK -Force
            }
        } Catch [RenameItemIOError]{
            Write-error "Could not handle Software Distribution folder" -ErrorID "6"
        }
    }
    $FolderFlagCat = Test-Path $CatrootDirBK
    #write-host "Copying Catroot2 folder"
    Try{
        if(!($FolderFlagCat)) {
            New-Item -Path $CatrootDirBK -ItemType Directory
            Copy-Item -Path $CatrootDir -Destination $CatrootDirBK -Recurse 
            Remove-Item $CatrootDir -Force -Recurse
        }
        Else {
            Remove-Item $CatrootDirBK -Force -Recurse
            New-Item -Path $CatrootDirBK -ItemType Directory
            Copy-Item -Path $CatrootDir -Destination $CatrootDirBK -Recurse 
            Remove-Item $CatrootDir -Force -Recurse 
        }
    } Catch {
        write-error "Could not handle Catroot2 folder" -ErrorId "7"
    }
    #write-host "Registering dlls"
    regsvr32.exe /s atl.dll
    regsvr32.exe /s urlmon.dll
    regsvr32.exe /s mshtml.dll
    regsvr32.exe /s shdocvw.dll
    regsvr32.exe /s browseui.dll
    regsvr32.exe /s jscript.dll
    regsvr32.exe /s vbscript.dll
    regsvr32.exe /s scrrun.dll
    regsvr32.exe /s msxml.dll
    regsvr32.exe /s msxml3.dll
    regsvr32.exe /s msxml6.dll
    regsvr32.exe /s actxprxy.dll
    regsvr32.exe /s softpub.dll
    regsvr32.exe /s wintrust.dll
    regsvr32.exe /s dssenh.dll
    regsvr32.exe /s rsaenh.dll
    regsvr32.exe /s gpkcsp.dll
    regsvr32.exe /s sccbase.dll
    regsvr32.exe /s slbcsp.dll
    regsvr32.exe /s cryptdlg.dll
    regsvr32.exe /s oleaut32.dll
    regsvr32.exe /s ole32.dll
    regsvr32.exe /s shell32.dll
    regsvr32.exe /s initpki.dll
    regsvr32.exe /s wuapi.dll
    regsvr32.exe /s wuaueng.dll
    regsvr32.exe /s wuaueng1.dll
    regsvr32.exe /s wucltui.dll
    regsvr32.exe /s wups.dll
    regsvr32.exe /s wups2.dll
    regsvr32.exe /s wuweb.dll
    regsvr32.exe /s qmgr.dll
    regsvr32.exe /s qmgrprxy.dll
    regsvr32.exe /s wucltux.dll
    regsvr32.exe /s muweb.dll
    regsvr32.exe /s wuwebv.dll
}
Finally {
    <# Handle Services & Search SCCM for Updates #>
    #write-host "Restarting Services"
    Start-Service wuauserv
    Start-Service BITS
    Start-Service cryptsvc
    Start-service msiserver 
    #write-host "Kicking off Config Mgr Software Update Deployment Eval"
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000108}" 
}
