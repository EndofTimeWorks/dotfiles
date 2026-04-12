local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("MapleMono NF", { weight = "Regular" })
config.font_size = 13.0
config.line_height = 1.15

-- Enable ligatures (Maple Mono supports them natively)
config.harfbuzz_features = { "calt=1", "liga=1", "clig=1" }

-- Dark navy palette
local bg        = "#0b0d1a"
local surface   = "#0f1120"
local surface2  = "#141628"
local overlay   = "#1a1d35"
local purple    = "#c792ea"
local cyan      = "#4ec9b0"
local green     = "#99c794"
local pink      = "#ec5f89"
local yellow    = "#fac863"
local red       = "#f97b58"
local text      = "#cdd6f4"
local subtext   = "#7f849c"

config.colors = {
  foreground    = text,
  background    = bg,
  cursor_bg     = purple,
  cursor_fg     = bg,
  cursor_border = purple,
  selection_fg  = bg,
  selection_bg  = purple,
  scrollbar_thumb = overlay,
  split         = overlay,

  ansi = {
    "#1a1b2e", -- black   (surface)
    red,       -- red
    green,     -- green
    yellow,    -- yellow
    "#82aaff", -- blue
    purple,    -- magenta
    cyan,      -- cyan
    text,      -- white
  },
  brights = {
    subtext,   -- bright black
    "#ff6e6e", -- bright red
    "#c3e88d", -- bright green
    "#ffcb6b", -- bright yellow
    "#9cc4ff", -- bright blue
    "#d9a0ff", -- bright magenta
    "#89ddff", -- bright cyan
    "#ffffff",  -- bright white
  },

  tab_bar = {
    background = surface,
    active_tab = {
      bg_color  = overlay,
      fg_color  = purple,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = surface,
      fg_color = subtext,
    },
    inactive_tab_hover = {
      bg_color = surface2,
      fg_color = text,
    },
    new_tab = {
      bg_color = surface,
      fg_color = subtext,
    },
    new_tab_hover = {
      bg_color = surface2,
      fg_color = text,
    },
  },
}

-- Window appearance
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0

config.window_padding = {
  left = 14, right = 14, top = 10, bottom = 10,
}

config.window_decorations = "NONE"
config.window_close_confirmation = "NeverPrompt"

-- Tab bar (minimal, top)
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.show_tab_index_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

config.tab_max_width = 32

-- Scrollback
config.scrollback_lines = 5000

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- Performance
config.max_fps = 120
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Misc
config.audible_bell = "Disabled"
config.check_for_updates = false

-- Key bindings (keep minimal, add a few useful ones)
config.keys = {
  -- Split panes
  { key = "e", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "o", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
  -- Navigate panes
  { key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
  -- New tab
  { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  -- Copy/paste
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
}

return config
