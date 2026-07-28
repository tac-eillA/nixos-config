-- Hyprland 0.56 native Lua configuration.
-- Managed by Home Manager through modules/home/allison/hyprland.nix.

local mainMod = "SUPER"
local terminal = "ghostty"
local browser = "firefox"
local fileManager = "thunar"

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    ["col.active_border"] = {
      colors = { "rgba(8aadf4ee)", "rgba(c6a0f6ee)" },
      angle = 45,
    },
    ["col.inactive_border"] = "rgba(494d64aa)",
    layout = "dwindle",
    resize_on_border = true,
  },
  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.96,
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "rgba(00000066)",
    },
    blur = {
      enabled = true,
      size = 7,
      passes = 3,
      vibrancy = 0.2,
    },
  },
  animations = {
    enabled = true,
  },
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0.0,
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
    },
  },
  dwindle = {
    preserve_split = true,
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },
})

-- Home Manager seeds this mutable file once. The wdisplays wrapper rewrites it
-- after display changes so monitor layouts survive logins and Nix rebuilds.
local configHome = os.getenv("XDG_CONFIG_HOME")
if not configHome or configHome == "" then
  configHome = os.getenv("HOME") .. "/.config"
end
dofile(configHome .. "/hypr/monitors.lua")

hl.curve("easeOut", {
  type = "bezier",
  points = { { 0.16, 1.0 }, { 0.3, 1.0 } },
})

hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 4.0,
  bezier = "easeOut",
  style = "popin 80%",
})
hl.animation({
  leaf = "windowsOut",
  enabled = true,
  speed = 4.0,
  bezier = "easeOut",
  style = "popin 80%",
})
hl.animation({ leaf = "fade", enabled = true, speed = 4.0, bezier = "easeOut" })
hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 4.0,
  bezier = "easeOut",
  style = "slide",
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wdisplays"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c allison ipc call shell toggleNotifications"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("qs -c allison ipc call shell togglePower"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

hl.bind("Print", hl.dsp.exec_cmd("grimblast copy area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast save area"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("loginctl lock-session"))

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs -c allison ipc call shell toggleMute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs -c allison ipc call shell media playPause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs -c allison ipc call shell media next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs -c allison ipc call shell media previous"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c allison ipc call shell volumeStep 5"), {
  locked = true,
  repeating = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs -c allison ipc call shell volumeStep -5"), {
  locked = true,
  repeating = true,
})
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c allison ipc call shell brightnessStep 5"), {
  locked = true,
  repeating = true,
})
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c allison ipc call shell brightnessStep -5"), {
  locked = true,
  repeating = true,
})

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for workspace = 1, 5 do
  local number = tostring(workspace)
  hl.bind(mainMod .. " + " .. number, hl.dsp.focus({ workspace = number }))
  hl.bind(mainMod .. " + SHIFT + " .. number, hl.dsp.window.move({
    workspace = number,
    follow = false,
  }))
end
