$adapters = Get-NetAdapter | Get-NetAdapterPowerManagement
foreach ($adapter in $adapters)
{
$adapter.AllowComputerToTurnOffDevice = 'Disabled'
$adapter | Set-NetAdapterPowerManagement
}

$DateTime = Get-Date -Format "yyy/MM/dd HH:mm:ss"
$PCName = Get-WmiObject -Class win32_computersystem | Select-Object -ExpandProperty Name

$Message = "$PCName completed at $DateTime"
$Message | Out-File "PATH\Disable NIC Power Management.txt" -Append -Force
