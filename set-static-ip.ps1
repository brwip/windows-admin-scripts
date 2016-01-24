# set static IP
#
# adapted from http://www.adminarsenal.com/admin-arsenal-blog/using-powershell-to-set-static-and-dhcp-ip-addresses-part-1/


param(
[Parameter(Mandatory=$true)]
[string]$IP,
[string]$MaskBits = 24, # This means subnet mask = 255.255.255.0
[Parameter(Mandatory=$true)]
[string]$Gateway,
[Parameter(Mandatory=$true)]
[string]$Dns,
[string]$IPType = "IPv4"
)

set-strictmode -version latest
$ErrorActionPreference = "Stop"

# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}

 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $IP `
    -PrefixLength $MaskBits `
    -DefaultGateway $Gateway

# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS