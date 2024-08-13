# Retrieve network adapter information
$networkAdapters = Get-NetAdapter | ForEach-Object {
    $ipAddress = (Get-NetIPAddress -InterfaceAlias $_.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress -join ', '
    
    [PSCustomObject]@{
        Name       = $_.Name
        Status     = $_.Status
        MacAddress = $_.MAC Address
        IPAddress  = if ($ipAddress) { $ipAddress } else { "N/A" }
    }
}

# Display the results in a formatted table
$networkAdapters | Format-Table -AutoSize
