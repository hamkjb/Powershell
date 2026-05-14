# Requires admin elevation
function Upgrade-WinGetPackages {
    [CmdletBinding()]
    param()

    try {
        # Upgrade all packages from the winget source, including packages with unknown installed versions
        & winget upgrade `
            --all `
            --source winget `
            --accept-package-agreements `
            --accept-source-agreements `
            --include-unknown

        if ($LASTEXITCODE -ne 0) {
            throw "winget exited with code $LASTEXITCODE."
        }
    }
    catch {
        Write-Host "Failed to upgrade packages." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}

# Run the function
Upgrade-WinGetPackages
