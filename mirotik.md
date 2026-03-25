# MikroTik — Configquit

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

Router will reboot automatically. Reconnect after it comes back up.

## Create WiFi networks
```routeros

# Set country
/interface wifi set wifi1 configuration.country=Poland
/interface wifi set wifi2 configuration.country=Poland

# Create virtual interfaces
/interface wifi add name=HomeNET-5G master-interface=wifi1 configuration.ssid=HomeNET configuration.mode=ap channel.band=5ghz-ax channel.width=20/40/80mhz security.authentication-types=wpa2-psk,wpa3-psk disabled=no
/interface wifi add name=HomeIoT-5G master-interface=wifi1 configuration.ssid=HomeIoT configuration.mode=ap channel.band=5ghz-ax channel.width=20/40/80mhz security.authentication-types=wpa2-psk,wpa3-psk disabled=no

/interface wifi add name=HomeNET-2G master-interface=wifi2 configuration.ssid=HomeNET configuration.mode=ap channel.band=2ghz-ax channel.width=20/40mhz security.authentication-types=wpa2-psk,wpa3-psk disabled=no
/interface wifi add name=HomeIoT-2G master-interface=wifi2 configuration.ssid=HomeIoT configuration.mode=ap channel.band=2ghz-ax channel.width=20/40mhz security.authentication-types=wpa2-psk,wpa3-psk disabled=no

# Add to bridge
/interface bridge port add bridge=bridge interface=HomeNET-5G
/interface bridge port add bridge=bridge interface=HomeNET-2G
/interface bridge port add bridge=bridge interface=HomeIoT-5G
/interface bridge port add bridge=bridge interface=HomeIoT-2G

# Set passwords
/interface wifi set HomeNET-5G security.passphrase=${WIFI_HOME_PASS}
/interface wifi set HomeNET-2G security.passphrase=${WIFI_HOME_PASS}
/interface wifi set HomeIoT-5G security.passphrase=${WIFI_IOT_PASS}
/interface wifi set HomeIoT-2G security.passphrase=${WIFI_IOT_PASS}

# Verify
/interface wifi print
/interface wifi print detail

```

## Cleanup WiFi networks - if necessary
```routeros
# cleanup
/interface wifi set HomeNET-5G disabled=yes
/interface wifi set HomeNET-2G disabled=yes
/interface wifi set HomeIoT-5G disabled=yes
/interface wifi set HomeIoT-2G disabled=yes

/interface wifi remove HomeNET-5G
/interface wifi remove HomeNET-2G
/interface wifi remove HomeIoT-5G
/interface wifi remove HomeIoT-2G
```

## Wan Config

```routeros
# Set DNS servers
/ip dns set servers=45.90.28.197,45.90.30.197 allow-remote-requests=yes

# --- OPTIONAL: Static WAN  ---
/ip dhcp-client remove [find interface=ether1]
/ip address add address=10.0.0.221/24 interface=ether1
/ip route add gateway=10.0.0.1
```
```
