# 07 — Dashboard and API Server

## Overview

A web-based monitoring dashboard with live system stats, service status, and quick actions. Uses a lightweight busybox httpd server with CGI for the JSON API.

## Architecture

```
Browser ──► :8080 (busybox httpd)
                ├── index.html (dashboard)
                └── cgi-bin/api.sh (JSON API)
                        ├── ?cmd=status  → system stats
                        ├── ?cmd=log     → system log
                        └── ?cmd=exec:cmd → run command
```

## Setup

### Step 1: Create WWW directory

```bash
mkdir -p /data/www/htdocs /data/www/cgi-bin
```

### Step 2: Deploy dashboard HTML

The dashboard is a single-page HTML file with embedded CSS/JS. Copy it to:
```bash
cp dashboard.html /data/www/htdocs/index.html
```

### Step 3: Create API CGI script

```bash
cat > /data/www/cgi-bin/api.sh << "CGIEOF"
#!/system/xbin/ash
echo "Content-Type: application/json"
echo ""

CMD="${QUERY_STRING#*=}"

case "$CMD" in
    status)
        LOAD=$(cat /proc/loadavg | cut -d" " -f1-3)
        MEM_TOTAL=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
        MEM_FREE=$(cat /proc/meminfo | grep MemFree | awk '{print $2}')
        SSH_UP=$(pidof dropbearmulti >/dev/null 2>&1 && echo 1 || echo 0)
        FTP_UP=$(netstat -tln 2>/dev/null | grep -q :21 && echo 1 || echo 0)
        WG_UP=$(pidof wireguard-go >/dev/null 2>&1 && echo 1 || echo 0)
        echo "{\"load\":\"$LOAD\",\"mem_total\":$MEM_TOTAL,\"mem_free\":$MEM_FREE,\"ssh\":$SSH_UP,\"ftp\":$FTP_UP,\"wg\":$WG_UP}"
        ;;
    log)
        LOG=$(dmesg 2>/dev/null | tail -30)
        echo "{\"log\":\"$LOG\"}"
        ;;
    exec:*)
        EXEC_CMD="${CMD#exec:}"
        RESULT=$(timeout 5 $EXEC_CMD 2>&1 | head -30)
        echo "{\"result\":\"$RESULT\"}"
        ;;
esac
CGIEOF
chmod 755 /data/www/cgi-bin/api.sh
```

### Step 4: Start HTTP server

```bash
/system/xbin/busybox httpd -p 8080 -h /data/www/htdocs &
```

## Dashboard Features

- **System**: CPU (estimated from load), Memory (used/free), Disk usage, Process count
- **Network**: IP address, SIM status, baseband version
- **Services**: SSH, FTP, WireGuard, ADB status with visual indicators
- **Quick Actions**: Reboot, restart SSH, restart FTP, show WireGuard status
- **System Log**: Live dmesg output with auto-refresh
- **Auto-refresh**: Dashboard updates every 10 seconds, log every 60 seconds

## API Endpoints

| Endpoint | Returns |
|----------|---------|
| `?cmd=status` | JSON with system stats and service states |
| `?cmd=log` | JSON with last 30 dmesg lines |
| `?cmd=exec:command` | JSON with command output |

## Access

```
Dashboard: http://192.168.42.129:8080/
API:       http://192.168.42.129:8080/cgi-bin/api.sh?cmd=status
```

## Making It Persistent

Add to boot_fix.sh:
```bash
mkdir -p /data/www/htdocs /data/www/cgi-bin
cp /data/data/com.webkey/files/dashboard.html /data/www/htdocs/index.html
/system/xbin/busybox httpd -p 8080 -h /data/www/htdocs &
```
