# Script to print Windows server specifications

# Operating system information
$os = Get-WmiObject Win32_OperatingSystem
Write-Host "====================================="
Write-Host "Operating system information:"
Write-Host "====================================="
Write-Host "Hostname: " $env:COMPUTERNAME
Write-Host "OS name: " $os.Caption
Write-Host "OS version: " $os.Version
Write-Host "Service Pack: " $os.ServicePackMajorVersion"."$os.ServicePackMinorVersion
Write-Host "Install date: " ([Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate))
Write-Host "Uptime (since last boot): " ([math]::Round(((Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime))).TotalDays,2)) "days"

# CPU information
$cpu = Get-WmiObject Win32_Processor
Write-Host "`n====================================="
Write-Host "CPU information:"
Write-Host "====================================="
Write-Host "CPU name: " $cpu.Name
Write-Host "Cores: " $cpu.NumberOfCores
Write-Host "Threads: " $cpu.NumberOfLogicalProcessors
$cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time'
$cpuUsageValue = [math]::Round($cpuUsage.CounterSamples[0].CookedValue, 2)
Write-Host "Current CPU usage: $cpuUsageValue %"

# RAM information
$cs = Get-WmiObject Win32_ComputerSystem
Write-Host "`n====================================="
Write-Host "RAM information:"
Write-Host "====================================="
Write-Host "Total memory (RAM): " ([math]::Round($cs.TotalPhysicalMemory/1GB,2)) "GB"
$totalMemKB = $os.TotalVisibleMemorySize
$freeMemKB = $os.FreePhysicalMemory
$usedMemPercentage = [math]::Round((($totalMemKB - $freeMemKB) / $totalMemKB * 100), 2)
Write-Host "Current RAM usage: $usedMemPercentage %"

# Disk information (local disks only)
$disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
Write-Host "`n====================================="
Write-Host "Disk information:"
Write-Host "====================================="
foreach ($disk in $disks) {
    $size = [math]::Round($disk.Size/1GB,2)
    $free = [math]::Round($disk.FreeSpace/1GB,2)
    Write-Host "Disk $($disk.DeviceID): Total size: $size GB, Free space: $free GB"
}
