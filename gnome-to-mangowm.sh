#!/usr/bin/env bash
set -euo pipefail

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Please run as root (e.g., sudo ./gnome-to-mangowm.sh)"
  exit 1
fi

RELEASEVER="$(rpm -E %fedora)"
echo "[+] Starting Pure MangoWM + Noctalia Conversion (Target: Fedora $RELEASEVER)"
echo "[+] This will install ONLY the compositor, shell, and essential Wayland utilities."
echo "[+] Your existing Fedora base, codecs, and GNOME setup remain completely untouched."
read -p "[?] Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "[-] Aborted."
  exit 1
fi

echo "[+] Step 1/3: Enabling Terra Repository..."
dnf install -y --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$RELEASEVER" terra-release

echo "[+] Step 2/3: Installing MangoWM, Noctalia & Core Wayland Utilities..."
dnf install -y \
  mangowm noctalia xwayland \
  foot \
  wl-clipboard grim slurp \
  brightnessctl upower

echo "[+] Step 3/3: Deploying System-Wide Configurations..."

# 1. Create Wayland Session Entry for GDM
mkdir -p /usr/share/wayland-sessions
cat <<'EOF' > /usr/share/wayland-sessions/mango.desktop
[Desktop Entry]
Name=MangoWM
Comment=Mango Wayland Compositor with Noctalia Shell
Exec=mango
Type=Application
DesktopNames=Mango
EOF

# 2. MangoWM Base Config
mkdir -p /etc/mango/config.d /usr/share/mango/config.d
cat <<'EOF_MANGO' > /etc/mango/config.conf
# System-wide MangoWM Configuration
exec-once = noctalia

# Visual Effects (SceneFX)
blur = 1
shadows = 1
blur_layer = 0
layer_shadows = 0
blur_optimized = 1
blur_params_radius = 5
shadows_size = 4
shadows_blur = 12
shadowscolor = 0x000000ff

# Laptop Touchpad Defaults
tap_to_click = 1
tap_and_drag = 1
trackpad_natural_scrolling = 1
disable_while_typing = 1
scroll_method = 1
click_method = 2

# Load drop-in configurations
source = /usr/share/mango/config.d/10-noctalia-binds.conf
EOF_MANGO

# 3. Noctalia IPC Keybinds
cat <<'EOF_BINDS' > /usr/share/mango/config.d/10-noctalia-binds.conf
# Core UI
bind = SUPER, space, spawn, noctalia msg panel-toggle launcher
bind = SUPER, s, spawn, noctalia msg panel-toggle control-center
bind = SUPER, comma, spawn, noctalia msg settings-toggle
bind = ALT, Tab, spawn, noctalia msg window-switcher
bind = SUPER, Return, spawn, foot

# Hardware/Media
bind = NONE, XF86AudioRaiseVolume, spawn, noctalia msg volume-up
bind = NONE, XF86AudioLowerVolume, spawn, noctalia msg volume-down
bind = NONE, XF86AudioMute, spawn, noctalia msg volume-mute
bind = NONE, XF86MonBrightnessUp, spawn, noctalia msg brightness-up
bind = NONE, XF86MonBrightnessDown, spawn, noctalia msg brightness-down
bind = NONE, XF86AudioPlay, spawn, noctalia msg media toggle
bind = NONE, XF86AudioNext, spawn, noctalia msg media next
bind = NONE, XF86AudioPrev, spawn, noctalia msg media previous

# Session & Power
bind = SUPER SHIFT, l, spawn, noctalia msg session lock
bind = SUPER SHIFT, e, spawn, noctalia msg panel-toggle session
bind = SUPER SHIFT, c, spawn, noctalia msg caffeine-toggle
bind = SUPER SHIFT, n, spawn, noctalia msg nightlight-toggle
bind = SUPER SHIFT, w, spawn, noctalia msg wifi-toggle
bind = SUPER SHIFT, b, spawn, noctalia msg bluetooth-toggle

# Screenshots & Clipboard
bind = NONE, Print, spawn, noctalia msg screenshot-fullscreen
bind = SUPER SHIFT, s, spawn, noctalia msg screenshot-region
bind = SUPER, v, spawn, noctalia msg panel-toggle clipboard

# Window Management
bind = SUPER, q, killclient
bind = SUPER SHIFT, f, togglefloating
bind = SUPER, f, togglefullscreen
bind = SUPER SHIFT, r, reload_config

# Tags
bind = CTRL, 1, view, 1
bind = CTRL, 2, view, 2
bind = CTRL, 3, view, 3
bind = CTRL, 4, view, 4
bind = CTRL, 5, view, 5
bind = CTRL, 6, view, 6
bind = CTRL, 7, view, 7
bind = CTRL, 8, view, 8
bind = CTRL, 9, view, 9

bind = CTRL SHIFT, 1, tag, 1
bind = CTRL SHIFT, 2, tag, 2
bind = CTRL SHIFT, 3, tag, 3
bind = CTRL SHIFT, 4, tag, 4
bind = CTRL SHIFT, 5, tag, 5
bind = CTRL SHIFT, 6, tag, 6
bind = CTRL SHIFT, 7, tag, 7
bind = CTRL SHIFT, 8, tag, 8
bind = CTRL SHIFT, 9, tag, 9

# Focus movement
bind = ALT, Left, focusdir, left
bind = ALT, Right, focusdir, right
bind = ALT, Up, focusdir, up
bind = ALT, Down, focusdir, down
EOF_BINDS

# 4. Noctalia Config
mkdir -p /etc/noctalia
cat <<'EOF_NOCTALIA' > /etc/noctalia/config.toml
[bar.main]
shadow = false
contact_shadow = false

[dock]
shadow = false

[shell.panel]
shadow = false
EOF_NOCTALIA

echo ""
echo "✅ Conversion Complete!"
echo "---------------------------------------------------------"
echo "1. Log out or reboot."
echo "2. At GDM login, select 'MangoWM' from the gear icon."
echo "---------------------------------------------------------"
