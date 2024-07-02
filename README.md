<b>RSAT-AD</b>
 
Installs RSAT (Remote Server Administration Tools) components related to Active Directory that are not currently installed. It also includes error handling to manage potential issues during the installation process.

<b>Appx Packages</b>

PowerShell script to manage Appx packages on Windows. The script creates an allowlist of specific packages and removes any applications that aren't on this list.

    Getting Appx Packages: You start by getting a list of all installed Appx packages using the 
    Get-AppxPackage cmdlet and store them in the $Packages variable.

    Creating the Allowlist: You define an array $AllowList containing wildcard patterns of 
    package names that you want to keep.

    Fetching Dependencies: For each item in the allowlist, you retrieve its dependencies and 
    add them to the allowlist if they are not already included.

    Removing Unwanted Applications: You loop through each package in the $Packages variable. 
    If a package does not match any entry in the allowlist and is not marked as non-removable, 
    you attempt to remove it using Remove-AppxPackage.

This script provides a systematic way to manage Appx packages based on your specified allowlist. Just ensure that the list is comprehensive and accurate to avoid unintended removals.

<b>Remove Windows Bloatware</b>

This PowerShell script is designed to manage local group policies on Windows machines.

    Installing the PolicyFileEditor Module: It first checks if the PolicyFileEditor module 
    is installed. If not, it installs the Nuget package provider (if not already installed)
    and then installs the PolicyFileEditor module.

    Defining Policies: It defines computer and user policies using PSCustomObject. 
    Each policy specifies a registry key, the name of the registry value, data to set, 
    and the value type.

    Setting Group Policies: It attempts to set the defined group policies using the 
    Set-PolicyFileEntry cmdlet. It sets both computer and user policies. If an error 
    occurs during this process, it writes a warning.

    Cleaning Up Start Menu & Taskbar: If the Windows version is detected to be Windows 11,
    it resets the start menu layout. Then, it restarts Explorer to apply changes.

    Reporting and Removing Policies: The script provides commented-out sections for 
    reporting on configured policies and removing them if needed.

This script provides a systematic way to manage local group policies and perform additional cleanup tasks related to the start menu and taskbar. Just ensure to review and test it thoroughly in your environment before deploying it widely.
