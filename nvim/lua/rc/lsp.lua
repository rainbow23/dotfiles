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
    map('gr', function()
      local util         = require('rc.util')
      local action_state = require('telescope.actions.state')
      require('telescope.builtin').lsp_references({
        prompt_title    = 'LSP References  <C-x>=Quickfix ' .. util.shortcut_common,
        attach_mappings = util.make_attach_mappings(true, function(_, lmap)
          util.map_modes(lmap, '<C-x>', function(b)
            local picker = action_state.get_current_picker(b)
            local qflist = {}
            for entry in picker.manager:iter() do
              if entry.filename then
                table.insert(qflist, {
                  filename = entry.filename,
                  lnum     = entry.lnum or 1,
                  col      = entry.col  or 1,
                  text     = entry.text or '',
                })
              end
            end
            vim.fn.setqflist(qflist, 'r')
            vim.schedule(function() vim.cmd('copen') end)
          end)
        end),
      })
    end)
    map('K',          vim.lsp.buf.hover)
    map('<leader>rn', vim.lsp.buf.rename)
    map('<leader>ca', vim.lsp.buf.code_action)
    map('[d',         vim.diagnostic.goto_prev)
    map(']d',         vim.diagnostic.goto_next)

    -- インレイヒント（対応サーバーのみ有効化）
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
  end,
})

-- サーバー定義は lsp_servers.lua に集約（headless の callgraph ツールと共用）
local capabilities = require('cmp_nvim_lsp').default_capabilities()
require('lsp_servers').enable(capabilities)

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
