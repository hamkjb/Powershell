Install-Module -Name PSWindowsUpdate -Force
Set-ExecutionPolicy RemoteSigned
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
Get-WindowsUpdateLog