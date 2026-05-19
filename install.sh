#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║         Arch / EndeavourOS Setup         ║"
echo "╚══════════════════════════════════════════╝"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. AUR helper ────────────────────────────────────────────
echo "[1/7] Checking AUR helper..."
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
fi

# ── 2. Base packages ─────────────────────────────────────────
echo "[2/7] Installing base packages..."
sudo pacman -S --needed --noconfirm - < "$SCRIPT_DIR/packages/base.txt"

# ── 3. AUR packages ──────────────────────────────────────────
echo "[3/7] Installing AUR packages..."
grep -v '^#' "$SCRIPT_DIR/packages/aur.txt" | grep -v '^$' | xargs yay -S --needed --noconfirm

# ── 4. hypr-utils ────────────────────────────────────────────
echo "[4/7] Installing hypr-utils..."
git clone https://github.com/tosi4ka/hypr-utils.git /tmp/hypr-utils
cd /tmp/hypr-utils && ./install.sh
cd "$SCRIPT_DIR"

# ── 5. Dotfiles ──────────────────────────────────────────────
echo "[5/7] Copying configs..."
mkdir -p ~/.config
for dir in "$SCRIPT_DIR"/configs/*/; do
    name=$(basename "$dir")
    cp -r "$dir" ~/.config/"$name"/
done

# Wallpapers directory — place your wallpapers here after install
mkdir -p ~/Pictures/wallpapers
echo "NOTE: Put your wallpapers in ~/Pictures/wallpapers/ and name the default wallpaper.jpg"

# ── 6. Services ──────────────────────────────────────────────
echo "[6/7] Enabling services..."
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
echo "[7/7] Setting up NVM..."
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
