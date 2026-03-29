# Network reference

## VLANs
 
| VLAN | Name | Subnet | Gateway | DHCP range | Ports | Wi-Fi |
|------|------|--------|---------|------------|-------|-------|
| 10 | Home | 192.168.10.0/24 | 192.168.10.1 | .10 – .200 | ether2, ether3 | HomeNET |
| 20 | Monitoring | 192.168.20.0/24 | 192.168.20.1 | .10 – .200 | ether4 | — |
| 30 | IoT | 192.168.30.0/24 | 192.168.30.1 | .10 – .200 | — | HomeIoT |
| — | Management | 192.168.88.0/24 | 192.168.88.1 | — | — | — |
 
## Static DHCP leases
 
| Device | MAC | IP | VLAN |
|--------|-----|----|------|
| NAS | 10:E7:C6:07:0B:39 | 192.168.10.10 | Home |
| WTR | C8:FF:BF:05:AA:09 | 192.168.10.20 | Home |
 
## Port forwards (WAN → LAN)
 
| Protocol | WAN port | Destination | Service |
|----------|----------|-------------|---------|
| TCP | 443 | 192.168.10.10:443 | NAS |
 
## VLAN access matrix
 
| From | Internet | Home | Monitoring | IoT |
|------|----------|------|------------|-----|
| Home | allow | self | initiate only | initiate only |
| Monitoring | allow | block | self | block |
| IoT | allow | block | block | self |
 
## DNS
 
| Hostname | Resolves to | Note |
|----------|-------------|------|
| *.gorillabay.click | 192.168.10.10 | Wildcard — all subdomains → NAS |
| upstream | 45.90.28.197, 45.90.30.197 | NextDNS |


<br/><br/>
<br/><br/>


# Configuration

## Connect to router
```routeros
ssh admin@192.168.88.1
```

## Check for updates
```routeros
/system package update check-for-updates
```

## Install updates
```routeros
/system package update install
```

## Enable scheduler feature on router - will ask to confirm by pressing the physical reset buttonsk 
```routeros
# Run this first and confirm with reset button on the device
/system device-mode update scheduler=yes
```

## Set Wi-Fi regulatory country for both radios (legal frequencies/power)
```routeros
/interface wifi set wifi1 configuration.country=Poland
/interface wifi set wifi2 configuration.country=Poland
```

## Create virtual Wi-Fi interfaces on top of physical radios
`master-interface=wifi1` → 5GHz radio, `master-interface=wifi2` → 2GHz radio
```routeros
/interface wifi
add name=HomeNET-5G master-interface=wifi1 configuration.ssid=HomeNET configuration.mode=ap \
    channel.band=5ghz-ax channel.width=20/40/80mhz \
    security.authentication-types=wpa2-psk,wpa3-psk comment="Home 5GHz" disabled=no
add name=HomeNET-2G master-interface=wifi2 configuration.ssid=HomeNET configuration.mode=ap \
    channel.band=2ghz-ax channel.width=20/40mhz \
    security.authentication-types=wpa2-psk,wpa3-psk comment="Home 2GHz" disabled=no
add name=HomeIoT-5G master-interface=wifi1 configuration.ssid=HomeIoT configuration.mode=ap \
    channel.band=5ghz-ax channel.width=20/40/80mhz \
    security.authentication-types=wpa2-psk,wpa3-psk comment="IoT 5GHz" disabled=no
add name=HomeIoT-2G master-interface=wifi2 configuration.ssid=HomeIoT configuration.mode=ap \
    channel.band=2ghz-ax channel.width=20/40mhz \
    security.authentication-types=wpa2-psk,wpa3-psk comment="IoT 2GHz" disabled=no
```

## Set Wi-Fi passwords
```routeros
/interface wifi set HomeNET-5G security.passphrase=${WIFI_HOME_PASS}
/interface wifi set HomeNET-2G security.passphrase=${WIFI_HOME_PASS}
/interface wifi set HomeIoT-5G security.passphrase=${WIFI_IOT_PASS}
/interface wifi set HomeIoT-2G security.passphrase=${WIFI_IOT_PASS}
```

## Create logical VLAN interfaces on top of the bridge
```routeros
/interface vlan
add name=vlan10 interface=bridge vlan-id=10 comment="Home"
add name=vlan20 interface=bridge vlan-id=20 comment="Monitoring"
add name=vlan30 interface=bridge vlan-id=30 comment="IoT"
```

## Assign physical ports to VLANs
`tagged=bridge` → CPU can send/receive VLAN traffic for routing

`untagged=etherX` → access port, connected device doesn't need to know about VLANs
Wi-Fi interfaces added as untagged so VLAN filtering allows their traffic through
```routeros
/interface bridge vlan
add bridge=bridge vlan-ids=10 tagged=bridge untagged=ether2,ether3,HomeNET-5G,HomeNET-2G
add bridge=bridge vlan-ids=20 tagged=bridge untagged=ether4
add bridge=bridge vlan-ids=30 tagged=bridge untagged=HomeIoT-5G,HomeIoT-2G
```

## Set PVID (Port VLAN ID)
Untagged frames arriving on this port get assigned to this VLAN
```routeros
/interface bridge port
set [find interface=ether2] pvid=10
set [find interface=ether3] pvid=10
set [find interface=ether4] pvid=20
add bridge=bridge interface=HomeNET-5G pvid=10
add bridge=bridge interface=HomeNET-2G pvid=10
add bridge=bridge interface=HomeIoT-5G pvid=30
add bridge=bridge interface=HomeIoT-2G pvid=30
```

## Assign gateway IPs to each VLAN interface (router acts as default gateway)
```routeros
/ip address
add address=192.168.10.1/24 interface=vlan10
add address=192.168.20.1/24 interface=vlan20
add address=192.168.30.1/24 interface=vlan30
```

## Define DHCP address pools for each VLAN (.1-.9 reserved for static devices)
```routeros
/ip pool
add name=pool10 ranges=192.168.10.10-192.168.10.200
add name=pool20 ranges=192.168.20.10-192.168.20.200
add name=pool30 ranges=192.168.30.10-192.168.30.200
```

## Create one DHCP server per VLAN
```routeros
/ip dhcp-server
add name=dhcp10 interface=vlan10 address-pool=pool10 disabled=no
add name=dhcp20 interface=vlan20 address-pool=pool20 disabled=no
add name=dhcp30 interface=vlan30 address-pool=pool30 disabled=no
```

## Tell DHCP what gateway and DNS server to advertise to clients
```routeros
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=192.168.10.1
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.1
add address=192.168.30.0/24 gateway=192.168.30.1 dns-server=192.168.30.1
```

## Set upstream DNS servers and allow router to answer DNS queries from clients
Without `allow-remote-requests` clients cannot resolve domain names
```routeros
/ip dns
set servers=45.90.28.197,45.90.30.197 allow-remote-requests=yes
```

## Add VLAN interfaces to the trusted LAN list
Default firewall trusts LAN list for DNS/DHCP — without this, DNS queries from
VLAN clients are silently dropped by the firewall input chain
```routeros
/interface list member
add list=LAN interface=vlan10
add list=LAN interface=vlan20
add list=LAN interface=vlan30
```

## Activate VLAN filtering on the bridge — enable this last
Without this line all VLAN config above has no effect
```routeros
/interface bridge set bridge vlan-filtering=yes
```

## Move UI to port 8080
```routeros
/ip service
set www port=8080
```

## Add DHCP reservation
```routeros
/ip dhcp-server lease
add server=dhcp10 mac-address=10:E7:C6:07:0B:39 address=192.168.10.10 comment="NAS"
add server=dhcp10 mac-address=C8:FF:BF:05:AA:09 address=192.168.10.20 comment="WTR"
```

## DNS entries
```routeros
# ================================================
# DNS: internal static entry
# ================================================
:if ([/ip dns static find name="*.gorillabay.click"] = "") do={
    /ip dns static add name="*.gorillabay.click" address=192.168.10.10 \
        comment="INTERNAL DNS: *.gorillabay.click → NAS"
}
```

## Firewall rules
```routeros
# ================================================
# NAT
# ================================================
:if ([/ip firewall nat find comment="NAT: hairpin dstnat NAS"] = "") do={
    /ip firewall nat add chain=dstnat in-interface-list=LAN protocol=tcp \
        dst-address=89.70.195.41 dst-port=80,443 \
        action=dst-nat to-addresses=192.168.10.10 \
        comment="NAT: hairpin dstnat NAS"
}
:if ([/ip firewall nat find comment="INTERNET HTTPS → NAS"] = "") do={
    /ip firewall nat add chain=dstnat in-interface-list=WAN protocol=tcp dst-port=443 action=dst-nat to-addresses=192.168.10.10 to-ports=443 comment="INTERNET HTTPS → NAS"
}
:if ([/ip firewall nat find comment="INTERNET HTTP → NAS"] = "") do={
    /ip firewall nat add chain=dstnat in-interface-list=WAN protocol=tcp dst-port=80 action=dst-nat to-addresses=192.168.10.10 to-ports=80 comment="INTERNET HTTP → NAS"
}
:if ([/ip firewall nat find comment="NAT: LAN → WAN"] = "") do={
    /ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="NAT: LAN → WAN"
}
:if ([/ip firewall nat find comment="NAT: hairpin NAS"] = "") do={
    /ip firewall nat add chain=srcnat protocol=tcp \
        dst-address=192.168.10.10 dst-port=80,443 \
        out-interface=vlan10 action=masquerade \
        comment="NAT: hairpin NAS"
}

# ================================================
# INPUT chain
# ================================================
:if ([/ip firewall filter find comment="INPUT: established/related"] = "") do={
    /ip firewall filter add chain=input connection-state=established,related action=accept comment="INPUT: established/related"
}
:if ([/ip firewall filter find comment="INPUT: drop invalid"] = "") do={
    /ip firewall filter add chain=input connection-state=invalid action=drop comment="INPUT: drop invalid"
}
:if ([/ip firewall filter find comment="INPUT: drop from WAN"] = "") do={
    /ip firewall filter add chain=input in-interface-list=WAN action=drop comment="INPUT: drop from WAN"
}
:if ([/ip firewall filter find comment="INPUT: ping from HOME"] = "") do={
    /ip firewall filter add chain=input in-interface=vlan10 protocol=icmp action=accept comment="INPUT: ping from HOME"
}
:if ([/ip firewall filter find comment="INPUT: SSH/Winbox from HOME"] = "") do={
    /ip firewall filter add chain=input in-interface=vlan10 protocol=tcp dst-port=22,8291 action=accept comment="INPUT: SSH/Winbox from HOME"
}
:if ([/ip firewall filter find comment="INPUT: DNS+DHCP from LAN"] = "") do={
    /ip firewall filter add chain=input in-interface-list=LAN protocol=udp dst-port=53,67 action=accept comment="INPUT: DNS+DHCP from LAN"
}

# ================================================
# FORWARD chain
# ================================================
:if ([/ip firewall filter find comment="FORWARD: established/related"] = "") do={
    /ip firewall filter add chain=forward connection-state=established,related action=accept comment="FORWARD: established/related"
}
:if ([/ip firewall filter find comment="FORWARD: drop invalid"] = "") do={
    /ip firewall filter add chain=forward connection-state=invalid action=drop comment="FORWARD: drop invalid"
}
:if ([/ip firewall filter find comment="FORWARD: all VLANs → internet"] = "") do={
    /ip firewall filter add chain=forward in-interface-list=LAN out-interface-list=WAN connection-state=new action=accept comment="FORWARD: all VLANs → internet"
}
:if ([/ip firewall filter find comment="FORWARD: HOME → MONITORING"] = "") do={
    /ip firewall filter add chain=forward in-interface=vlan10 out-interface=vlan20 connection-state=new action=accept comment="FORWARD: HOME → MONITORING"
}
:if ([/ip firewall filter find comment="FORWARD: HOME → IOT"] = "") do={
    /ip firewall filter add chain=forward in-interface=vlan10 out-interface=vlan30 connection-state=new action=accept comment="FORWARD: HOME → IOT"
}
:if ([/ip firewall filter find comment="FORWARD: BLOCK MONITORING → HOME"] = "") do={
    /ip firewall filter add chain=forward in-interface=vlan20 out-interface=vlan10 action=drop comment="FORWARD: BLOCK MONITORING → HOME"
}
:if ([/ip firewall filter find comment="FORWARD: BLOCK IOT → HOME"] = "") do={
    /ip firewall filter add chain=forward in-interface=vlan30 out-interface=vlan10 action=drop comment="FORWARD: BLOCK IOT → HOME"
}
```

## Create script that updates Hairpin rules when WAN IP changes
```routeros
/system script add name=update-hairpin-nat source={
    :local wanip [/ip address get [find interface=ether1] address]
    :set wanip [:pick $wanip 0 [:find $wanip "/"]]
    /ip firewall nat set [find comment="NAT: hairpin dstnat NAS"] dst-address=$wanip
}

/system scheduler add name=update-hairpin-nat interval=1m \
    on-event=update-hairpin-nat comment="Update hairpin NAT with current WAN IP"
```

## Hardening
```routeros
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
set www address=192.168.88.0/24,192.168.10.0/24      # WebUI accessible from LAN only
set www-ssl address=192.168.88.0/24,192.168.10.0/24  # HTTPS WebUI from LAN only
set ssh address=192.168.88.0/24,192.168.10.0/24
set winbox address=192.168.88.0/24,192.168.10.0/24
```
