-- LSP / 補完設定（プラグイン定義は plugins/lsp.lua）
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    'kotlin_language_server',
    'ts_ls',
    'sqlls',
    'lua_ls',
    'vimls',
    'bashls',
  },
})

-- LuaSnip（vim-snippets の snipmate 形式スニペットを読み込む）
local luasnip = require('luasnip')
require('luasnip.loaders.from_snipmate').lazy_load()

-- nvim-cmp
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.abort(),
    ['<CR>']      = cmp.mapping.confirm({ select = true }),
    ['<Tab>']     = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>']   = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources(
    { { name = 'nvim_lsp' }, { name = 'luasnip' } },
    { { name = 'buffer' },   { name = 'path' } }
  ),
})

-- LSP 共通設定
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local map = function(keys, func)
      vim.keymap.set('n', keys, func, { buffer = bufnr, silent = true })
    end
    map('gd',         vim.lsp.buf.definition)
    map('gr',         vim.lsp.buf.references)
    map('K',          vim.lsp.buf.hover)
    map('<leader>rn', vim.lsp.buf.rename)
    map('<leader>ca', vim.lsp.buf.code_action)
    map('[d',         vim.diagnostic.goto_prev)
    map(']d',         vim.diagnostic.goto_next)
  end,
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

-- lua_ls（Neovim API を認識させる追加設定）
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime    = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace  = { library = vim.api.nvim_get_runtime_file('', true), checkThirdParty = false },
      telemetry  = { enable = false },
    },
  },
})

vim.lsp.enable({ 'kotlin_language_server', 'ts_ls', 'sqlls', 'vimls', 'bashls', 'lua_ls' })

-- Java（nvim-jdtls）
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    require('jdtls').start_or_attach({
      cmd = {
        vim.fn.stdpath('data') .. '/mason/bin/jdtls',
        '-data', vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name,
      },
      root_dir = vim.fs.dirname(vim.fs.find(
        { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' },
        { upward = true }
      )[1]),
      capabilities = capabilities,
    })
  end,
})
