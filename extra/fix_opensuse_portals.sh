#!/usr/bin/env bash
# Fix XDG Desktop Portal paths for openSUSE
# On openSUSE, portal binaries are in /usr/libexec instead of /usr/lib
#
# This script:
# 1. Creates symlinks for portal binaries in /usr/lib if they're in /usr/libexec
# 2. Sets environment variables for portal discovery
# 3. Ensures Hyprland can find the portals

set -euo pipefail

# Detect if we're on openSUSE
if ! grep -qi "opensuse" /etc/os-release 2>/dev/null; then
    echo "This script is for openSUSE only"
    exit 0
fi

echo "Fixing XDG Desktop Portal paths for openSUSE..."

LIBEXEC_PATH="/usr/libexec"
LIB_PATH="/usr/lib"

# List of portal binaries that might be in libexec on openSUSE
PORTAL_BINARIES=(
    "xdg-desktop-portal"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-kde"
    "xdg-desktop-portal-gtk"
)

# Function to create symlink if source exists and link doesn't
create_portal_symlink() {
    local binary=$1
    
    if [ -f "${LIBEXEC_PATH}/${binary}" ] && [ ! -f "${LIB_PATH}/${binary}" ]; then
        echo "  Creating symlink for ${binary}..."
        sudo ln -sf "${LIBEXEC_PATH}/${binary}" "${LIB_PATH}/${binary}"
    fi
}

# Create symlinks for all portal binaries
for binary in "${PORTAL_BINARIES[@]}"; do
    create_portal_symlink "$binary"
done

# Update environment for portal discovery
echo "Updating environment variables for portal discovery..."

# Create /etc/environment.d/hyprland-portals.conf if it doesn't exist
if [ ! -f /etc/environment.d/hyprland-portals.conf ]; then
    sudo tee /etc/environment.d/hyprland-portals.conf > /dev/null << EOF
# HyDE openSUSE: XDG Portal Configuration
# Ensure portals in /usr/libexec are discoverable

# Add libexec to library search path
LD_LIBRARY_PATH=/usr/libexec:\$LD_LIBRARY_PATH

# Ensure systemd user services can find portals
XDG_DESKTOP_PORTAL_DIR=/usr/libexec

# For Hyprland
HYPRLAND_PORTAL_PATH=/usr/libexec
EOF
    echo "Created /etc/environment.d/hyprland-portals.conf"
else
    echo "Portal environment configuration already exists"
fi

# Check if there are any remaining missing portals
echo ""
echo "Checking for portal binaries..."
for binary in "${PORTAL_BINARIES[@]}"; do
    if [ -f "${LIBEXEC_PATH}/${binary}" ] || [ -f "${LIB_PATH}/${binary}" ]; then
        echo "  ✓ ${binary} found"
    else
        echo "  ✗ ${binary} NOT FOUND (may need to be installed)"
    fi
done

echo ""
echo "Portal paths fixed. You may need to restart for changes to take effect."
