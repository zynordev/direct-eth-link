<#
.SYNOPSIS
    Configure a direct point-to-point Ethernet link on Windows (no default gateway).
.DESCRIPTION
    Assigns a static IPv4 address to the chosen Ethernet adapter without setting a
    default gateway, so Windows keeps using Wi-Fi (or your primary adapter) for internet.
.EXAMPLE
    .\setup-windows.ps1
    .\setup-windows.ps1 -InterfaceAlias "Ethernet" -IPAddress "192.168.10.1" -PrefixLength 24
    .\setup-windows.ps1 -Remove -InterfaceAlias "Ethernet"
#>

[CmdletBinding()]
param(
    [string]$InterfaceAlias = "",
    [string]$IPAddress = "192.168.10.1",
    [int]$PrefixLength = 24,
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

# Require Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run PowerShell as Administrator."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($InterfaceAlias)) {
    $adapters = Get-NetAdapter | Where-Object { $_.HardwareInterface -eq $true -and $_.Name -notmatch "Wi-Fi|WLAN|Wireless|Bluetooth" }
    if ($adapters.Count -eq 0) {
        Write-Error "No physical Ethernet adapter found."
        exit 1
    } elseif ($adapters.Count -eq 1) {
        $InterfaceAlias = $adapters[0].Name
    } else {
        Write-Host "Available Ethernet adapters:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            Write-Host "  [$i] $($adapters[$i].Name) ($($adapters[$i].InterfaceDescription)) - $($adapters[$i].Status)"
        }
        $choice = Read-Host "Select adapter index [0]"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "0" }
        $InterfaceAlias = $adapters[[int]$choice].Name
    }
}

if ($Remove) {
    Write-Host "Reverting '$InterfaceAlias' to DHCP..." -ForegroundColor Yellow
    Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Enabled
    Write-Host "Done." -ForegroundColor Green
    exit 0
}

Write-Host "Configuring '$InterfaceAlias' -> $IPAddress/$PrefixLength (no default gateway)..." -ForegroundColor Cyan

# Clear existing static IPv4 addresses on this interface
Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.PrefixOrigin -ne "WellKnown" } |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

Get-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Disabled
New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -AddressFamily IPv4 | Out-Null

Write-Host ""
Write-Host "Done! Assigned IPv4:" -ForegroundColor Green
Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength -AutoSize
