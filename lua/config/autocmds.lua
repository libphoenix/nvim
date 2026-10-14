-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    if vim.fn.has("nvim-0.13") == 1 then
      vim.hl.hl_op()
    else
      (vim.hl or vim.highlight).on_yank()
    end
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dap-float",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

local c_syntax_namespace = vim.api.nvim_create_namespace("c_family_syntax")

local function update_c_syntax_diagnostics(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then
    vim.diagnostic.reset(c_syntax_namespace, bufnr)
    return
  end

  local trees = parser:parse()
  local tree = trees and trees[1]
  if not tree then
    return
  end

  local diagnostics = {}
  local function collect(node)
    local is_missing = node:missing()
    if is_missing or node:type() == "ERROR" then
      local start_row, start_col, end_row, end_col = node:range()
      if start_row == end_row and start_col == end_col then
        end_col = start_col + 1
      end
      diagnostics[#diagnostics + 1] = {
        lnum = start_row,
        col = start_col,
        end_lnum = end_row,
        end_col = end_col,
        severity = vim.diagnostic.severity.ERROR,
        message = is_missing and ("Missing " .. node:type()) or "Syntax error",
        source = "treesitter",
      }
      return
    end

    if node:has_error() then
      for child in node:iter_children() do
        collect(child)
      end
    end
  end

  collect(tree:root())
  vim.diagnostic.set(c_syntax_namespace, bufnr, diagnostics)
end

-- Report parser errors only. Clangd still provides completion and navigation.
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
  group = augroup("c_family_syntax_diagnostics"),
  pattern = { "*.c", "*.cc", "*.cpp", "*.cxx", "*.h", "*.hh", "*.hpp", "*.hxx", "*.m", "*.mm", "*.cu" },
  callback = function(event)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(event.buf) then
        update_c_syntax_diagnostics(event.buf)
      end
    end)
  end,
})

-- A C/C++ buffer only needs one clangd client. If another one attaches,
-- detach it before it can duplicate definitions, completions, and inlay hints.
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("single_clangd_client"),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client or client.name ~= "clangd" then
      return
    end

    -- Hide clangd's compiler and semantic diagnostics for this buffer.
    for _, is_pull in ipairs({ false, true }) do
      local namespace = vim.lsp.diagnostic.get_namespace(client.id, is_pull)
      vim.diagnostic.enable(false, { bufnr = event.buf, ns_id = namespace })
    end

    for _, other in ipairs(vim.lsp.get_clients({ bufnr = event.buf, name = "clangd" })) do
      if other.id ~= client.id then
        vim.schedule(function()
          vim.lsp.buf_detach_client(event.buf, client.id)
        end)
        return
      end
    end
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
