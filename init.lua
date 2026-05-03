--------------------------------------------------------------------------------
-- 1. General options
--------------------------------------------------------------------------------

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = false
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.undofile = true
opt.updatetime = 250
opt.scrolloff = 8
opt.guicursor = {
  "n-v-c:block-Cursor/lCursor-blinkwait100-blinkon200-blinkoff150",
  "i-ci-ve:ver25-Cursor/lCursor-blinkwait300-blinkon200-blinkoff150",
  "r-cr:hor20-Cursor/lCursor-blinkwait300-blinkon200-blinkoff150",
  "o:hor50-Cursor/lCursor",
}

-- Vim API
-- This should change the blinking cursor colors, but seems its not working for now.
--[[
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "Cursor", { fg = "#1e1e2e", bg = "#cdd6f4" })
    vim.api.nvim_set_hl(0, "lCursor", { fg = "#1e1e2e", bg = "#cdd6f4" })
  end,
})
--]]

--------------------------------------------------------------------------------
-- 2. BOOTSTRAP LAZY.NVIM (plugin management)
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- 3. PLUGINS
--------------------------------------------------------------------------------
require("lazy").setup({

  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Treesitter: syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "haskell",
          "lua",
          "markdown",
          "glsl",
          "hlsl",
          "wgsl",
          "gdscript",
          "godot_resource",
          "gdshader",
          "javascript",
          "typescript",
          "tsx",
          "jsx",
          "html",
          "css",
          "json",
          "clojure",
        },
      })
    end,
  },
  -- LSP
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "hls",
          "lua_ls",
          "glsl_analyzer",
          "ts_ls",
          "eslint",
          "html",
          "cssls",
          "emmet_ls",
          "jsonls",
          "clojure_lsp",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- Clojure
      vim.lsp.config("clojure_lsp", {
        capabilities = capabilities,
      })


      -- Godot
      vim.lsp.config("gdscript", {
        cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
        filetypes = { "gdscript" },
        root_markers = { "project.godot" },
        capabilities = capabilities,
      })
      -- Haskell
      vim.lsp.config("hls", {
        capabilities = capabilities,
        settings = {
          haskell = {
            formattingProvider = "ormolu",
            checkProject = true,
          },
        },
      })
      -- Shaders
      vim.lsp.config("glsl_analyzer", {
        capabilities = capabilities,
      })
      -- Lua
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      vim.lsp.enable({ "hls", "lua_ls", "glsl_analyzer", "gdscript", "clojure_lsp" })

      -- Keymaps LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Ir a definición")
          map("gr", vim.lsp.buf.references, "Ver referencias")
          map("K", vim.lsp.buf.hover, "Documentación hover")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>rn", vim.lsp.buf.rename, "Renombrar símbolo")
          map("<leader>d", vim.diagnostic.open_float, "Ver diagnóstico")
          map("[d", vim.diagnostic.goto_prev, "Diagnóstico anterior")
          map("]d", vim.diagnostic.goto_next, "Diagnóstico siguiente")
        end,
      })
    end,
  },
  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Telescope: fuzzy search
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar archivos" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Grep en proyecto" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers abiertos" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Buscar en ayuda" },
    },
  },

  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = [[<c-\>]],
      direction = "float",
      float_opts = { border = "curved" },
    },
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "auto",
      },
    },
  },
  -- My own plugins:
  {
    "Olical/conjure",
    ft = { "clojure", "fennel", "scheme" },
    init = function()
      -- Avoic conflict with localleader
      vim.g["conjure#mapping#prefix"] = "<localleader>c"
    end,
  },
  {
    "julienvincent/nvim-paredit",
    ft = {
      "clojure",
      "scheme",
      "lisp",
      "fennel",
      "racket"
    },
    config = function()
      require("nvim-paredit").setup()
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          gdscript = { "gdformat" },
          lua = { "stylua" },
          haskell = { "ormolu" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
        },
        format_on_save = {
          timeout_ms = 2000,
          lsp_format = "fallback",
        },
      })
    end,
  },
  {
    { "tikhomirov/vim-glsl",       ft = "glsl" },
    { "echasnovski/mini.pairs",    event = "InsertEnter", opts = {} },
    { "echasnovski/mini.surround", event = "VeryLazy",    opts = {} },
  }
})

vim.filetype.add({
  extension = {
    vert = "glsl",
    frag = "glsl",
    geom = "glsl",
    tesc = "glsl",
    tese = "glsl",
    comp = "glsl",
    wgsl = "wgsl",
    gd = "gdscript",
    tscn = "gdresource",
    tres = "gdresource",
    gdshader = "gdshader",
  },
  pattern = {
    ["project%.godot"] = "confini",
  }
})
