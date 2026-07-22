# Pre-compiled Binaries

This repository does **not** host pre-compiled ARM binaries. You are encouraged to build your own following the guides in the docs/ directory.

## Why No Pre-built Binaries?

1. **Security** — You should verify what you're running on your device
2. **Trust** — Build your own to ensure no malware
3. **Reproducibility** — Your build chain may differ from ours

## Build Guides

| Binary | Guide | Build Time |
|--------|-------|------------|
| busybox | Download from osm0sis NDK build | Pre-built available |
| dropbearmulti | docs/04-ssh-server.md | ~5 min with zig |
| wireguard-go | docs/06-wireguard-vpn.md | ~2 min with Go |
| wg | docs/06-wireguard-vpn.md | ~1 min with zig |

## Build Host Requirements

- **Linux** (Arch, Debian, Ubuntu, Fedora)
- **Zig 0.16+** — for C cross-compilation
- **Go 1.26+** — for Go cross-compilation
- **git**, **make**, standard build tools

## Build Commands

### Dropbear
```bash
git clone https://github.com/mkj/dropbear dropbear-2022.83
cd dropbear-2022.83
./configure --host=arm-linux --enable-static CC="zig cc -target arm-linux-musleabi -static"
make -j$(nproc) MULTI=1
```

### wireguard-go
```bash
git clone --depth 1 https://git.zx2c4.com/wireguard-go
cd wireguard-go
GOOS=linux GOARCH=arm CGO_ENABLED=0 go build -o wireguard-go-arm
```

### wg-tools
```bash
git clone --depth 1 https://git.zx2c4.com/wireguard-tools
cd wireguard-tools/src
CC="zig cc -target arm-linux-musleabi -O2 -static" \
  make WITH_SYSTEMDUNITS=no WITH_BASHCOMPLETION=no WITH_WGQUICK=no
```
