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

# Function to get GPU usage and temperature using nvidia-smi
function Get-GPUUsage {
    param (
        [string]$NvidiaSmiPath
    )

    # Attempt to find nvidia-smi.exe if path is not provided or the provided path is incorrect
    if (-not $NvidiaSmiPath -or -not (Test-Path $NvidiaSmiPath)) {
        $NvidiaSmiPath = Get-Command -Name nvidia-smi -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if (-not $NvidiaSmiPath) {
            Write-Error "nvidia-smi.exe not found. Please ensure it is installed and available in the system's PATH."
            return $null
        }
    }

    Try {
        $gpuUsage = & $NvidiaSmiPath --query-gpu=utilization.gpu,utilization.memory,temperature.gpu --format=csv,noheader,nounits
        
        if ($gpuUsage -eq $null) {
            Write-Error "Failed to get GPU usage from nvidia-smi"
            return $null
        }

        # Parse the output
        $gpuUsageInfo = @()
        foreach ($line in $gpuUsage) {
            $columns = $line -split ","
            $gpuUsage = [pscustomobject]@{
                GPUUsage       = [int]$columns[0]
                MemoryUsage    = [int]$columns[1]
                GPUTemperature = [int]$columns[2]
            }
            $gpuUsageInfo += $gpuUsage
        }
        
        return $gpuUsageInfo
    }
    Catch {
        Write-Error "Error retrieving GPU usage information: $_"
        return $null
    }
}

# Function to get CPU temperature
function Get-CPUTemperature {
    Try {
        $temperature = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" | Select-Object CurrentTemperature
        $temperatureC = $temperature.CurrentTemperature - 2732 / 10.0
        return $temperatureC
    }
    Catch {
        Write-Error "Error retrieving CPU temperature: $_"
        return $null
    }
}

# Function to get disk information and temperature
function Get-DiskInfo {
    Try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, @{Name="FreeSpaceGB";Expression={[math]::round($_.FreeSpace / 1GB, 2)}}, @{Name="SizeGB";Expression={[math]::round($_.Size / 1GB, 2)}}
        
        $diskTemps = Get-WmiObject MSStorageDriver_FailurePredictData -Namespace "root\wmi" | Select-Object InstanceName, ReadRawErrorRate, SpinRetryCount, Temperature

        foreach ($disk in $disks) {
            $diskTemp = $diskTemps | Where-Object { $_.InstanceName -like "*$($disk.DeviceID.TrimEnd(':'))*" }
            $disk | Add-Member -MemberType NoteProperty -Name Temperature -Value ([math]::round($diskTemp.Temperature, 2))
        }

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
    $cpuTemp = Get-CPUTemperature
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
        Write-Host " CPU Temperature: $([math]::round($cpuTemp, 2)) °C"
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
        foreach ($gpu in $gpuUsage) {
            Write-Host " GPU Usage: $($gpu.GPUUsage) %"
            Write-Host " Memory Usage: $($gpu.MemoryUsage) %"
            Write-Host " GPU Temperature: $($gpu.GPUTemperature) °C"
        }
    }
    Write-Host ""

    Write-Host "Disk Information:" -ForegroundColor Yellow
    if ($diskInfo) {
        foreach ($disk in $diskInfo) {
            Write-Host " Drive $($disk.DeviceID)"
            Write-Host " Free Space: $($disk.FreeSpaceGB) GB"
            Write-Host " Total Size: $($disk.SizeGB) GB"
            Write-Host " Disk Temperature: $($disk.Temperature) °C"
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

# Generate the report
Generate-Report -NvidiaSmiPath $NvidiaSmiPath
