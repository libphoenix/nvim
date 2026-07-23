return {
  {
    "shahshlok/vim-coach.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("vim-coach").setup()
    end,
    keys = {
      { "<leader>?", "<cmd>VimCoach<cr>", desc = "Vim Coach" },
    },
  },

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
