#!/bin/bash

echo "=== Pakages insall ==="

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
    libsecret

# AUR pakets
yay -S --noconfirm \
    visual-studio-code-bin \
    google-chrome \
    viber \
    zoom \
    nvm \
    whitesur-gtk-theme \
    whitesur-icon-theme-git \
    timeshift \
    brother-cups-wrapper-laser

echo "=== Servis settings  ==="
sudo systemctl enable docker
sudo systemctl enable tlp
sudo systemctl enable cups
sudo systemctl enable avahi-daemon
sudo systemctl mask power-profiles-daemon.service
sudo usermod -aG docker $USER

echo "=== nvm settings ==="
echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
source ~/.bashrc
nvm install --lts

echo "=== darkman settings ==="
mkdir -p ~/.config/darkman
cat > ~/.config/darkman/config.yaml << EOF
lat: 48.8566
lng: 2.3522
usegeoclue: false
EOF
systemctl --user enable darkman
systemctl --user start darkman

echo "=== Settings scripts of themes ==="
mkdir -p ~/.local/share/dark-mode.d
mkdir -p ~/.local/share/light-mode.d

cat > ~/.local/share/dark-mode.d/xfce.sh << EOF
#!/bin/bash
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark"
EOF

cat > ~/.local/share/light-mode.d/xfce.sh << EOF
#!/bin/bash
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Light"
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur"
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Light"
EOF

chmod +x ~/.local/share/dark-mode.d/xfce.sh
chmod +x ~/.local/share/light-mode.d/xfce.sh

echo "=== Settings printer Brother ==="
sudo lpadmin -p Brother-HL-L2400DWE -E -v "ipp://192.168.1.168/ipp/print" -m everywhere

echo "=== Portainer ==="
docker volume create portainer_data
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# Memory optimization
sudo pacman -S --noconfirm zram-generator earlyoom
sudo systemctl enable earlyoom
echo 'vm.swappiness=80' | sudo tee /etc/sysctl.d/99-swappiness.conf

# Zram config
sudo bash -c 'cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF'
sudo systemctl daemon-reload
sudo systemctl enable systemd-zram-setup@zram0

# Swap 16GB btrfs
sudo btrfs filesystem mkswapfile --size 16g /swap/swapfile
sudo swapon /swap/swapfile

# Performance
sudo pacman -S --noconfirm thermald ananicy-cpp preload
sudo systemctl enable thermald ananicy-cpp preload fstrim.timer

echo "✅ All instal! Reboot system: reboot"
