return {
  {
    'heilgar/bookmarks.nvim',
    lazy = false,
    dependencies = {
      'kkharji/sqlite.lua',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    -- モンキーパッチはプラグインロード前に適用する必要があるため init で行う
    init = function()
      require('rc.patches.bookmarks')
    end,
    config = function()
      local util = require('rc.util')
      require('bookmarks').setup({})
      local autocmds = require('bookmarks.autocmds')
      local map      = vim.keymap.set
      local function refresh()
        autocmds.refresh_buffer(vim.api.nvim_get_current_buf())
      end
      map('n', 'mm', function()
        local bufnr = vim.api.nvim_get_current_buf()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local list = autocmds.get_buffer_bookmarks(bufnr)
        local is_bookmarked = false
        if list then
          for _, bm in ipairs(list.items) do
            if bm.line == line then
              is_bookmarked = true
              break
            end
          end
        end
        if is_bookmarked then
          require('bookmarks.commands').remove_bookmark()
        else
          require('bookmarks.commands').add_bookmark()
        end
        refresh()
      end, { desc = 'Bookmark toggle' })
      map('n', 'mc', function()
        require('bookmarks.commands').remove_bookmark()
        refresh()
      end, { desc = 'Bookmark remove' })
      map('n', 'mn', function()
        local bufnr = vim.api.nvim_get_current_buf()
        require('bookmarks.navigation').jump_to_next(autocmds.get_buffer_bookmarks(bufnr))
      end, { desc = 'Bookmark next' })
      map('n', 'mp', function()
        local bufnr = vim.api.nvim_get_current_buf()
        require('bookmarks.navigation').jump_to_prev(autocmds.get_buffer_bookmarks(bufnr))
      end, { desc = 'Bookmark prev' })
      map('n', 'ml', function()
        local bm_config = require('bookmarks').get_config()
        local title = '📖 Bookmarks'
        if bm_config.use_branch_specific then
          local branch = require('bookmarks.utils').get_current_branch()
          title = title .. (branch and string.format(' (branch: %s)', branch) or ' (branch: unknown)')
        end
        local active_list = bm_config.active_list or 'default'
        if active_list == 'all' then
          title = title .. ' [🔍 all lists]'
        elseif active_list == 'default' then
          title = title .. ' [📋 default]'
        else
          title = title .. string.format(' [📁 %s]', active_list)
        end
        title = title .. '  <C-l>=レイアウト切替 <C-d>=削除'

        require('telescope').extensions.bookmarks.list({
          prompt_title    = title,
          layout_strategy = util.telescope_layout_presets[1].layout_strategy,
          layout_config   = util.telescope_layout_presets[1].layout_config,
          attach_mappings = function(prompt_bufnr, pmap)
            local function delete_bookmark()
              local as = require('telescope.actions.state')
              local current_picker = as.get_current_picker(prompt_bufnr)
              local selection = as.get_selected_entry()
              if not (selection and selection.value) then return end
              local bmk = selection.value
              local cfg = require('bookmarks').get_config()
              local branch = cfg.use_branch_specific and require('bookmarks.utils').get_current_branch() or nil
              require('bookmarks.storage').remove_bookmark(bmk.filename, bmk.line, bmk.project_root, branch, bmk.list)
              local bufnr = vim.fn.bufnr(bmk.filename)
              if bufnr ~= -1 then require('bookmarks.autocmds').refresh_buffer(bufnr) end
              current_picker:delete_selection(function()
                vim.notify('Bookmark deleted', vim.log.levels.INFO)
              end)
            end
            pmap('i', '<C-d>', delete_bookmark)
            pmap('n', '<C-d>', delete_bookmark)

            local toggle_layout = util.make_layout_toggle(prompt_bufnr)
            pmap('i', '<C-l>', toggle_layout)
            pmap('n', '<C-l>', toggle_layout)
            return true
          end,
        })
      end, { desc = 'Bookmark list' })
      -- Nerd Font 非対応環境での ? 表示を回避するため ASCII 文字に上書き
      vim.fn.sign_define('BookmarkSign', {
        text   = '>>',
        texthl = 'BookmarkSignHighlight',
        numhl  = 'BookmarkSignHighlight',
        linehl = 'BookmarkHighlight',
      })
      -- _vimrc の colorscheme 適用で BookmarkHighlight が消えるため再定義
      -- VimEnter: _vimrc source 完了後に確実に定義、ColorScheme: 以降の変更にも対応
      local function restore_bookmark_hl()
        vim.api.nvim_set_hl(0, 'BookmarkHighlight',     { bg = '#594d3e', bold = true })
        vim.api.nvim_set_hl(0, 'BookmarkSignHighlight', { fg = '#FFE5B4', bold = true })
        require('bookmarks.autocmds').refresh_all_buffers()
      end
      vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
        callback = restore_bookmark_hl,
      })
    end,
  },
}
