-- Theme picker popup
hl.window_rule({ match = { class = "theme-picker" }, float    = true })
hl.window_rule({ match = { class = "theme-picker" }, center   = true })
hl.window_rule({ match = { class = "theme-picker" }, size     = { 980, 680 } })
hl.window_rule({ match = { class = "theme-picker" }, pin      = true })
hl.window_rule({ match = { class = "theme-picker" }, rounding = 16 })

-- quickshell `base` Settings window (a FloatingWindow titled "base-settings")
hl.window_rule({ match = { title = "^base-settings$" }, float  = true })
hl.window_rule({ match = { title = "^base-settings$" }, center = true })
hl.window_rule({ match = { title = "^base-settings$" }, size   = { 1100, 760 } })
