#!/bin/bash
# ============================================================
# EndeavourOS Setup Script
# Acer Swift 3 SF314-512 | i7-1260P | 8GB RAM | 500GB M.2
# ============================================================

set -e

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     EndeavourOS Full Setup Script        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ============================================================
# 1. SYSTEM PACKAGES
# ============================================================
echo "=== [1/10] Installing system packages ==="
sudo pacman -S --noconfirm \
    git \
    go \
    docker \
    docker-compose \
    telegram-desktop \
    vlc \
    libreoffice-fresh \
    nmap \
    htop \
    btop \
    tlp \
    tlp-rdw \
    xfce4-sensors-plugin \
    xfce4-systemload-plugin \
    xfce4-genmon-plugin \
    xorg-xev \
    wine \
    wine-mono \
    winetricks \
    plank \
    darkman \
    fprintd \
    cups \
    avahi \
    gnome-keyring \
    libsecret \
    pamixer \
    thermald \
    irqbalance \
    ccache \
    mold \
    zram-generator \
    earlyoom \
    profile-sync-daemon \
    xdotool \
    brother-hll2400dwe-cups 2>/dev/null || true

# ============================================================
# 2. AUR PACKAGES
# ============================================================
echo "=== [2/10] Installing AUR packages ==="
yay -S --noconfirm \
    visual-studio-code-bin \
    google-chrome \
    viber \
    zoom \
    nvm \
    whitesur-gtk-theme \
    whitesur-icon-theme-git \
    timeshift \
    ananicy-cpp \
    preload \
    libfprint-git

# ============================================================
# 3. SERVICES
# ============================================================
echo "=== [3/10] Configuring services ==="
sudo systemctl enable docker
sudo systemctl enable tlp
sudo systemctl enable cups
sudo systemctl enable avahi-daemon
sudo systemctl enable thermald
sudo systemctl enable irqbalance
sudo systemctl enable earlyoom
sudo systemctl enable ananicy-cpp
sudo systemctl enable preload
sudo systemctl enable fstrim.timer
sudo systemctl mask power-profiles-daemon.service
sudo usermod -aG docker $USER
sudo usermod -aG plugdev $USER

# ============================================================
# 4. NVM + NODE
# ============================================================
echo "=== [4/10] Configuring NVM + Node.js ==="
echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
source ~/.bashrc
nvm install --lts

# ============================================================
# 5. CCACHE
# ============================================================
echo "=== [5/10] Configuring ccache ==="
echo 'export PATH="/usr/lib/ccache/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# ============================================================
# 6. DARKMAN (Auto dark/light theme)
# ============================================================
echo "=== [6/10] Configuring darkman (Paris location) ==="
mkdir -p ~/.config/darkman
cat > ~/.config/darkman/config.yaml << EOF
lat: 48.8566
lng: 2.3522
usegeoclue: false
EOF

systemctl --user enable darkman
systemctl --user start darkman

# Theme switch scripts
mkdir -p ~/.local/share/dark-mode.d
mkdir -p ~/.local/share/light-mode.d

cat > ~/.local/share/dark-mode.d/xfce.sh << 'EOF'
#!/bin/bash
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark"
EOF

cat > ~/.local/share/light-mode.d/xfce.sh << 'EOF'
#!/bin/bash
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Light"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Light"
EOF

chmod +x ~/.local/share/dark-mode.d/xfce.sh
chmod +x ~/.local/share/light-mode.d/xfce.sh

# ============================================================
# 7. MEMORY OPTIMIZATION
# ============================================================
echo "=== [7/10] Memory optimization ==="

# Swappiness
echo 'vm.swappiness=80' | sudo tee /etc/sysctl.d/99-swappiness.conf

# ZRAM
sudo bash -c 'cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF'
sudo systemctl daemon-reload
sudo systemctl enable systemd-zram-setup@zram0

# Swap file on btrfs (16GB)
sudo mkdir -p /swap
sudo btrfs filesystem mkswapfile --size 16g /swap/swapfile 2>/dev/null || true
sudo swapon /swap/swapfile 2>/dev/null || true

# ============================================================
# 8. NETWORK OPTIMIZATION (Wi-Fi 5GHz fix)
# ============================================================
echo "=== [8/10] Network optimization ==="
sudo bash -c 'cat > /etc/NetworkManager/conf.d/wifi-powersave.conf << EOF
[connection]
wifi.powersave = 2
EOF'

# ============================================================
# 9. PRINTER (Brother HL-L2400DWE)
# ============================================================
echo "=== [9/10] Configuring Brother printer ==="
sudo systemctl start cups
sudo lpadmin -p Brother-HL-L2400DWE -E \
    -v "ipp://192.168.1.168/ipp/print" \
    -m everywhere 2>/dev/null || true

# ============================================================
# 10. PORTAINER (Docker GUI)
# ============================================================
echo "=== [10/10] Starting Portainer ==="
docker volume create portainer_data 2>/dev/null || true
docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest 2>/dev/null || true

# ============================================================
# FINGERPRINT UDEV RULE
# ============================================================
echo "=== Fingerprint udev rule ==="
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="04f3", ATTRS{idProduct}=="0c7f", MODE="0664", GROUP="plugdev"' | \
    sudo tee /etc/udev/rules.d/70-fingerprint.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# ============================================================
# SLEEP CONFIG
# ============================================================
echo "=== Sleep configuration ==="
sudo bash -c 'cat > /etc/systemd/sleep.conf << EOF
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
SuspendState=mem
HibernateDelaySec=15min
EOF'

# ============================================================
# WINECFG
# ============================================================
echo "=== Wine initial config ==="
winecfg &
sleep 5
pkill winecfg 2>/dev/null || true

# ============================================================
# PROFILE SYNC DAEMON
# ============================================================
echo "=== Profile sync daemon ==="
systemctl --user enable psd

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           ✅ Setup Complete!             ║"
echo "║                                          ║"
echo "║  After reboot:                           ║"
echo "║  • Run: winecfg (select Windows 10)      ║"
echo "║  • Close Firefox before starting psd     ║"
echo "║  • Portainer: https://localhost:9443     ║"
echo "║  • Timeshift: create first snapshot      ║"
echo "║                                          ║"
echo "║  Reboot now: sudo reboot                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""
