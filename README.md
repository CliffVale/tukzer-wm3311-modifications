# Tukzer WM3311 / UZ801 — Android 4.4.4 Modifications

> **Building on the [tukzer-wm3311-research](https://github.com/CliffVale/tukzer-wm3311-research) foundation — this repo documents practical modifications to the stock Android firmware without opening the device or using EDL mode.**

## 🎯 What This Repo Covers

All modifications are performed **remotely via the Webkey HTTP API** (`--digest -u admin:admin http://192.168.42.129/run`) — no physical access, no ADB required (though ADB is enabled for convenience).

| Modification | Status | Method |
|-------------|--------|--------|
| **Root ADB** | ✅ Persistent | Fixed USB gadget config bug in `init.qcom.usb.rc` |
| **Busybox** | ✅ 390 applets | Static NDK ARM build pushed to `/system/xbin/` |
| **SSH (Dropbear)** | ✅ Publickey + Password | Cross-compiled static ARM binary, key auth, MD5 password |
| **FTP** | ✅ Anonymous RW | Busybox `ftpd` via `tcpsvd` |
| **WireGuard VPN** | ✅ 10.0.0.1/24 tunnel | Userspace `wireguard-go` + `wg-tools` cross-compiled for ARM |
| **Dashboard** | ✅ Live monitoring | Busybox `httpd` + CGI JSON API on port 8080 |
| **SMS Gateway** | ⏳ Tools ready, needs SIM | BeanShell script + `service call isms` + shell tools |
| **Boot Persistence** | ✅ Auto-start all services | Patched `start.sh` calls `boot_fix.sh` on every boot |

## 🔥 Key Discovery: Root Shell via HTTP

The Webkey framework exposes a `/run` endpoint that executes arbitrary shell commands as **root**:

```bash
curl --digest -u admin:admin -X POST \
  -d 'id; mount -o rw,remount /system' \
  http://192.168.42.129/run
```

This is the foundation for every modification in this repo.

## 📖 Documentation

| Doc | Content |
|-----|---------|
| [Getting Started](docs/01-getting-started.md) | Prerequisites, initial access, filesystem overview |
| [ADB Persistence](docs/02-adb-access.md) | Fixing the USB gadget init bug for permanent `rndis,adb` |
| [Busybox](docs/03-busybox.md) | Installing busybox with all applets |
| [SSH Server](docs/04-ssh-server.md) | Cross-compiling Dropbear, debugging "invalid shell", key auth |
| [FTP](docs/05-ftp-server.md) | Anonymous file server via busybox ftpd |
| [WireGuard VPN](docs/06-wireguard-vpn.md) | Cross-compiling wireguard-go + wg-tools for ARM |
| [Dashboard](docs/07-dashboard.md) | Web dashboard with live API, monitoring, quick actions |
| [SMS Gateway](docs/08-sms-gateway.md) | Tools for sending/receiving SMS via Android telephony API |
| [Boot Persistence](docs/09-boot-persistence.md) | boot_fix.sh — all services auto-start on power-on |

## 🚀 Quick Start

```bash
# 1. Connect device via USB (RNDIS mode, IP 192.168.42.129)
# 2. Verify access
curl --digest -u admin:admin http://192.168.42.129/run -d 'id'

# 3. Run the full setup
ssh tukzer "sh -c \"\$(wget -qO- https://raw.githubusercontent.com/CliffVale/tukzer-wm3311-modifications/main/scripts/setup-all.sh)\""

# 4. Connect via SSH
ssh tukzer

# 5. Open dashboard
firefox http://192.168.42.129:8080/
```

## ⚙️ Prerequisites

- **Tukzer WM3311** (or any UZ801 v3.x / UFI-series dongle with Webkey firmware)
- **USB cable** for initial connection
- **Linux / macOS / Windows** with `curl` and SSH client
- **Zig 0.16+** (for cross-compiling ARM binaries)
- **Go 1.26+** (for wireguard-go)

## 📂 Repository Contents

```
├── README.md            ← This file
├── LICENSE              ← MIT
├── docs/                ← Step-by-step guides
├── scripts/             ← Ready-to-run shell scripts
├── configs/             ← Configuration files
├── binaries/            ← Build guide (no pre-built binaries)
└── api/                 ← Web dashboard source
```

## 🔗 Related

- [tukzer-wm3311-research](https://github.com/CliffVale/tukzer-wm3311-research) — Hardware specs, firmware backup, EDL flashing, custom OS
- [OpenStick Project](https://github.com/OpenStick) — Community efforts on similar dongles
- [UZ801 on OpenWrt Forum](https://forum.openwrt.org/t/uz801-v3-0-qualcomm-4g-lte-wifi-mini-router/111648)
