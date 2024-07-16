# Requires admin elevation

# Install the PSWindowsUpdate module
Install-Module -Name PSWindowsUpdate -Force

# Set the execution policy to RemoteSigned
Set-ExecutionPolicy RemoteSigned -Force

# Install all available updates and reboot automatically if needed
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

# Retrieve the Windows Update log
Get-WindowsUpdateLog
