# MikroTik Configuration

 Interface | VLAN ID | Subnet | Gateway | DHCP Range | Role | Ports | Wi-Fi SSID |
|-----------|---------|--------|---------|------------|------|-------|------------|
| ether1 | — | dynamic (ISP) | ISP gateway | — | WAN uplink | ether1 | — |
| bridge | — | 192.168.88.0/24 | 192.168.88.1 | — | Management | all (default) | — |
| vlan10 | 10 | 192.168.10.0/24 | 192.168.10.1 | .10 – .200 | Home | ether2, ether3 | HomeNET |
| vlan20 | 20 | 192.168.20.0/24 | 192.168.20.1 | .10 – .200 | Monitoring | — | — |
| vlan30 | 30 | 192.168.30.0/24 | 192.168.30.1 | .10 – .200 | IoT | — | HomeIoT |


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
