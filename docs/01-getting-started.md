# 01 — Getting Started

## Prerequisites

- A Tukzer WM3311 (or any UZ801 v3.x device running Webkey-based firmware)
- USB cable (micro-USB to USB-A)
- Linux/macOS host with `curl`, `ssh`, and basic tools

## Initial Connection

1. **Power on the device** (press and hold power button ~3 seconds)
2. **Connect via USB** — the device enumerates as an RNDIS network adapter
3. **Find the device IP**: `192.168.42.129` (default for Webkey firmware)

```bash
# Test connectivity
ping 192.168.42.129

# Access the web UI
curl --digest -u admin:admin http://192.168.42.129/
```

## Verify Root Shell Access

The Webkey `/run` endpoint executes shell commands as root:

```bash
# Basic command
curl --digest -u admin:admin -X POST \
  -d 'id' \
  http://192.168.42.129/run

# Expected output:
# uid=0(root) gid=0(root)

# Get system info
curl --digest -u admin:admin -X POST \
  -d 'cat /proc/version; echo "---"; uname -a; echo "---"; cat /proc/cpuinfo | head -5' \
  http://192.168.42.129/run
```

## Remount /system as Read-Write

The `/system` partition is ext4 and mounted read-only by default:

```bash
curl --digest -u admin:admin -X POST \
  -d 'mount -o rw,remount /system; mount | grep system' \
  http://192.168.42.129/run
```

## Filesystem Layout

| Path | Description | Space |
|------|-------------|-------|
| `/system` | System partition (ext4) | 775MB total, ~485MB free |
| `/data` | User data partition | 2.4GB total, ~2.3GB free |
| `/cache` | Cache partition | 122MB |
| `/storage/sdcard0` | Internal storage (same as /data) | 2.3GB |

## USB Gadget Notes

The device uses RNDIS (Remote Network Driver Interface Specification) for USB networking:

```bash
# Check USB config
cat /sys/class/android_usb/android0/functions
# Expected: rndis,adb (after fix — see doc 02)
```

## Default Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Web UI | http://192.168.42.129/ | `admin` | See `--sms.html` or super password `564356` |
| HTTP API | POST http://192.168.42.129/run | `admin` | Same as web UI |
