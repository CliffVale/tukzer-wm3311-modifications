# 10 — Troubleshooting

## SSH: "User 'root' has invalid shell, rejected"

Check dropbear log:
```bash
cat /tmp/dropbear.log
```
Fix: Verify /etc/shells, /etc/passwd, restart dropbear.

## SSH: "Permission denied (publickey)"

Check:
```bash
ls -la /root/.ssh/authorized_keys  # must be 600
cat /root/.ssh/authorized_keys     # verify key present
```
Fix: Add client's public key, chmod 600.

## SSH: Password authentication fails

Check hash format in /etc/passwd. Must start with $1$ (MD5), not $6$ (SHA-512).
Fix: Use openssl passwd -1 to generate MD5 hash.

## WireGuard: "Failed to create TUN device"

Check TUN device:
```bash
ls -la /dev/net/tun
```
Fix: mkdir -p /dev/net; mknod /dev/net/tun c 10 200

## ADB: Device not found after reboot

Check USB functions:
```bash
cat /sys/class/android_usb/android0/functions
```
Should show: rndis,adb. Re-apply if not.

## FTP: Connection refused

Restart FTP:
```bash
killall tcpsvd
/system/xbin/busybox tcpsvd -vE 0.0.0.0 21 /system/xbin/busybox ftpd -w -A /data/shared &
```

## Dashboard: 404 Not Found

Copy dashboard:
```bash
cp /data/data/com.webkey/files/dashboard.html /data/www/htdocs/index.html
```
