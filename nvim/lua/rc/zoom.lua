-- ZoomWin 代替: backdrop + float window で tmux popup 風の疑似最大化を実現する
-- ,, でトグル開閉
local zoom_float_id    = nil
local zoom_backdrop_id = nil

local function fullscreen_float(bufnr)
  local width  = math.floor(vim.o.columns * 0.95)
  local height = math.floor((vim.o.lines - vim.o.cmdheight - 1) * 0.95)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)
  local win = vim.api.nvim_open_win(bufnr or 0, true, {
    relative  = 'editor',
    row       = row,
    col       = col,
    width     = width,
    height    = height,
    border    = 'rounded',
    zindex    = 50,
  })
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].spell      = false
  return win
end

local function create_backdrop()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative  = 'editor',
    row       = 0,
    col       = 0,
    width     = vim.o.columns,
    height    = vim.o.lines,
    style     = 'minimal',
    border    = 'none',
    focusable = false,
    zindex    = 49,  -- メイン float (50) より手前・通常ウィンドウより奥
  })
  vim.wo[win].winhl = 'Normal:ZoomBackdrop'
  return win, buf
end

local function zoom_toggle()
  if zoom_float_id and vim.api.nvim_win_is_valid(zoom_float_id) then
    vim.api.nvim_win_close(zoom_float_id, false)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local backdrop_win, backdrop_buf = create_backdrop()
  zoom_backdrop_id = backdrop_win
  zoom_float_id    = fullscreen_float(bufnr)
  -- winbar にファイル名と変更状態を表示（airline は floating window に非対応）
  vim.wo[zoom_float_id].winbar = ' %f %m'
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern  = tostring(zoom_float_id),
    once     = true,
    callback = function()
      zoom_float_id = nil
      -- backdrop を閉じてスクラッチバッファを削除する
      if zoom_backdrop_id and vim.api.nvim_win_is_valid(zoom_backdrop_id) then
        vim.api.nvim_win_close(zoom_backdrop_id, true)
      end
      zoom_backdrop_id = nil
      pcall(vim.api.nvim_buf_delete, backdrop_buf, { force = true })
    end,
  })
end

vim.keymap.set('n', ',,', zoom_toggle, { desc = 'Zoom window toggle (float)' })
