# Function to upgrade all installed packages using winget
function Upgrade-WinGetPackages {
    # Get a list of installed packages
    $installedPackages = winget list --quiet --sourced --id

    # Loop through each installed package and upgrade it
    foreach ($package in $installedPackages) {
        Write-Host "Checking for updates for package: $package"
        winget upgrade --id $package
    }
}

# Run the function to upgrade packages
Upgrade-WinGetPackages
