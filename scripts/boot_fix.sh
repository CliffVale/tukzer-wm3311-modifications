#!/system/bin/sh
# boot_fix.sh - Tukzer WM3311 boot-time modifications
# Called by start.sh before webkey starts

# --- ADB fix ---
echo "boot_fix: Setting ADB root mode"
setprop persist.sys.usb.config rndis,adb
echo 0 > /sys/class/android_usb/f_mass_storage/lun/file
echo rndis,adb > /sys/class/android_usb/android0/functions
echo 1 > /sys/class/android_usb/android0/enable
setprop service.adb.root 1
start adbd

# --- SELinux ---
echo "boot_fix: Setting SELinux permissive"
echo 0 > /sys/fs/selinux/enforce

# --- SSH ---
echo "boot_fix: Starting dropbear SSH on port 2222"
mkdir -p /etc
cat > /etc/shells << "SHELLS"
/system/xbin/busybox
/system/bin/mksh
/system/xbin/ash
SHELLS
echo "root::0:0:root:/root:/system/xbin/ssh-shell.sh" > /etc/passwd
mkdir -p /etc/dropbear /root/.ssh
chmod 755 /root
# Generate host keys if missing
if [ ! -f /etc/dropbear/dropbear_rsa_host_key ]; then
    /system/xbin/dropbearmulti dropbearkey -t rsa -s 2048 -f /etc/dropbear/dropbear_rsa_host_key
    /system/xbin/dropbearmulti dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key
fi
killall -9 dropbearmulti 2>/dev/null
sleep 1
/system/xbin/dropbearmulti dropbear -p 2222 -E > /tmp/dropbear.log 2>&1 &

# --- Remounts ---
mount -o rw,remount / 2>/dev/null

# --- FTP ---
echo "boot_fix: Starting FTP on port 21"
mkdir -p /data/shared/downloads /data/shared/upload
chmod 777 /data/shared /data/shared/downloads /data/shared/upload
killall tcpsvd 2>/dev/null
/system/xbin/busybox tcpsvd -vE 0.0.0.0 21 /system/xbin/busybox ftpd -w -A /data/shared &

# --- Dashboard ---
echo "boot_fix: Starting dashboard on port 8080"
mkdir -p /data/www/htdocs /data/www/cgi-bin
cp /data/data/com.webkey/files/dashboard.html /data/www/htdocs/index.html 2>/dev/null
killall httpd 2>/dev/null
/system/xbin/busybox httpd -p 8080 -h /data/www/htdocs &

# --- WireGuard ---
echo "boot_fix: Starting WireGuard VPN"
mkdir -p /dev/net 2>/dev/null
[ ! -e /dev/net/tun ] && mknod /dev/net/tun c 10 200 2>/dev/null
killall wireguard-go 2>/dev/null
sleep 1
ip link delete wg0 2>/dev/null
if [ -f /etc/wireguard/wg0.conf ]; then
    /system/xbin/wireguard-go wg0 2>/dev/null &
    sleep 2
    /system/xbin/wg setconf wg0 /etc/wireguard/wg0.conf 2>/dev/null
    ip addr add 10.0.0.1/24 dev wg0 2>/dev/null
    ip link set wg0 up 2>/dev/null
fi

echo "boot_fix: Complete"
