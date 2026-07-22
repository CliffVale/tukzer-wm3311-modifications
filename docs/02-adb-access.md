# 02 — Root ADB Access (Permanent Fix)

## The Problem

The stock firmware has ADB support **compiled into the kernel** but it never activates at boot. The root cause is a bug in `/init.qcom.usb.rc` — Android's USB gadget configuration script.

## Root Cause: Two Bugs in init.qcom.usb.rc

### Bug 1 (line 622)

```ini
on property:sys.usb.config=rndis,adb
    write /sys/class/android_usb/android0/functions **rndis**   # <-- MISSING ",adb"!
```

When the system sets `sys.usb.config=rndis,adb`, the `write` command only writes `rndis` — omitting ADB entirely.

### Bug 2 (line 1081)

```ini
on property:sys.usb.config=charging,none,adb
    write /sys/class/android_usb/android0/functions **rndis**   # <-- Wrong function!
```

Charging mode with ADB writes RNDIS instead of charging functions.

## The Fix

### Method 1: Live Patch (until reboot)

```bash
curl --digest -u admin:admin -X POST \
  -d 'echo rndis,adb > /sys/class/android_usb/android0/functions && \
      echo 1 > /sys/class/android_usb/android0/enable && \
      setprop service.adb.root 1 && \
      start adbd' \
  http://192.168.42.129/run
```

### Method 2: Permanent Fix (survives reboot)

Patch the init script directly:

```bash
curl --digest -u admin:admin -X POST \
  -d 'mount -o rw,remount /
      sed -i "s/functions rndis$/functions rndis,adb/" /init.qcom.usb.rc
      sed -i "/sys.usb.config=rndis,adb/,+1 s/functions rndis$/functions rndis,adb/" /init.qcom.usb.rc
      sed -i "s|write /sys/class/android_usb/android0/functions rndis\b|write /sys/class/android_usb/android0/functions rndis,adb|" /init.qcom.usb.rc
      echo "Patched:"
      grep "functions rndis,adb" /init.qcom.usb.rc' \
  http://192.168.42.129/run
```

### Method 3: Set Persistent Property

```bash
setprop persist.sys.usb.config rndis,adb
```

This property is read at boot. If init.rc triggers on the persist prop, ADB will activate.

## Verification

```bash
# Check USB functions
cat /sys/class/android_usb/android0/functions
# Should show: rndis,adb

# Check ADB host-side
adb devices
# Should show device
```

## ADB Access

```bash
# ADB root mode
adb root
adb shell
```

## What We Learned

- The **USB gadget subsystem** uses configfs (via `/sys/class/android_usb/android0/`)
- Functions are comma-separated in the `functions` file
- `rndis,adb` means both RNDIS networking AND ADB are active
- The init script bug means the comma and `adb` are **silently dropped**
- ADB driver (`adbd`) is separate — it needs to be started after the function is configured
