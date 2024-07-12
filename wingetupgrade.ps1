# Requires admin elevation
# Requires admin elevation
function Upgrade-WinGetPackages {
    try {
        # Check for available upgrades and upgrade all packages, including those with unknown versions
        winget upgrade --all --source=winget --accept-package-agreements --accept-source-agreements --include-unknown
    } catch {
        Write-Host "Failed to upgrade packages."
        Write-Host $_
    }
}

# Run the function to upgrade packages
Upgrade-WinGetPackages
