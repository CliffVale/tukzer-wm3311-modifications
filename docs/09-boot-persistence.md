# 09 — Boot Persistence

## Overview

All modifications survive reboots via a boot-time script (boot_fix.sh) called by the Webkey startup sequence.

## How It Works

The Webkey APK starts via start.sh. We modified it to call boot_fix.sh first:

```bash
#!/system/bin/sh
/data/data/com.webkey/files/boot_fix.sh
su -c /data/data/com.webkey/files/./webkey
mount -o rw,remount /system 2>/dev/null
```

## boot_fix.sh Actions

1. ADB fix — sets rndis,adb, starts adbd as root
2. SELinux — sets permissive
3. SSH — creates /etc/shells, /etc/passwd, starts dropbear
4. FTP — creates shared dirs, starts tcpsvd + ftpd
5. WireGuard — creates /dev/net/tun, starts wireguard-go, configures wg0
6. Dashboard — copies HTML, starts httpd on port 8080

## What Persists vs. Needs Re-setup

| Item | Persists | Notes |
|------|----------|-------|
| /system mods | Yes | System partition is writable |
| Busybox at /system/xbin/ | Yes | Installed to system partition |
| Dropbear at /system/xbin/ | Yes | Installed to system partition |
| wireguard-go + wg | Yes | Installed to system partition |
| /etc/shells | No | Recreated by boot_fix.sh |
| /etc/passwd | No | Recreated by boot_fix.sh |
| SSH host keys | Yes | Stored at /etc/dropbear/ |
| WireGuard config | Yes | Stored at /etc/wireguard/ |
| authorized_keys | Yes | Stored at /root/.ssh/ |
| Dashboard HTML | Yes | Stored in /data/ |
| boot_fix.sh | Yes | Stored in /data/ |

## Testing After Reboot

```bash
# Wait 30 seconds for services to start
ssh tukzer "id; uptime; df /system"
```
