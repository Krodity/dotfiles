# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end
    # quickshell base theme (bg/fg/cursor/selection) overrides end4's; written by base/config/Theme.qml
    if test -f ~/.local/state/quickshell-base/sequences.txt
        cat ~/.local/state/quickshell-base/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end

    # Show system info on new interactive terminals (after matugen palette applied above)
    pfetch

    alias hypr='HYPRLAND_INSTANCE_SIGNATURE=(ls /run/user/1000/hypr/) XDG_RUNTIME_DIR=/run/user/1000 hyprctl'
end
