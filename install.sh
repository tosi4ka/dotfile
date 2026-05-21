#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║         Arch / EndeavourOS Setup         ║"
echo "╚══════════════════════════════════════════╝"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. AUR helper ────────────────────────────────────────────
echo "[1/8] Checking AUR helper..."
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
fi

# ── 2. Base packages ─────────────────────────────────────────
echo "[2/8] Installing base packages..."
grep -v '^#' "$SCRIPT_DIR/packages/base.txt" | grep -v '^$' | sudo pacman -S --needed --noconfirm -

# ── 3. AUR packages ──────────────────────────────────────────
echo "[3/8] Installing AUR packages..."
grep -v '^#' "$SCRIPT_DIR/packages/aur.txt" | grep -v '^$' | yay -S --needed --noconfirm -

# ── 4. hypr-utils ────────────────────────────────────────────
echo "[4/8] Installing hypr-utils..."
git clone https://github.com/tosi4ka/hypr-utils.git /tmp/hypr-utils
cd /tmp/hypr-utils && ./install.sh
cd "$SCRIPT_DIR"

# ── 5. Dotfiles ──────────────────────────────────────────────
echo "[5/8] Copying configs..."
mkdir -p ~/.config
for dir in "$SCRIPT_DIR"/configs/*/; do
    name=$(basename "$dir")
    [[ "$name" == "systemd" ]] && continue
    cp -r "$dir" ~/.config/"$name"/
done

# Systemd user services
mkdir -p ~/.config/systemd/user
cp "$SCRIPT_DIR"/configs/systemd/user/*.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable char-picker

# Wallpapers directory
mkdir -p ~/SomeFiles/img
echo "NOTE: Put your wallpapers in ~/SomeFiles/img/"

# ── 6. Power mode script ─────────────────────────────────────
echo "[6/8] Installing power mode script..."
sudo cp "$SCRIPT_DIR/scripts/set-power-mode" /usr/local/bin/set-power-mode
sudo chmod +x /usr/local/bin/set-power-mode
REAL_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
echo "$REAL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/set-power-mode" | sudo tee /etc/sudoers.d/set-power-mode > /dev/null

# ── 7. Services ──────────────────────────────────────────────
echo "[7/8] Enabling services..."
sudo systemctl enable --now bluetooth
sudo systemctl enable --now docker
sudo systemctl enable --now cups
sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now thermald
sudo systemctl enable --now irqbalance
sudo systemctl enable --now earlyoom
sudo systemctl enable --now acpid
sudo systemctl enable --now fstrim.timer
sudo usermod -aG docker "$USER"
sudo usermod -aG input "$USER"

# ── 7. NVM + Node ────────────────────────────────────────────
echo "[8/8] Setting up NVM..."
if ! grep -q 'init-nvm.sh' ~/.bashrc; then
    echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
fi
source /usr/share/nvm/init-nvm.sh
nvm install --lts

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║              Setup complete!             ║"
echo "║         Reboot: sudo reboot              ║"
echo "╚══════════════════════════════════════════╝"
