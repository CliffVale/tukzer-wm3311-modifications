# 06 — WireGuard VPN

## Overview

WireGuard provides an encrypted VPN tunnel. Since the kernel 3.10.28 doesn't have WireGuard built-in, we use **wireguard-go** — a userspace implementation that creates a TUN interface and handles encryption in userspace.

## Prerequisites

- **Go 1.26+** for cross-compiling wireguard-go
- **Zig 0.16+** for cross-compiling wireguard-tools (wg)
- TUN device support in kernel (present: /dev/tun)

## Building wireguard-go for ARM

```bash
# Clone from official repo
git clone --depth 1 https://git.zx2c4.com/wireguard-go
cd wireguard-go

# Cross-compile for ARM
GOOS=linux GOARCH=arm CGO_ENABLED=0 go build -o wireguard-go-arm

# Check binary
file wireguard-go-arm
# ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked
```

## Building wg-tools for ARM

```bash
# Clone wireguard-tools
git clone --depth 1 https://git.zx2c4.com/wireguard-tools
cd wireguard-tools/src

# Cross-compile with zig
CC="zig cc -target arm-linux-musleabi -O2 -static" \
  make DESTDIR=/tmp/wg-out \
  WITH_SYSTEMDUNITS=no WITH_BASHCOMPLETION=no WITH_WGQUICK=no

# Result: ./wg — static ARM ELF
file wg
# ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked
```

## TUN Device Setup

The device has /dev/tun but wireguard-go looks for /dev/net/tun:

```bash
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
# Or symlink: ln -sf /dev/tun /dev/net/tun
```

## Server Configuration

```bash
mkdir -p /etc/wireguard

# Generate keys
# On laptop:
wg genkey | tee server.key | wg pubkey > server.pub
wg genkey | tee client.key | wg pubkey > client.pub

# Server config (/etc/wireguard/wg0.conf)
cat > /etc/wireguard/wg0.conf << "EOF"
[Interface]
PrivateKey = <server-private-key>
ListenPort = 51820

[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32
EOF
```

## Starting the Service

```bash
# Start wireguard-go (creates wg0 interface)
/system/xbin/wireguard-go wg0

# Apply configuration
/system/xbin/wg setconf wg0 /etc/wireguard/wg0.conf

# Set IP address
ip addr add 10.0.0.1/24 dev wg0
ip link set wg0 up
```

## Client (Laptop) Configuration

```bash
# Client config (~/.config/wireguard/tukzer.conf)
cat > ~/.config/wireguard/tukzer.conf << "EOF"
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.2/24

[Peer]
PublicKey = <server-public-key>
AllowedIPs = 10.0.0.0/24
Endpoint = 192.168.42.129:51820
PersistentKeepalive = 25
EOF

# Connect
sudo wg-quick up ~/.config/wireguard/tukzer.conf

# SSH through the tunnel
ssh root@10.0.0.1 "id; uptime"
```

## Verification

```bash
# On device
/system/xbin/wg show
# interface: wg0
#   public key: MPrrYcECaBdIHNm4+boVeB+HX/Pvw+/e+boMQLx3bUQ=
#   listening port: 51820
# peer: B2mba7pYaPlskxlwh85+sM7MvVcKxEpep1tR3+CTIF4=
#   allowed ips: 10.0.0.2/32

# Test ping
ping -c 3 10.0.0.1
```

## Troubleshooting

### /dev/net/tun does not exist

The TUN device is at /dev/tun but wireguard-go looks for /dev/net/tun:
```bash
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
```

### "Failed to create TUN device: device or resource busy"

A previous wireguard-go instance is still running:
```bash
killall wireguard-go
ip link delete wg0
sleep 1
# Then restart
```

### "Running wireguard-go is not required because this kernel has first class support for WireGuard"

This warning appears on newer wireguard-go versions. It checks for /sys/module/wireguard which may not exist on 3.10.28. It's harmless — wireguard-go still runs correctly.
