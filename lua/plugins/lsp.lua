return {
  -- Add emoji completion.
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
      },
    },
  },

  -- Extend LazyVim's LSP configuration instead of copying its setup code.
  -- Mason/LazyVim remains the single owner that starts clangd.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {},
        stylua = { enabled = false },
        harper_ls = {
          filetypes = { "markdown" },
          settings = {
            ["harper-ls"] = {
              userDictPath = "",
              workspaceDictPath = "",
              fileDictPath = "",
              linters = {
                SpellCheck = true,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = true,
                UnclosedQuotes = true,
                WrongApostrophe = false,
                LongSentences = true,
                RepeatedWords = true,
                Spaces = true,
                CorrectNumberSuffix = true,
              },
              codeActions = {
                ForceStable = false,
              },
              markdown = {
                IgnoreLinkTitle = false,
              },
              diagnosticSeverity = "hint",
              isolateEnglish = false,
              dialect = "American",
              maxFileLength = 120000,
              ignoredLintsPath = "",
              excludePatterns = {},
            },
          },
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c",
        "cpp",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      })
    end,
  },
}
