-- Shell keybinds for quickshell `base` (end4-pC binds on the same keys are unbound first).
-- App launchers are left to you — add your own below.

-- Lone Super tap → app launcher (fuzzel if base isn't running). Release bind, so Super+<key> combos don't fire it.
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")
local launcherCmd = "qs -c base ipc call launcher toggle || pkill fuzzel || fuzzel"
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(launcherCmd), { release = true, description = "App launcher" })
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd(launcherCmd), { release = true })

-- SUPER+Tab → window/workspace overview
hl.unbind("SUPER + Tab")
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("qs -c base ipc call windows toggle"), { description = "Shell: Window overview" })

-- Wallpapers: carousel, next / previous
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("qs -c base ipc call carousel toggle"), { description = "Shell: Wallpaper carousel" })
hl.bind("SUPER + ALT + Right", hl.dsp.exec_cmd("qs -c base ipc call wallpaper next"), { description = "Shell: Next wallpaper" })
hl.bind("SUPER + ALT + Left", hl.dsp.exec_cmd("qs -c base ipc call wallpaper prev"), { description = "Shell: Previous wallpaper" })

-- Bar toggle
hl.unbind("SUPER + J")
hl.bind("SUPER + J", hl.dsp.exec_cmd("qs -c base ipc call bar toggle"), { description = "Toggle shell bar" })
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("qs -c base ipc call bar toggle"), { description = "Toggle shell bar" })

-- Terminal
hl.unbind("SUPER + Return")
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"), { description = "Terminal" })

-- Edit this file
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })
