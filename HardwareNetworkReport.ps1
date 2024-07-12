# GPU report assumes nvidia card installed with nvidia-smi installed

param (
    [string]$NvidiaSmiPath = "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    # Add other parameters as needed
)

# Function to get CPU information
function Get-CPUInfo {
    Try {
        $cpu = Get-WmiObject -Class Win32_Processor | Select-Object Name, Manufacturer, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors
        return $cpu
    }
    Catch {
        Write-Error "Error retrieving CPU information: $_"
        return $null
    }
}

# Function to get memory information
function Get-MemoryInfo {
    Try {
        $memory = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{Name="TotalMemoryGB";Expression={$_.Sum / 1GB -as [int]}}
        return $memory
    }
    Catch {
        Write-Error "Error retrieving memory information: $_"
        return $null
    }
}

# Function to get GPU usage using nvidia-smi
function Get-GPUUsage {
    param (
        [string]$NvidiaSmiPath
    )
    Try {
        $gpuUsage = & $NvidiaSmiPath --query-gpu=utilization.gpu --format=csv,noheader,nounits
        return $gpuUsage.Trim()
    }
    Catch {
        Write-Error "Error retrieving GPU usage information: $_"
        return $null
    }
}

# Function to get disk information
function Get-DiskInfo {
    Try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, @{Name="FreeSpaceGB";Expression={[math]::round($_.FreeSpace / 1GB, 2)}}, @{Name="SizeGB";Expression={[math]::round($_.Size / 1GB, 2)}}
        return $disks
    }
    Catch {
        Write-Error "Error retrieving disk information: $_"
        return $null
    }
}

# Function to get network interface information
function Get-NetworkInfo {
    Try {
        $network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true} | Select-Object Description, MACAddress, IPAddress
        return $network
    }
    Catch {
        Write-Error "Error retrieving network information: $_"
        return $null
    }
}

# Function to generate a report
function Generate-Report {
    param (
        [string]$NvidiaSmiPath
    )
    $cpuInfo = Get-CPUInfo
    $memoryInfo = Get-MemoryInfo
    $gpuUsage = Get-GPUUsage -NvidiaSmiPath $NvidiaSmiPath
    $diskInfo = Get-DiskInfo
    $networkInfo = Get-NetworkInfo

    Write-Host "----------------- System Information Report -----------------" -ForegroundColor Cyan

    Write-Host "CPU Information:" -ForegroundColor Yellow
    if ($cpuInfo) {
        Write-Host " Name: $($cpuInfo.Name)"
        Write-Host " Manufacturer: $($cpuInfo.Manufacturer)"
        Write-Host " Max Clock Speed: $($cpuInfo.MaxClockSpeed) MHz"
        Write-Host " Cores: $($cpuInfo.NumberOfCores)"
        Write-Host " Logical Processors: $($cpuInfo.NumberOfLogicalProcessors)"
        
        # Get real-time CPU usage
        $cpuUsage = Get-WmiObject -Class Win32_PerfFormattedData_PerfOS_Processor | Where-Object {$_.Name -eq "_Total"} | Select-Object PercentProcessorTime
        Write-Host " CPU Usage: $($cpuUsage.PercentProcessorTime) %"
    }
    Write-Host ""

    Write-Host "Memory Information:" -ForegroundColor Yellow
    if ($memoryInfo) {
        Write-Host " Total Memory: $($memoryInfo.TotalMemoryGB) GB"
        
        # Get real-time RAM usage
        $ramUsage = Get-WmiObject -Class Win32_OperatingSystem | Select-Object @{Name="TotalRAMGB";Expression={$_.TotalVisibleMemorySize / 1GB -as [int]}}, @{Name="FreeRAMGB";Expression={[math]::round($_.FreePhysicalMemory / 1GB, 2)}}
        Write-Host " Free Memory: $($ramUsage.FreeRAMGB) GB free"
    }
    Write-Host ""

    Write-Host "GPU Information:" -ForegroundColor Yellow
    if ($gpuUsage) {
        Write-Host " GPU Usage: $($gpuUsage) %"
    }
    Write-Host ""

    Write-Host "Disk Information:" -ForegroundColor Yellow
    if ($diskInfo) {
        foreach ($disk in $diskInfo) {
            Write-Host " Drive $($disk.DeviceID)"
            Write-Host " Free Space: $($disk.FreeSpaceGB) GB"
            Write-Host " Total Size: $($disk.SizeGB) GB"
        }
    }
    Write-Host ""

    Write-Host "Network Information:" -ForegroundColor Yellow
    if ($networkInfo) {
        foreach ($net in $networkInfo) {
            Write-Host " Description: $($net.Description)"
            Write-Host " MAC Address: $($net.MACAddress)"
            Write-Host " IP Address(es): $($net.IPAddress -join ', ')"
            Write-Host ""
        }
    }

    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
}

# Remote script execution example
if ($PSCmdlet.ParameterSetName -ne 'Remote') {
    Generate-Report -NvidiaSmiPath $NvidiaSmiPath
}
