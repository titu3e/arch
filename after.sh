#!/bin/bash

# Ensure this is run as a regular user (not root)
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run this script as your regular user (not root)."
    exit 1
fi

echo "=== Beautifying Qtile Desktop ==="

# Create config directories
mkdir -p ~/.config/qtile ~/.config/alacritty ~/.local/share/fonts ~/Pictures/wallpapers

# Download wallpaper
curl -Lo ~/Pictures/wallpapers/default.jpg https://w.wallhaven.cc/full/1p/wallhaven-1p3jx9.jpg

# Install FiraCode Nerd Font
echo "➡️ Installing FiraCode Nerd Font..."
curl -Lo /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts/
fc-cache -fv

# Alacritty configuration
cat > ~/.config/alacritty/alacritty.yml <<EOF
window:
  opacity: 0.95
  padding:
    x: 10
    y: 10
font:
  normal:
    family: "FiraCode Nerd Font"
  size: 10.5
colors:
  primary:
    background: '0x1e1e2e'
    foreground: '0xcdd6f4'
  cursor:
    text: '0x1e1e2e'
    cursor: '0xf5e0dc'
EOF

# Install Qtile extras
echo "➡️ Installing dependencies..."
sudo pacman -S --noconfirm picom feh rofi unzip

# Basic Qtile config
cat > ~/.config/qtile/config.py <<EOF
from libqtile import bar, layout, widget, hook
from libqtile.config import Key, Group, Screen, Match
from libqtile.lazy import lazy
import os

mod = "mod4"
terminal = "alacritty"

keys = [
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="App launcher"),
    Key([mod], "q", lazy.window.kill(), desc="Close window"),
    Key([mod], "Tab", lazy.layout.next(), desc="Switch window focus"),
    Key([mod, "control"], "r", lazy.restart(), desc="Restart Qtile"),
]

groups = [Group(i) for i in "123456"]
for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen()),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name)),
    ])

layouts = [
    layout.Columns(border_focus="#ff79c6", border_width=2),
    layout.Max(),
]

widget_defaults = dict(font="FiraCode Nerd Font", fontsize=13, padding=5)

screens = [
    Screen(
        top=bar.Bar([
            widget.CurrentLayout(),
            widget.GroupBox(highlight_method='block', this_current_screen_border='#bd93f9'),
            widget.Prompt(),
            widget.WindowName(),
            widget.Systray(),
            widget.Clock(format="%Y-%m-%d %H:%M"),
        ], 28, background="#1e1e2e")
    )
]

@hook.subscribe.startup_once
def start_once():
    os.system("feh --bg-scale ~/Pictures/wallpapers/default.jpg")
    os.system("picom -b --experimental-backends")
EOF

# Set .xinitrc to autostart Qtile
echo "exec qtile start" > ~/.xinitrc

echo "✅ Qtile setup is now beautiful and modern!"
echo "➡️ Run 'startx' to launch your desktop."
