# 05 - FTP Server

## Overview

Busybox includes ftpd - a lightweight FTP server. This provides anonymous read-write file access to /data/shared/.

## Setup

\`\`\`bash
# Create shared directories
mkdir -p /data/shared/downloads /data/shared/upload
chmod 777 /data/shared /data/shared/downloads /data/shared/upload

# Start FTP server (anonymous, writable)
/system/xbin/busybox tcpsvd -vE 0.0.0.0 21 \
  /system/xbin/busybox ftpd -w -A /data/shared &
\`\`\`

## Usage

\`\`\`bash
# List files
curl ftp://192.168.42.129/downloads/

# Download
curl -O ftp://192.168.42.129/downloads/file.txt

# Upload
curl -T myfile.txt ftp://192.168.42.129/upload/
\`\`\`

## Options

| Flag | Meaning |
|------|---------|
| -w | Allow uploads |
| -A | No login required (runs as ftpd's UID) |
| -v | Log errors to stderr |
| [DIR] | Chroot to this directory |

## Security Note

Anonymous FTP with write access is only recommended for trusted local networks (RNDIS USB). Do not expose port 21 to the internet without adding authentication.
