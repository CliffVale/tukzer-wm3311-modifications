# 04 - SSH Server (Dropbear)

## Why Dropbear?

OpenSSH is too large for embedded systems. Dropbear is a lightweight SSH server (~200KB static), supports public key and password auth, and is designed for embedded Linux.

## Cross-Compilation

We built Dropbear 2022.83 as a statically-linked ARM binary using the Zig cross-compiler.

\`\`\`bash
# Install zig (if not already)
sudo pacman -S zig

# Download Dropbear
wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2022.83.tar.bz2
tar xf dropbear-2022.83.tar.bz2
cd dropbear-2022.83

# Configure for static ARM build
./configure --host=arm-linux --enable-static \
  CC="zig cc -target arm-linux-musleabi -static -O2"

# Build the multi-call binary
make -j$(nproc) MULTI=1 SCPROGRAMS=dropbear dropbearkey dropbearconvert dbclient
\`\`\`

## Key Challenges Solved

### Challenge 1: "User 'root' has invalid shell, rejected"

**Root Cause**: Dropbear validates the user's shell via stat() + S_ISREG() + access(X_OK) AND checks /etc/shells. On Android:

- /system/bin/sh is a symlink to mksh
- stat() follows symlinks but S_ISREG() is checked on the target
- The shell path MUST appear in /etc/shells

**Fix**:
\`\`\`bash
# Create /etc/shells with valid shell paths
mkdir -p /etc
cat > /etc/shells << "EOF"
/system/xbin/busybox
/system/bin/mksh
/system/xbin/ash
/system/xbin/ssh-shell.sh
EOF

# Set root shell to a path that exists AND is in /etc/shells
echo "root::0:0:root:/root:/system/xbin/ssh-shell.sh" > /etc/passwd
\`\`\`

### Challenge 2: Public Key Auth Rejected

**Root Cause**: The Dropbear-generated private key uses a different format from OpenSSH. The OpenSSH client can't read Dropbear keys.

**Fix**: Convert the key or generate keys on the client side:

\`\`\`bash
# Option 1: Convert Dropbear key to OpenSSH format
/System/xbin/dropbearmulti dropbearconvert dropbear openssh /etc/dropbear/dropbear_rsa_host_key /root/.ssh/id_rsa

# Option 2: Generate key on client
ssh-keygen -t ed25519 -f ~/.ssh/tukzer
# Then add public key to /root/.ssh/authorized_keys
\`\`\`

### Challenge 3: No PATH for non-interactive SSH commands

**Root Cause**: When SSH executes \`ssh host "command"\`, the shell runs with -c which doesn't source .profile. Android shells don't set PATH.

**Fix**: Create a shell wrapper:

\`\`\`bash
cat > /system/xbin/ssh-shell.sh << "EOF"
#!/system/xbin/ash
export PATH=/sbin:/system/sbin:/system/bin:/system/xbin:/data/data/com.webkey/files
export HOME=/root
export USER=root
exec /system/bin/mksh "$@"
EOF
chmod 755 /system/xbin/ssh-shell.sh
\`\`\`

### Challenge 4: Password Auth Fails

**Root Cause**: Android 4.4 Bionic libc crypt() supports MD5 (\$1\$) but NOT SHA-512 (\$6\$).

**Fix**: Use MD5-crypt:

\`\`\`bash
# Generate MD5 hash
HASH=$(openssl passwd -1 -salt x5 "admin")
echo "root:${HASH}:0:0:root:/root:/system/xbin/ssh-shell.sh" > /etc/passwd
\`\`\`

## Running Dropbear

\`\`\`bash
# Generate host keys
mkdir -p /etc/dropbear
dropbearkey -t rsa -s 2048 -f /etc/dropbear/dropbear_rsa_host_key
dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key

# Start on port 2222
dropbear -p 2222 -E > /tmp/dropbear.log 2>&1 &
\`\`\`

## Client Connection

\`\`\`bash
# SSH config (~/.ssh/config)
# Host tukzer
#     HostName 192.168.42.129
#     Port 2222
#     User root
#     IdentityFile ~/.ssh/tukzer/id_rsa

ssh tukzer "id; uptime; df /system"
\`\`\`
