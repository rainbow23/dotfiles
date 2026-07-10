-- セッション管理（telescope ベース）
local conf         = require('telescope.config').values
local finders      = require('telescope.finders')
local pickers      = require('telescope.pickers')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')

local util      = require('rc.util')
local map_modes = util.map_modes

local session_dir = vim.fn.expand('~/.vim/sessions')
vim.fn.mkdir(session_dir, 'p')

local function session_save(name)
  name = name or 'default'
  local path = session_dir .. '/' .. name .. '.vim'
  vim.cmd('mksession! ' .. vim.fn.fnameescape(path))
  vim.notify('Session saved: ' .. name, vim.log.levels.INFO)
end

local function session_load(name)
  local path = session_dir .. '/' .. name .. '.vim'
  vim.cmd('source ' .. vim.fn.fnameescape(path))
  vim.notify('Session loaded: ' .. name, vim.log.levels.INFO)
end

local function telescope_session_picker()
  -- 現在の git root を取得してセッションをフィルタリング
  -- git rev-parse の出力形式のまま保持し、セッション側も同じコマンドで取得して比較する
  -- （GitBash では expand('~') が C:/... を返し git が /c/... を返すため fnamemodify での
  --   正規化では吸収できない。同一コマンド出力同士を比較することで形式差異を回避する）
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  local has_git  = git_root ~= '' and not git_root:find('fatal')

  local files = vim.fn.glob(session_dir .. '/*.vim', false, true)
  local names = {}
  for _, f in ipairs(files) do
    local include = true
    if has_git then
      -- セッションの cd 行からディレクトリを取得し、git -C でその git root を求めて照合
      include = false
      local fh = io.open(f, 'r')
      if fh then
        for line in fh:lines() do
          local dir = line:match('^cd%s+(.+)$')
          if dir then
            local expanded = vim.fn.expand(dir)
            local session_root = vim.fn.system(
              'git -C ' .. vim.fn.shellescape(expanded) .. ' rev-parse --show-toplevel 2>/dev/null'
            ):gsub('\n', '')
            if session_root == git_root then include = true end
            break
          end
        end
        fh:close()
      end
    end
    if include then
      table.insert(names, vim.fn.fnamemodify(f, ':t:r'))
    end
  end

  pickers.new({}, {
    prompt_title = '📂 Sessions  <CR>=ロード <C-d>=削除 <C-r>=リネーム <C-o>=上書保存',
    finder = finders.new_table({ results = names }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then session_load(sel[1]) end
      end)
      local function delete_session()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then
          vim.fn.delete(session_dir .. '/' .. sel[1] .. '.vim')
          picker:delete_selection(function() vim.notify('Session deleted: ' .. sel[1]) end)
        end
      end
      local function rename_session()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local old_name = sel[1]
        actions.close(prompt_bufnr)
        vim.schedule(function()
          local new_name = vim.fn.input('Rename session: ', old_name)
          vim.cmd('redraw')
          if new_name == '' or new_name == old_name then return end
          local old_path = session_dir .. '/' .. old_name .. '.vim'
          local new_path = session_dir .. '/' .. new_name .. '.vim'
          if vim.fn.rename(old_path, new_path) == 0 then
            vim.notify('Session renamed: ' .. old_name .. ' → ' .. new_name, vim.log.levels.INFO)
          else
            vim.notify('Rename failed', vim.log.levels.ERROR)
          end
          telescope_session_picker()
        end)
      end
      local function overwrite_session()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        actions.close(prompt_bufnr)
        vim.schedule(function() session_save(sel[1]) end)
      end
      map_modes(map, '<C-d>', delete_session)
      map_modes(map, '<C-r>', rename_session)
      map_modes(map, '<C-o>', overwrite_session)
      return true
    end,
    layout_strategy = 'vertical',
    layout_config   = { height = 0.5, width = 0.4, prompt_position = 'top' },
  }):find()
end

vim.api.nvim_create_user_command('Uss', function(opts)
  session_save(opts.args ~= '' and opts.args or nil)
end, { nargs = '?' })

-- [fzf]us（vimrc.d/search-keymaps.vim）用: fzf 版を telescope 実装で置き換え
-- plain vim では vimrc.d/fzf.vim が同名コマンドを定義する
vim.api.nvim_create_user_command('MySessionLoad', telescope_session_picker, {})

vim.keymap.set('n', 'uss',  '<Cmd>Uss<CR>', { desc = 'Session save (default)' })
vim.keymap.set('n', 'us',   telescope_session_picker, { desc = 'Session load (telescope)' })
vim.keymap.set('n', 'usos', function()
  local current = vim.v.this_session
  local name = (current ~= '') and vim.fn.fnamemodify(current, ':t:r') or 'default'
  local input = vim.fn.input('save current session? session_name=' .. name .. ' y or n ')
  vim.cmd('redraw')
  if input == 'y' then
    session_save(name)
  else
    vim.notify('canceled. session_name=' .. name, vim.log.levels.INFO)
  end
end, { desc = 'Session override save' })
