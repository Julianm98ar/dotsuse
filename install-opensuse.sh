#!/usr/bin/env bash
set -e

clear
echo "========================================="
echo "   HyDE Installer for openSUSE"
echo "========================================="
echo

# -----------------------------
# Detect distro
# -----------------------------
if ! grep -qi "opensuse" /etc/os-release; then
  echo "❌ Este script es solo para openSUSE"
  exit 1
fi

# -----------------------------
# Ask HyDE path
# -----------------------------
read -rp "📁 Ruta donde está HyDE (ej: /home/julian/HyDE): " HYDE_DIR

if [ ! -d "$HYDE_DIR" ]; then
  echo "❌ La carpeta no existe"
  exit 1
fi

# -----------------------------
# Install packages
# -----------------------------
echo
echo "📦 Instalando dependencias..."

sudo zypper refresh

sudo zypper install -y \
  hyprland \
  waybar \
  wofi \
  kitty \
  foot \
  grim \
  slurp \
  swappy \
  wl-clipboard \
  brightnessctl \
  playerctl \
  pamixer \
  pipewire \
  wireplumber \
  xdg-desktop-portal \
  xdg-desktop-portal-hyprland \
  polkit-kde-agent-6 \
  thunar \
  thunar-volman \
  gvfs \
  kvantum-manager \
  qt5ct \
  qt6ct \
  pavucontrol \
  curl \
  wget \
  unzip \
  sddm \
  fastfetch

echo "✅ Paquetes instalados"

# -----------------------------
# Copy configs
# -----------------------------
echo
echo "📂 Copiando configuraciones..."

mkdir -p ~/.config

copy_if_exists () {
  if [ -d "$HYDE_DIR/$1" ]; then
    echo " → $1"
    cp -r "$HYDE_DIR/$1" ~/.config/
  fi
}

copy_if_exists hypr
copy_if_exists waybar
copy_if_exists wofi
copy_if_exists kitty
copy_if_exists foot
copy_if_exists dunst
copy_if_exists rofi

# -----------------------------
# Fix polkit
# -----------------------------
echo
echo "🔐 Configurando polkit..."

mkdir -p ~/.config/hypr

sed -i '/polkit/d' ~/.config/hypr/hyprland.conf 2>/dev/null || true

echo 'exec-once = /usr/lib/polkit-kde-authentication-agent-1 &' >> ~/.config/hypr/hyprland.conf

# -----------------------------
# XDG Portal
# -----------------------------
echo
echo "🧩 Configurando xdg-desktop-portal..."

mkdir -p ~/.config/xdg-desktop-portal

cat <<EOF > ~/.config/xdg-desktop-portal/portals.conf
[preferred]
default=hyprland
EOF

systemctl --user enable --now xdg-desktop-portal
systemctl --user enable --now xdg-desktop-portal-hyprland

# -----------------------------
# Hyprland session
# -----------------------------
echo
echo "🪟 Creando sesión Wayland..."

sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Exec=Hyprland
Type=Application
EOF

# -------------------------------------------------
# Display manager (openSUSE way)
# -------------------------------------------------
echo
echo "🖥 Configurando display manager..."


sudo systemctl set-default graphical.target
sudo systemctl enable display-manager


echo
echo "========================================="
echo "✅ Instalación completada"
echo "➡ Reinicia el sistema"
echo "➡ Selecciona Hyprland en SDDM"
echo "========================================="

# -----------------------------
# Finish
# -----------------------------
echo
echo "========================================="
echo "✅ HyDE instalado correctamente"
echo "➡ reinicia el sistema"
echo "➡ selecciona Hyprland en el login"
echo "========================================="