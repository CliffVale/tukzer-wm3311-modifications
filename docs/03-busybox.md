# 03 — Busybox Installation

## Why Busybox?

The stock Android 4.4.4 system has a minimal toolset (`toolbox`) missing critical utilities like `sed`, `awk`, `find`, `vi`, `nc`, etc. Busybox provides 390+ applets in a single static binary.

## Approach

We use a **pre-built static ARM NDK build** of Busybox v1.36.1 — no compilation needed. The binary is pushed to the device and symlinks are created for all applets.

## Installation

### Step 1: Download busybox ARM binary

On your build machine:

```bash
# Get the osm0sis NDK build (recommended for Android)
wget https://github.com/Magisk-Modules-Repo/busybox-ndk/raw/master/busybox-arm
# OR build your own
```

### Step 2: Push to device

```bash
# Upload via ADB
adb push busybox-arm /system/xbin/busybox

# OR upload via HTTP API (base64 encode first)
```

### Step 3: Set permissions and install

```bash
chmod 755 /system/xbin/busybox
cd /system/xbin
for applet in $(busybox --list); do
  ln -sf busybox $applet
done
```

### Step 4: Verify

```bash
# Check version
busybox --help | head -1
# BusyBox v1.36.1-osm0sis (2023-05-25 15:21:20 ADT) multi-call binary.

# Check applet count
busybox --list | wc -l
# 390

# Test key applets
sed --help | head -2
vi --help | head -2
nc --help | head -2
```

## Key Applets Available

```
ash, awk, cat, chmod, cp, cut, dd, df, du, echo, egrep,
find, ftpd, grep, gunzip, gzip, head, hexdump, ip, kill,
killall, less, ln, ls, md5sum, mkdir, mknod, more, mount,
mv, nc, netstat, nice, nohup, od, patch, pidof, ping, ps,
pstree, pwd, readlink, realpath, reboot, renice, reset,
rm, rmdir, sed, seq, sha1sum, sha256sum, sha3sum, sha512sum,
sh, shred, sleep, sort, split, stat, strings, stty, swapoff,
swapon, sync, sysctl, tail, tar, tee, test, time, timeout,
top, touch, tr, traceroute, true, truncate, tty, ubootenv,
udhcpc, umount, uname, uniq, unlink, unshare, uptime, usleep,
uudecode, uuencode, vi, watch, wc, wget, which, whoami,
xargs, xxd, yes, zcat
```

## Note on Path Resolution

On Android 4.4.4, the system uses symlinks for applet dispatch. When busybox is invoked as a symlink name (e.g., `/system/xbin/sed`), it reads `argv[0]` to determine which applet to run. Direct invocation (`/system/xbin/busybox` without an applet name) fails with "applet not found" unless a specific applet is named as the first argument.
