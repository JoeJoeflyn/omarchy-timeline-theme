-- Timeline — Hyprland decoration: warm desert, shifts with time of day
-- Active border color is driven by colors.toml accent, refreshed by timeline-daemon

hl.config({
  general = {
    col = {
      active_border = "rgb(C4983A)",
      inactive_border = "rgb(1a120e)",
    },
    gaps_in = 7,
    gaps_out = 11,
    border_size = 2,
  },
  group = {
    col = {
      border_active = "rgb(C4983A)",
      border_inactive = "rgb(1a120e)",
    },
    groupbar = {
      col = {
        active = "rgba(C4983A99)",
        inactive = "rgba(1A120E88)",
      },
      text_color = "rgb(F0E8D8)",
      text_color_inactive = "rgba(A89080ee)",
    },
  },
  decoration = {
    rounding = 6,
    rounding_power = 3,
    shadow = {
      enabled = true,
      range = 16,
      color = "rgba(00000088)",
    },
  },
})
