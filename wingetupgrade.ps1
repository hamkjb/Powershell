# Requires admin elevation
function Upgrade-WinGetPackages {
    try {
        # Check for available upgrades and upgrade all packages
        winget upgrade --all --source=winget --accept-package-agreements --accept-source-agreements
    } catch {
        Write-Host "Failed to upgrade packages."
        Write-Host $_
    }
}

# Run the function to upgrade packages
Upgrade-WinGetPackages
