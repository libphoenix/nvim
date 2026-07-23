-- start screen
return {
  -- disable alpha
  { "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },

  {
    "nvim-mini/mini.starter",
    opts = function(_, opts)
      local pad_footer = string.rep(" ", 4)
      opts.header = table.concat({
        "",
        "   ██████╗ ██████╗ ",
        "   ██╔══██╗██╔══██╗",
        "   ██║  ██║██████╔╝",
        "   ██║  ██║██╔═══╝ ",
        "   ██████╔╝██║     ",
        "",
        "",
      }, "\n")

      opts.items = {}

      opts.footer = pad_footer .. " Welcome Deepak "
      return opts
    end,
  },
}
