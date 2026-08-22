-- Memo を起点に関数の呼び出し関係を LSP でたどり、テキストツリーを出力する
-- 起動は etc/callgraph.sh 経由（nvim -l で実行されるため個人設定は読み込まれない）
--
-- 呼び出し先の判定方式:
--   関数の range 内から「識別子(」の形を拾い、その位置に textDocument/definition を投げ、
--   定義先が関数シンボルなら呼び出し先とみなす。
--   callHierarchy 非対応のサーバー（lua_ls など）でも動作させるためこの方式を採る。

-- -l 起動では個人設定の lua/ が package.path に入らないため、自身の位置から解決する
local self_dir = debug.getinfo(1, 'S').source:sub(2):gsub('[^/\\]+$', '')
package.path = self_dir .. '../?.lua;' .. package.path

local lsp_servers = require('lsp_servers')

-- ---------------------------------------------------------------- ユーティリティ

local function norm(path)
  return (path:gsub('\\', '/'))
end

-- 絶対パス化してシンボリックリンクも解決する
-- ~/.config/nvim → dotfiles/nvim のようなリンク経由の定義をルート外と誤判定しないため
local function abspath(path)
  local full = vim.fn.fnamemodify(vim.fn.expand(path), ':p')
  local real = ((vim.uv or vim.loop).fs_realpath(full))
  return (norm(real or full):gsub('/$', ''))
end

local function die(msg)
  io.stderr:write('callgraph: ' .. msg .. '\n')
  os.exit(1)
end

-- ---------------------------------------------------------------- 引数

local opts = {
  keyword   = '検索: この関数を起点とした呼び出しを調べる',
  root      = norm(vim.fn.getcwd()),
  depth     = 5,
  memo_file = norm(vim.fn.expand('~/.vim/memos.json')),
  output    = nil,
  format    = 'tree',
  direction = 'out',
  timeout   = 30000,
  external  = false,
  location  = true,
  quiet     = false,
}

do
  local a = _G.arg or {}
  local i = 1
  local function value(name)
    i = i + 1
    if a[i] == nil then die(name .. ' には値が必要です') end
    return a[i]
  end
  local function number(name)
    local n = tonumber(value(name))
    if not n then die(name .. ' には数値を指定してください') end
    return n
  end
  while a[i] do
    local o = a[i]
    if     o == '-k' or o == '--keyword'   then opts.keyword   = value(o)
    elseif o == '-r' or o == '--root'      then opts.root      = abspath(value(o))
    elseif o == '-d' or o == '--depth'     then opts.depth     = number(o)
    elseif o == '-o' or o == '--output'    then opts.output    = value(o)
    elseif o == '-m' or o == '--memo-file' then opts.memo_file = abspath(value(o))
    elseif o == '--format'                 then opts.format    = value(o)
    elseif o == '--direction'              then opts.direction = value(o)
    elseif o == '--timeout'                then opts.timeout   = number(o)
    elseif o == '--external'               then opts.external  = true
    elseif o == '--no-loc'                 then opts.location  = false
    elseif o == '-q' or o == '--quiet'     then opts.quiet     = true
    elseif o:sub(1, 1) == '-'              then die('不明なオプション: ' .. o)
    else opts.keyword = o
    end
    i = i + 1
  end
end

if opts.format ~= 'tree' and opts.format ~= 'md' and opts.format ~= 'json' then
  die('--format は tree / md / json のいずれかです: ' .. opts.format)
end
if opts.direction ~= 'out' and opts.direction ~= 'in' then
  die('--direction は out / in のいずれかです: ' .. opts.direction)
end

local function log(msg)
  if not opts.quiet then io.stderr:write('callgraph: ' .. msg .. '\n') end
end

-- ---------------------------------------------------------------- メモ抽出

local function under_root(path)
  return path:sub(1, #opts.root + 1) == opts.root .. '/'
end

local function read_roots()
  local fh = io.open(opts.memo_file, 'r')
  if not fh then die('メモファイルが読めません: ' .. opts.memo_file) end
  local raw = fh:read('*a')
  fh:close()
  local ok, data = pcall(vim.fn.json_decode, raw)
  if not (ok and type(data) == 'table') then die('メモファイルの JSON が壊れています: ' .. opts.memo_file) end

  local roots = {}
  for filepath, entries in pairs(data) do
    local path = abspath(filepath)
    if under_root(path) and type(entries) == 'table' then
      for _, e in ipairs(entries) do
        if type(e) == 'table' and type(e.text) == 'string'
          and e.text:find(opts.keyword, 1, true) then
          table.insert(roots, { path = path, line = e.line, text = e.text })
        end
      end
    end
  end
  table.sort(roots, function(x, y)
    if x.path ~= y.path then return x.path < y.path end
    return x.line < y.line
  end)
  return roots
end

-- ---------------------------------------------------------------- バッファ / シンボル

local bufs = {}

local function ensure_buf(path)
  if bufs[path] ~= nil then return bufs[path] or nil end
  if vim.fn.filereadable(path) == 0 then
    log('ファイルが見つかりません: ' .. path)
    bufs[path] = false
    return nil
  end
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)
  -- -l 起動では filetype 自動判定が働かないため明示的に設定する（FileType 発火で LSP が attach する）
  if vim.bo[bufnr].filetype == '' then
    local ft = vim.filetype.match({ filename = path, buf = bufnr })
    if ft then vim.bo[bufnr].filetype = ft end
  end
  local attached = vim.wait(opts.timeout, function()
    return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
  end, 100)
  if not attached then log('LSP が接続できませんでした: ' .. path) end
  bufs[path] = bufnr
  return bufnr
end

-- SymbolKind: Method=6, Constructor=9, Function=12
local FUNC_KINDS = { [6] = true, [9] = true, [12] = true }

local sym_cache = {}

-- documentSymbol の結果を平坦化する（DocumentSymbol / SymbolInformation の両形式に対応）
local function flatten(list, path, out)
  for _, s in ipairs(list or {}) do
    local sel   = s.selectionRange or (s.location and s.location.range) or s.range
    local range = s.range or (s.location and s.location.range)
    if sel and range then
      table.insert(out, {
        name  = s.name,
        kind  = s.kind,
        path  = path,
        srow  = sel.start.line,
        scol  = sel.start.character,
        rstart = range.start.line,
        rend  = range['end'].line,
      })
    end
    if s.children then flatten(s.children, path, out) end
  end
  return out
end

local function doc_symbols(path)
  if sym_cache[path] ~= nil then return sym_cache[path] end
  local bufnr = ensure_buf(path)
  if not bufnr then sym_cache[path] = {}; return {} end
  local params = { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }
  local syms = {}
  -- 起動直後はインデックス未完了で空が返ることがあるため数回リトライする
  for _ = 1, 3 do
    local res = vim.lsp.buf_request_sync(bufnr, 'textDocument/documentSymbol', params, opts.timeout)
    for _, r in pairs(res or {}) do
      if r.result then flatten(r.result, path, syms) end
    end
    if #syms > 0 then break end
    vim.wait(500)
  end
  sym_cache[path] = syms
  return syms
end

local function is_func(sym) return FUNC_KINDS[sym.kind] end

-- 指定行を含む最も内側の関数シンボルを返す
local function enclosing_symbol(path, line0)
  local best
  for _, s in ipairs(doc_symbols(path)) do
    if is_func(s) and s.rstart <= line0 and line0 <= s.rend then
      if not best or (s.rend - s.rstart) < (best.rend - best.rstart) then best = s end
    end
  end
  return best
end

-- メモ行から起点となる関数シンボルを決める
-- ①メモ行が関数名の行 → ②メモ行を含む関数 → ③メモ行以降で最初の関数
local function symbol_for_memo(path, line0)
  local syms = doc_symbols(path)
  for _, s in ipairs(syms) do
    if is_func(s) and s.srow == line0 then return s end
  end
  local enc = enclosing_symbol(path, line0)
  if enc then return enc end
  local best
  for _, s in ipairs(syms) do
    if is_func(s) and s.rstart >= line0 then
      if not best or s.rstart < best.rstart then best = s end
    end
  end
  return best
end

-- 定義位置に対応する関数シンボルを返す（関数でなければ nil）
local function symbol_at(path, line0)
  for _, s in ipairs(doc_symbols(path)) do
    if is_func(s) and (s.srow == line0 or s.rstart == line0) then return s end
  end
  return nil
end

-- ---------------------------------------------------------------- 呼び出し位置の抽出

local LINE_COMMENT = {
  lua = '--', vim = '"', sh = '#', bash = '#', zsh = '#', python = '#', ruby = '#',
  perl = '#', yaml = '#', toml = '#', make = '#', sql = '--', haskell = '--',
}

-- 呼び出しとして扱わない予約語（言語横断でまとめて除外する）
local KEYWORDS = {}
for w in ([[if elseif else for while do end return function fun func def switch case when
  catch try finally throw new delete typeof instanceof await async defer go select and or not
  in is as with print2 repeat until then local var val let const class object interface enum
  public private protected internal static override suspend init sizeof]]):gmatch('%S+') do
  KEYWORDS[w] = true
end

-- 呼び出し名と解決したシンボル名が対応するか判定する
-- 引数名などが同じ行の関数シンボルに誤って結び付くのを防ぐ（M.foo と foo の対応は許容）
local function name_matches(sym_name, call_name)
  if sym_name == call_name then return true end
  return sym_name:match('([%w_]+)$') == call_name
end

-- 文字列リテラルとコメントを同じ長さの空白に置換する（列位置を保つため）
local function mask(line, ft)
  local function blank(s) return string.rep(' ', #s) end
  line = line:gsub('"[^"]*"', blank):gsub("'[^']*'", blank)
  local cs = LINE_COMMENT[ft] or '//'
  local at = line:find(cs, 1, true)
  if at then line = line:sub(1, at - 1) end
  return line
end

-- バイト列位置を LSP の文字位置（既定 utf-16）へ変換する
local function lsp_col(line, byte_col)
  if not line:sub(1, byte_col):find('[\128-\255]') then return byte_col end
  local prefix = line:sub(1, byte_col)
  local ok, v = pcall(vim.str_utfindex, prefix, 'utf-16')
  if ok and type(v) == 'number' then return v end
  local ok2, _, u16 = pcall(vim.str_utfindex, prefix)
  if ok2 and type(u16) == 'number' then return u16 end
  return byte_col
end

-- 関数の range 内から呼び出しらしい位置を集める
local function scan_calls(bufnr, sym)
  local ft    = vim.bo[bufnr].filetype
  local lines = vim.api.nvim_buf_get_lines(bufnr, sym.rstart, sym.rend + 1, false)
  local seen, out = {}, {}
  for idx, raw in ipairs(lines) do
    local line  = mask(raw, ft)
    local line0 = sym.rstart + idx - 1
    local init  = 1
    while true do
      local s, e, name = line:find('([%a_][%w_]*)%s*%(', init)
      if not s then break end
      init = e
      local prev = line:sub(1, s - 1):match('([%a_]+)%s*$')
      -- 予約語・宣言（function foo( 等）・宣言行にある自分自身の名前は除外する
      local is_decl = (prev and (prev == 'function' or prev == 'fun' or prev == 'def'))
        or (line0 == sym.srow and name_matches(sym.name, name))
      if not KEYWORDS[name] and not is_decl and not seen[name] then
        seen[name] = true
        table.insert(out, { name = name, line = line0, col = lsp_col(line, s - 1) })
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------- LSP 問い合わせ

local function first_location(res)
  for _, r in pairs(res or {}) do
    local result = r.result
    if result then
      if result.uri or result.targetUri then result = { result } end
      for _, loc in ipairs(result) do
        local uri   = loc.uri or loc.targetUri
        local range = loc.range or loc.targetSelectionRange or loc.targetRange
        if uri and range then return uri, range.start.line, range.start.character end
      end
    end
  end
end

local def_cache = {}

local function definition(bufnr, line0, col0)
  local key = bufnr .. ':' .. line0 .. ':' .. col0
  if def_cache[key] ~= nil then
    local c = def_cache[key]
    return c[1], c[2], c[3]
  end
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position     = { line = line0, character = col0 },
  }
  local res = vim.lsp.buf_request_sync(bufnr, 'textDocument/definition', params, opts.timeout)
  local uri, line, col = first_location(res)
  def_cache[key] = { uri, line, col }
  return uri, line, col
end

-- 別名宣言（local f = mod.func）の右辺末尾の識別子位置を返す
local function alias_rhs(bufnr, line0)
  local text = (vim.api.nvim_buf_get_lines(bufnr, line0, line0 + 1, false))[1]
  if not text then return nil end
  local eq = text:find('=')
  if not eq then return nil end
  local rhs, last_s, last_name = text:sub(eq + 1), nil, nil
  local init = 1
  while true do
    local s, e, name = rhs:find('([%a_][%w_]*)', init)
    if not s then break end
    init, last_s, last_name = e + 1, s, name
  end
  if not last_name then return nil end
  return lsp_col(text, eq + last_s - 1)
end

-- 定義先が関数でない場合、別名（local f = mod.func / import 文）とみなして
-- もう一段 definition を辿る。Lua のローカル別名や TS の import 経由の呼び出しに対応する。
local function resolve_definition(bufnr, line0, col0)
  local uri, dline, dcol = definition(bufnr, line0, col0)
  if not uri then return nil end
  local path = abspath(vim.uri_to_fname(uri))
  if not under_root(path) or symbol_at(path, dline) then return uri, dline, dcol end
  local nbuf = ensure_buf(path)
  if not nbuf or (nbuf == bufnr and dline == line0) then return uri, dline, dcol end
  -- ①定義位置からもう一段辿る（import 文経由など）
  -- ②それでも関数に届かなければ別名宣言の右辺から辿る（local f = mod.func）
  for _, col in ipairs({ dcol or 0, alias_rhs(nbuf, dline) }) do
    local uri2, dline2, dcol2 = definition(nbuf, dline, col)
    if uri2 then
      local path2 = abspath(vim.uri_to_fname(uri2))
      if not (path2 == path and dline2 == dline) and symbol_at(path2, dline2) then
        return uri2, dline2, dcol2
      end
    end
  end
  return uri, dline, dcol
end

local function references(bufnr, sym)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position     = { line = sym.srow, character = sym.scol or 0 },
    context      = { includeDeclaration = false },
  }
  local res = vim.lsp.buf_request_sync(bufnr, 'textDocument/references', params, opts.timeout)
  local locs = {}
  for _, r in pairs(res or {}) do
    for _, loc in ipairs(r.result or {}) do
      local uri   = loc.uri or loc.targetUri
      local range = loc.range or loc.targetRange
      if uri and range then table.insert(locs, { uri = uri, line = range.start.line }) end
    end
  end
  return locs
end

-- ---------------------------------------------------------------- 探索

-- 呼び出し先（out）: 本体中の識別子を definition で解決して関数シンボルを集める
local function callees(sym)
  local bufnr = ensure_buf(sym.path)
  if not bufnr then return {} end
  local found, out = {}, {}
  for _, call in ipairs(scan_calls(bufnr, sym)) do
    local uri, line0, col0 = resolve_definition(bufnr, call.line, call.col)
    if uri then
      local path = abspath(vim.uri_to_fname(uri))
      if under_root(path) or opts.external then
        local target = under_root(path) and symbol_at(path, line0) or
          { name = call.name, path = path, srow = line0, rstart = line0, rend = line0, kind = 12, external = true }
        if target and name_matches(target.name, call.name) then
          local key = target.path .. ':' .. target.srow
          if not found[key] then
            found[key] = true
            table.insert(out, target)
          end
        end
      end
    end
  end
  return out
end

-- 呼び出し元（in）: references の各位置を囲む関数シンボルを集める
local function callers(sym)
  local bufnr = ensure_buf(sym.path)
  if not bufnr then return {} end
  local found, out = {}, {}
  for _, loc in ipairs(references(bufnr, sym)) do
    local path = abspath(vim.uri_to_fname(loc.uri))
    if under_root(path) then
      local target = enclosing_symbol(path, loc.line)
      if target then
        local key = target.path .. ':' .. target.srow
        if not found[key] then
          found[key] = true
          table.insert(out, target)
        end
      end
    end
  end
  return out
end

local function node_of(sym)
  return {
    name     = sym.name,
    path     = sym.path,
    line     = sym.srow + 1,
    external = sym.external,
    children = {},
  }
end

local function expand(sym, node, depth, visited, ancestors)
  if depth >= opts.depth then
    node.note = 'depth'
    return
  end
  if node.external then return end
  local children = (opts.direction == 'out') and callees(sym) or callers(sym)
  for _, child in ipairs(children) do
    local key   = child.path .. ':' .. child.srow
    local cnode = node_of(child)
    if ancestors[key] then
      cnode.note = 'cycle'
    elseif visited[key] then
      cnode.note = 'seen'
    else
      visited[key]   = true
      ancestors[key] = true
      expand(child, cnode, depth + 1, visited, ancestors)
      ancestors[key] = nil
    end
    table.insert(node.children, cnode)
  end
end

-- ---------------------------------------------------------------- 出力

local NOTE = { seen = '(既出)', cycle = '(循環)', depth = '…', external = '(外部)' }

local function relpath(path)
  if under_root(path) then return path:sub(#opts.root + 2) end
  return path
end

local function label(node)
  local s = node.name
  if opts.location then s = s .. '  (' .. relpath(node.path) .. ':' .. node.line .. ')' end
  if node.external then s = s .. '  ' .. NOTE.external end
  if node.note then s = s .. '  ' .. NOTE[node.note] end
  return s
end

local function render_tree(node, depth, out)
  local prefix = depth == 0 and '' or (string.rep('　', depth) .. '→')
  table.insert(out, prefix .. label(node))
  for _, c in ipairs(node.children) do render_tree(c, depth + 1, out) end
end

local function render_md(node, depth, out)
  table.insert(out, string.rep('  ', depth) .. '- ' .. label(node))
  for _, c in ipairs(node.children) do render_md(c, depth + 1, out) end
end

-- ---------------------------------------------------------------- 実行

lsp_servers.setup_headless()

local roots = read_roots()
if #roots == 0 then
  die(string.format('キーワードに一致するメモがありません: "%s" (root=%s)', opts.keyword, opts.root))
end
log(string.format('起点メモ %d 件 / 方向=%s / 深さ=%d', #roots, opts.direction, opts.depth))

local trees = {}
for _, memo in ipairs(roots) do
  local line0 = math.max(0, (memo.line or 1) - 1)
  local sym   = symbol_for_memo(memo.path, line0)
  if not sym then
    log(string.format('関数を特定できませんでした: %s:%d', relpath(memo.path), memo.line))
  else
    log(string.format('探索中: %s (%s:%d)', sym.name, relpath(sym.path), sym.srow + 1))
    local node = node_of(sym)
    local key  = sym.path .. ':' .. sym.srow
    expand(sym, node, 0, { [key] = true }, { [key] = true })
    table.insert(trees, node)
  end
end

local lines = {}
if opts.format == 'json' then
  table.insert(lines, vim.json.encode({ direction = opts.direction, root = opts.root, trees = trees }))
else
  for i, tree in ipairs(trees) do
    if i > 1 then table.insert(lines, '') end
    if opts.format == 'md' then render_md(tree, 0, lines) else render_tree(tree, 0, lines) end
  end
end

local text = table.concat(lines, '\n') .. '\n'
if opts.output then
  local fh = io.open(opts.output, 'w')
  if not fh then die('出力ファイルを開けません: ' .. opts.output) end
  fh:write(text)
  fh:close()
  log('出力しました: ' .. opts.output)
else
  io.stdout:write(text)
end
io.stdout:flush()
os.exit(0)
