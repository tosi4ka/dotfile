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
echo "=== [1/13] Installing system packages ==="
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
    xorg-xset \
    xdotool \
    rofi \
    python-gobject \
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
    cpupower \
    brother-hll2400dwe-cups 2>/dev/null || true

# ============================================================
# 2. AUR PACKAGES
# ============================================================
echo "=== [2/13] Installing AUR packages ==="
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
echo "=== [3/13] Configuring services ==="
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
sudo usermod -aG input $USER

# ============================================================
# 4. NVM + NODE
# ============================================================
echo "=== [4/13] Configuring NVM + Node.js ==="
echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
source ~/.bashrc
nvm install --lts

# ============================================================
# 5. CCACHE + ALIASES
# ============================================================
echo "=== [5/13] Configuring ccache and aliases ==="
echo 'export PATH="/usr/lib/ccache/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo "alias power-save='sudo cpupower frequency-set -g powersave'" >> ~/.bashrc
echo "alias power-performance='sudo cpupower frequency-set -g performance'" >> ~/.bashrc
source ~/.bashrc

# ============================================================
# 6. DARKMAN (Auto dark/light theme)
# ============================================================
echo "=== [6/13] Configuring darkman (Paris location) ==="
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
# 7. POWER MODE SCRIPTS
# ============================================================
echo "=== [7/13] Configuring power mode scripts ==="
mkdir -p ~/.local/bin

cat > ~/.local/bin/power-status.sh << 'EOF'
#!/bin/bash
gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
if [ "$gov" = "performance" ]; then
    echo "<txt>⚡ Perf</txt>"
else
    echo "<txt>🔋 Save</txt>"
fi
EOF

cat > ~/.local/bin/power-toggle.sh << 'EOF'
#!/bin/bash
gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
if [ "$gov" = "performance" ]; then
    sudo cpupower frequency-set -g powersave
else
    sudo cpupower frequency-set -g performance
fi
EOF

chmod +x ~/.local/bin/power-status.sh
chmod +x ~/.local/bin/power-toggle.sh

# sudo без пароля для cpupower
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/cpupower" | \
    sudo tee /etc/sudoers.d/cpupower

# ============================================================
# 8. MEMORY OPTIMIZATION
# ============================================================
echo "=== [8/13] Memory optimization ==="
echo 'vm.swappiness=80' | sudo tee /etc/sysctl.d/99-swappiness.conf

sudo bash -c 'cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF'
sudo systemctl daemon-reload
sudo systemctl enable systemd-zram-setup@zram0

sudo mkdir -p /swap
sudo btrfs filesystem mkswapfile --size 16g /swap/swapfile 2>/dev/null || true
sudo swapon /swap/swapfile 2>/dev/null || true

# ============================================================
# 9. NETWORK OPTIMIZATION (Wi-Fi 5GHz fix)
# ============================================================
echo "=== [9/13] Network optimization ==="
sudo bash -c 'cat > /etc/NetworkManager/conf.d/wifi-powersave.conf << EOF
[connection]
wifi.powersave = 2
EOF'

# ============================================================
# 10. PRINTER (Brother HL-L2400DWE)
# ============================================================
echo "=== [10/13] Configuring Brother printer ==="
sudo systemctl start cups
sudo lpadmin -p Brother-HL-L2400DWE -E \
    -v "ipp://192.168.1.168/ipp/print" \
    -m everywhere 2>/dev/null || true

# ============================================================
# 11. PORTAINER (Docker GUI)
# ============================================================
echo "=== [11/13] Starting Portainer ==="
sudo systemctl start docker
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
# 12. KEYBOARD — US+RU layouts
# ============================================================
echo "=== [12/13] Keyboard layouts ==="

# Раскладки: US (стандартный @ на Shift+2) + RU, переключение Win+Space
xfconf-query -c keyboard-layout -p /Default/XkbDisable -s false --create -t bool
xfconf-query -c keyboard-layout -p /Default/XkbLayout  -s "us,ru" --create -t string
xfconf-query -c keyboard-layout -p /Default/XkbVariant -s "," --create -t string
xfconf-query -c keyboard-layout -p /Default/XkbOptions -s "grp:win_space_toggle" --create -t string

# Применить в текущей сессии
setxkbmap -layout us,ru -option "grp:win_space_toggle" 2>/dev/null || true

# ============================================================
# 13. CHARACTER PICKER (Mac-like press-and-hold)
# ============================================================
echo "=== [13/13] Character picker ==="

pip install evdev python-xlib --break-system-packages -q

# Основной демон
cat > ~/.local/bin/char-picker.py << 'PYEOF'
#!/usr/bin/env python3
import evdev, subprocess, time, sys, os, selectors, fcntl, struct
from evdev import InputDevice, ecodes as e
from Xlib import X, display as xdisplay
from Xlib.ext import xtest

VARIANTS = {
    e.KEY_A: ['à','á','â','ã','ä','å','æ','ā','ă','ą'],
    e.KEY_E: ['è','é','ê','ë','ě','ę','ē','ė','ə'],
    e.KEY_I: ['ì','í','î','ï','ī','į','ı','ĭ'],
    e.KEY_O: ['ò','ó','ô','õ','ö','ø','œ','ō','ŏ'],
    e.KEY_U: ['ù','ú','û','ü','ū','ů','ű','ŭ','ų'],
    e.KEY_Y: ['ý','ÿ','ŷ'],
    e.KEY_N: ['ñ','ń','ņ','ň','ŋ'],
    e.KEY_C: ['ç','ć','č','ĉ','ċ'],
    e.KEY_S: ['ś','š','ŝ','ş','ß'],
    e.KEY_Z: ['ź','ż','ž'],
    e.KEY_L: ['ł','ļ','ľ','ĺ'],
    e.KEY_R: ['ř','ŗ'],
    e.KEY_D: ['ð','đ'],
    e.KEY_T: ['þ','ţ','ť'],
    e.KEY_G: ['ğ','ĝ','ġ'],
    e.KEY_H: ['ħ','ĥ'],
    e.KEY_MINUS: ['–','—','·','•'],
    e.KEY_EQUAL: ['≠','≈','±','×','÷'],
    e.KEY_SLASH: ['÷','⁄'],
    e.KEY_DOT:   ['…','·','•'],
}

HOLD_TIME  = 0.45
DISPLAY    = os.environ.get('DISPLAY', ':0')
XAUTHORITY = os.environ.get('XAUTHORITY', os.path.expanduser('~/.Xauthority'))
POPUP      = os.path.expanduser('~/.local/bin/char-picker-popup.py')
XDOTOOL    = '/usr/bin/xdotool'
XSET       = '/usr/bin/xset'
EVIOCSREP  = 0x40084503

def xenv():
    return {**os.environ, 'DISPLAY': DISPLAY, 'XAUTHORITY': XAUTHORITY}

def x11_repeat(on):
    subprocess.run([XSET, 'r', 'on' if on else 'off'],
                   env=xenv(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def kernel_repeat(kbd, delay, period):
    try:
        fcntl.ioctl(kbd.fd, EVIOCSREP, struct.pack('II', delay, period))
    except Exception:
        pass

def fake_keyup(kc):
    try:
        dpy = xdisplay.Display(DISPLAY)
        xtest.fake_input(dpy, X.KeyRelease, kc + 8)
        dpy.flush()
        dpy.close()
    except Exception:
        pass

def show_picker(variants):
    try:
        r = subprocess.run(
            [POPUP, ' '.join(variants)],
            capture_output=True, timeout=30, env=xenv())
        if r.returncode == 0:
            s = r.stdout.decode('utf-8').strip()
            return s if s in variants else None
    except Exception as ex:
        print(f"[picker] popup error: {ex}", flush=True)
    return None

def run(kbd):
    sel = selectors.DefaultSelector()
    sel.register(kbd, selectors.EVENT_READ)
    print(f"[picker] monitoring: {kbd.name}", flush=True)

    held_kc    = None
    press_time = None

    while True:
        ready = sel.select(timeout=0.01)
        now   = time.time()

        if held_kc is not None and (now - press_time) >= HOLD_TIME:
            kc      = held_kc
            held_kc = None

            try:
                kbd.grab()
            except Exception:
                x11_repeat(True)
                kernel_repeat(kbd, 500, 20)
                continue

            fake_keyup(kc)

            deadline = time.time() + 5.0
            while time.time() < deadline:
                if sel.select(timeout=0.02):
                    try:
                        for ev in kbd.read():
                            if ev.type == e.EV_KEY and ev.code == kc and ev.value == 0:
                                deadline = 0
                    except Exception:
                        break

            try:
                kbd.ungrab()
            except Exception:
                pass

            x11_repeat(True)
            kernel_repeat(kbd, 500, 20)
            time.sleep(0.08)

            chosen = show_picker(VARIANTS.get(kc, []))
            if chosen:
                time.sleep(0.05)
                subprocess.run(
                    [XDOTOOL, 'type', '--clearmodifiers', '--delay', '0', '--', chosen],
                    env=xenv(), stderr=subprocess.DEVNULL)
            continue

        if not ready:
            continue
        try:
            events = list(kbd.read())
        except Exception:
            continue

        for ev in events:
            if ev.type != e.EV_KEY:
                continue
            if ev.value == 1 and ev.code in VARIANTS and held_kc is None:
                held_kc    = ev.code
                press_time = time.time()
                x11_repeat(False)
                kernel_repeat(kbd, 10000, 10000)
                time.sleep(0.02)
            elif ev.value == 0 and ev.code == held_kc:
                held_kc = None
                x11_repeat(True)
                kernel_repeat(kbd, 500, 20)

def find_keyboard():
    need = {e.KEY_A, e.KEY_Z, e.KEY_SPACE, e.KEY_ENTER, e.KEY_LEFTCTRL}
    best = None
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
            caps = dev.capabilities()
            if e.EV_KEY not in caps: continue
            if not need.issubset(set(caps[e.EV_KEY])): continue
            if any(x in dev.name.lower() for x in ('virtual','uinput','picker')): continue
            if best is None or 'AT Translated' in dev.name: best = dev
        except Exception: continue
    return best

def main():
    kbd = find_keyboard()
    if not kbd:
        print("[picker] Клавиатура не найдена.")
        sys.exit(1)
    try:
        run(kbd)
    except PermissionError:
        print("[picker] Нет прав. sudo usermod -aG input $USER → ребут")
        sys.exit(1)
    except KeyboardInterrupt:
        x11_repeat(True)
        kernel_repeat(kbd, 500, 20)
        try: kbd.ungrab()
        except Exception: pass
        print("[picker] Остановлен.")

if __name__ == '__main__':
    main()
PYEOF
chmod +x ~/.local/bin/char-picker.py

# GTK popup (mac-like)
cat > ~/.local/bin/char-picker-popup.py << 'PYEOF'
#!/usr/bin/env python3
import sys, subprocess, os
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

CSS = b"""
window { background: transparent; }
.popup-box {
    background-color: rgba(235, 235, 235, 0.97);
    border-radius: 12px;
    padding: 10px 14px 6px 14px;
    border: 1px solid rgba(0,0,0,0.12);
}
.char-btn {
    background-color: transparent;
    color: #1a1a1a;
    border-radius: 6px;
    border: none;
    font-size: 18px;
    min-width: 32px;
    min-height: 32px;
    margin: 0 2px;
    padding: 0;
}
.char-btn-selected {
    background-color: rgba(74, 144, 217, 0.85);
    color: white;
    border-radius: 6px;
}
.num-label { color: #999999; font-size: 9px; margin-top: 1px; }
"""

def get_cursor_pos():
    try:
        env = {**os.environ, 'DISPLAY': os.environ.get('DISPLAY', ':0')}
        out = subprocess.check_output(['xdotool', 'getmouselocation'], env=env).decode()
        x = int([p for p in out.split() if p.startswith('x:')][0].split(':')[1])
        y = int([p for p in out.split() if p.startswith('y:')][0].split(':')[1])
        return x, y
    except Exception:
        return 960, 500

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    variants = sys.argv[1].split()
    if not variants:
        sys.exit(1)

    selected = [None]
    current  = [0]
    buttons  = []

    provider = Gtk.CssProvider()
    provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    win = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
    win.set_decorated(False)
    win.set_app_paintable(True)
    win.set_keep_above(True)
    win.set_skip_taskbar_hint(True)
    win.set_skip_pager_hint(True)
    win.set_accept_focus(True)
    win.set_focus_on_map(True)

    screen = win.get_screen()
    visual = screen.get_rgba_visual()
    if visual:
        win.set_visual(visual)

    outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
    outer.get_style_context().add_class('popup-box')
    win.add(outer)

    def update_selection():
        for i, btn in enumerate(buttons):
            ctx = btn.get_style_context()
            ctx.remove_class('char-btn-selected')
            if i == current[0]:
                ctx.add_class('char-btn-selected')

    def choose(char):
        selected[0] = char
        win.destroy()
        Gtk.main_quit()

    def close():
        win.destroy()
        Gtk.main_quit()

    for i, char in enumerate(variants, 1):
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        col.set_halign(Gtk.Align.CENTER)

        btn = Gtk.Button(label=char)
        btn.get_style_context().add_class('char-btn')
        btn.set_relief(Gtk.ReliefStyle.NONE)
        btn.connect('clicked', lambda b, c=char: choose(c))
        col.pack_start(btn, False, False, 0)
        buttons.append(btn)

        num = Gtk.Label(label=str(i))
        num.get_style_context().add_class('num-label')
        col.pack_start(num, False, False, 0)

        outer.pack_start(col, False, False, 0)

    update_selection()
    win.show_all()
    win.realize()

    cx, cy  = get_cursor_pos()
    display = Gdk.Display.get_default()
    monitor = display.get_monitor_at_point(cx, cy)
    geom    = monitor.get_geometry()
    w, h    = win.get_size()
    x = max(geom.x, min(cx - w // 2, geom.x + geom.width - w))
    y = cy - h - 30
    if y < geom.y:
        y = cy + 30
    win.move(x, y)

    def grab_kb():
        win.present()
        win.grab_focus()
        seat = Gdk.Display.get_default().get_default_seat()
        seat.grab(win.get_window(),
                  Gdk.SeatCapabilities.KEYBOARD,
                  False, None, None, None, None)
        return False

    GLib.timeout_add(150, grab_kb)

    def on_key(widget, event):
        key = Gdk.keyval_name(event.keyval)
        if key == 'Escape':
            close()
        elif key in ('Return', 'KP_Enter'):
            choose(variants[current[0]])
        elif key == 'Right':
            current[0] = (current[0] + 1) % len(variants)
            update_selection()
        elif key == 'Left':
            current[0] = (current[0] - 1) % len(variants)
            update_selection()
        elif key and key.isdigit():
            idx = int(key) - 1
            if 0 <= idx < len(variants):
                choose(variants[idx])
        return True

    win.connect('key-press-event', on_key)
    win.connect('focus-out-event', lambda w, e: close())

    Gtk.main()

    if selected[0]:
        print(selected[0], end='')

if __name__ == '__main__':
    main()
PYEOF
chmod +x ~/.local/bin/char-picker-popup.py

# Toggle скрипт
cat > ~/.local/bin/char-picker-toggle.sh << 'EOF'
#!/bin/bash
if systemctl --user is-active --quiet char-picker; then
    systemctl --user stop char-picker
    notify-send "⌨ Character Picker" "Выключен 🔴" --expire-time=1500
else
    systemctl --user start char-picker
    notify-send "⌨ Character Picker" "Включён 🟢" --expire-time=1500
fi
EOF
chmod +x ~/.local/bin/char-picker-toggle.sh

# Systemd user сервис
mkdir -p ~/.config/systemd/user
python3 -c "
content = '''[Unit]
Description=Mac-like character picker
After=graphical-session.target

[Service]
Type=simple
ExecStart=/home/$USER/.local/bin/char-picker.py
Restart=on-failure
RestartSec=3
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$USER/.Xauthority

[Install]
WantedBy=default.target
'''
import os
path = os.path.expanduser('~/.config/systemd/user/char-picker.service')
with open(path, 'w') as f:
    f.write(content)
"

systemctl --user daemon-reload
systemctl --user enable char-picker

# Горячая клавиша Ctrl+Shift+P для toggle
xfconf-query -c xfce4-keyboard-shortcuts \
    -p "/commands/custom/<Primary><Shift>p" \
    -s "/home/$USER/.local/bin/char-picker-toggle.sh" \
    --create -t string 2>/dev/null || true

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

source ~/.bashrc

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           ✅ Setup Complete!             ║"
echo "║                                          ║"
echo "║  После ребута:                           ║"
echo "║  • winecfg → выбери Windows 10           ║"
echo "║  • Portainer: https://localhost:9443     ║"
echo "║  • Timeshift: создай первый снапшот      ║"
echo "║  • Панель: добавь Generic Monitor с      ║"
echo "║    ~/.local/bin/power-status.sh          ║"
echo "║  • Ctrl+Shift+P — вкл/выкл picker        ║"
echo "║  • Win+Space — смена раскладки US/RU     ║"
echo "║                                          ║"
echo "║  Reboot: sudo reboot                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""