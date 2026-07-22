#!/bin/bash
# setup-all.sh - One-shot full setup for Tukzer WM3311
# Run from your Linux host with the device connected via USB
# Usage: bash setup-all.sh

DEVICE="192.168.42.129"
CRED="admin:admin"
API="http://${DEVICE}/run"

echo "=== Tukzer WM3311 — Full Setup ==="
echo "Device: ${DEVICE}"
echo ""

# Check connectivity
echo "=== Checking connectivity... ==="
curl -s --digest -u "${CRED}" -d 'id' "${API}" | head -1 || {
    echo "ERROR: Cannot reach device at ${DEVICE}"
    echo "Ensure USB is connected and RNDIS is active."
    exit 1
}

# 1. Remount system
echo "=== Remounting /system rw ==="
curl -s --digest -u "${CRED}" -d 'mount -o rw,remount /system; mount -o rw,remount /' "${API}"

# 2. Fix ADB
echo "=== Fixing ADB ==="
curl -s --digest -u "${CRED}" -d 'echo rndis,adb > /sys/class/android_usb/android0/functions; setprop service.adb.root 1; start adbd' "${API}"

# 3. Deploy boot_fix.sh
echo "=== Deploying boot_fix.sh ==="
# Download from the repo
curl -s --digest -u "${CRED}" -d 'wget -qO /data/data/com.webkey/files/boot_fix.sh https://raw.githubusercontent.com/CliffVale/tukzer-wm3311-modifications/main/scripts/boot_fix.sh && chmod 755 /data/data/com.webkey/files/boot_fix.sh' "${API}"

# 4. Deploy dashboard
echo "=== Deploying dashboard ==="
curl -s --digest -u "${CRED}" -d 'wget -qO /data/www/htdocs/index.html https://raw.githubusercontent.com/CliffVale/tukzer-wm3311-modifications/main/api/dashboard.html' "${API}"

# 5. Run boot_fix
echo "=== Running boot_fix.sh ==="
curl -s --digest -u "${CRED}" -d '/data/data/com.webkey/files/boot_fix.sh' "${API}"

# 6. Verify
echo ""
echo "=== Verification ==="
echo "SSH: ssh -p 2222 root@${DEVICE}"
echo "FTP: ftp ${DEVICE}"
echo "Dashboard: http://${DEVICE}:8080/"
echo "WireGuard: 10.0.0.1:51820"
echo ""
echo "=== Setup complete! ==="
