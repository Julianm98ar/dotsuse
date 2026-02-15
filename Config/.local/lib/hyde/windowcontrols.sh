#!/usr/bin/env bash
# Window Controls Script for Waybar
# Provides minimize, maximize, and close buttons for active window

[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

# Get active window info
get_window_info() {
    hyprctl activewindow -j 2>/dev/null || echo "{}"
}

# Check if there's an active window
has_active_window() {
    local address
    address=$(get_window_info | jq -r '.address // empty')
    [[ -n "$address" ]]
}

# Minimize window (move to special workspace)
minimize_window() {
    if has_active_window; then
        hyprctl dispatch movetoworkspacesilent special:minimized
        send_notifs -i window-minimize -t 2000 "HyDE" "Ventana minimizada"
    fi
}

# Maximize/Toggle fullscreen
maximize_window() {
    if has_active_window; then
        hyprctl dispatch fullscreen 1
    fi
}

# Close window
close_window() {
    if has_active_window; then
        hyprctl dispatch killactive
    fi
}

# Display window controls for Waybar
display_controls() {
    if has_active_window; then
        local window_info
        window_info=$(get_window_info)
        local title
        title=$(echo "$window_info" | jq -r '.title // "Ventana"' | head -c 30)
        
        # Icons with proper classes for styling
        echo "{\"text\":\"  \", \"tooltip\":\"Minimizar: Clic izquierdo | Maximizar: Clic medio | Cerrar: Clic derecho\", \"class\":\"active\"}"
    else
        echo "{\"text\":\"\", \"tooltip\":\"No hay ventana activa\", \"class\":\"inactive\"}"
    fi
}

# Handle action parameter
case "${1}" in
    --minimize|-m)
        minimize_window
        ;;
    --maximize|-M)
        maximize_window
        ;;
    --close|-c)
        close_window
        ;;
    --display|-d|*)
        display_controls
        ;;
esac
