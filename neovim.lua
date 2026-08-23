return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      transparent = false,
      colors = {
        bg         = "#100A12",
        dark_bg    = "#0A0608",
        darker_bg  = "#060306",
        lighter_bg = "#160E18",

        fg         = "#D0C8D0",
        dark_fg    = "#786078",
        light_fg   = "#Dcd4Dc",
        bright_fg  = "#FFFFFF",
        muted      = "#4A3A4A",

        red        = "#8A3A4A",
        orange     = "#6A4A3A",
        yellow     = "#8A6A3A",
        green      = "#4A5A4A",
        cyan       = "#5A4A5A",
        blue       = "#4A3A5A",
        purple     = "#6A3A5A",
        brown      = "#2A1422",

        bright_red    = "#A85A5A",
        bright_yellow = "#A88858",
        bright_green  = "#6A7A6A",
        bright_cyan   = "#7A6A7A",
        bright_blue   = "#6A5A7A",
        bright_purple = "#8A5A7A",

        accent               = "#6A3A5A",
        cursor               = "#6A3A5A",
        foreground           = "#D0C8D0",
        background           = "#100A12",
        selection            = "#160E18",
        selection_foreground = "#D0C8D0",
        selection_background = "#100A12",
      },
      on_highlights = function(hl, c)
        hl.CursorLine = { bg = "#160E18" }
        hl.CursorLineNr = { fg = c.purple, bold = true }
        hl.LspReferenceText = { bg = c.selection, fg = c.bright_fg }
        hl.LspReferenceRead = hl.LspReferenceText
        hl.LspReferenceWrite = hl.LspReferenceText
        hl.SnacksPickerDir         = { fg = c.muted }
        hl.SnacksPickerPathHidden  = { fg = c.muted }
        hl.SnacksPickerPathIgnored = { fg = c.muted }
        hl.SnacksPickerListCursorLine = { bg = "#160E18" }
        hl["@markup.raw.markdown_inline"] = { bg = "NONE" }
        hl["@markup.raw.block.markdown"] = { bg = "NONE" }
        hl["@markup.quote"] = { bg = "NONE" }
      end,
    },
    config = function(_, opts)
      require("aether").setup(opts)
      vim.cmd("colorscheme aether")
    end,
  },
}
