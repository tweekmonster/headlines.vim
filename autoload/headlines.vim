let s:cursors = {}
let s:default_markers = {
      \ 'python': '\n\_^\%(@\|\%(def\|class\)\>\s\+\)\i\+',
      \ 'html': ['^\s*<head\>.*\_$\n\zs', '\n\_^\s*</head\>'],
      \ 'htmldjango': '\n\_^\s*\%({%\s*\<\%(load\|extends\)\>\_.\+\_$\|\_$\)\@!',
      \ 'go': '\n\%(\_^//.*\n\)*\_^\s*func\>',
      \ 'vim': '\n\_^\s*fu\%[nction]\>'
      \ }


function! s:save_cursor()
  let s:cursors[b:_filename] = winsaveview()
endfunction


function! s:win_focus(win) abort
  silent execute 'noautocmd' a:win 'wincmd w'
endfunction


function! s:save_views(filename) abort
  let windows = {}
  let hwin = winnr()
  windo if expand('%:p') == a:filename | let windows[winnr()] = winsaveview() | endif
  call s:win_focus(hwin)
  return windows
endfunction


function! s:restore_views(views) abort
  let hwin = winnr()
  for win in keys(a:views)
    execute win 'windo call winrestview(a:views[win])'
  endfor
  call s:win_focus(hwin)
endfunction


function! s:get_headlines() abort
  let pattern = get(get(g:, 'headlines_markers', s:default_markers), &l:filetype, '')
  if empty(pattern)
    return [0, 0]
  endif

  let view = winsaveview()
  keepjumps normal! gg

  let line1 = 0
  let line2 = 0
  let ptype = type(pattern)
  if ptype == 1
    let line1 = 1
    let line2 = search(pattern, 'nW')
  elseif ptype == 2
    let funcview = winsaveview()
    let [line1, line2] = call(pattern)
    call winrestview(funcview)
  elseif ptype == 3
    let line1 = search(pattern[0], 'ceW')
    if line1
      let line2 = search(pattern[1], 'W')
    endif
  endif

  call winrestview(view)

  if !line2 || line2 == line('$')
    " An entire file can't be the headlines
    return [0, 0]
  endif

  return [line1, line2]
endfunction


function! s:close_headlines() abort
  let last_win = winnr('$')
  if b:_window > last_win
    echo 'wintf'
    return
  endif

  let buf = b:_buffer
  call s:win_focus(b:_window)
  execute 'noautocmd' buf 'bufdo setlocal modifiable'
endfunction


function! s:write_headlines() abort
  " The only event that should be triggered is TextChanged on the source
  " buffer.
  let ei = &eventignore
  set eventignore=all

  setlocal nomodified
  let hbuf = winbufnr(0)
  let sbuf = b:_buffer

  " Restore indentation
  let new_lines = map(getline(1, '$'), '(v:val !~# ''^\s*$'' ? repeat(b:_indent_char, b:_indent) : '''').v:val')
  let cur_lines = getbufline(sbuf, b:_lines[0], b:_lines[1])

  if string(new_lines) == string(cur_lines)
    " Nothing to change
    return
  endif

  let delta = (line('$') - 1) - (b:_lines[1] - b:_lines[0])

  let bwin = winnr()
  let undopoint = !exists('b:undopoint')

  call s:win_focus(b:_window)
  execute sbuf 'bufdo setlocal modifiable'

  " Save all window views related to the buffer
  let views = s:save_views(expand('%:p'))
  for win in keys(views)
    let views[win].topline += delta
    let views[win].lnum += delta
  endfor

  let lines = getbufvar(hbuf, '_lines')

  if get(g:, 'headlines_single_undo', 1)
    if undopoint
      " Force an undo point to join with
      execute "normal! a\<space>\<bs>"
      call setbufvar(hbuf, 'undopoint', 1)
    endif

    undojoin
  endif

  execute 'silent' lines[0] 'delete _' ((lines[1] - lines[0]) + 1)
  silent call append(lines[0] - 1, new_lines)
  let &eventignore = ei
  doautocmd TextChanged
  setlocal nomodifiable

  call s:restore_views(views)
  call s:win_focus(bwin)
  let b:_lines[1] += delta
endfunction


function! headlines#toggle(...) abort
  let filename = expand('%')
  let hbufname = 'headlines://'.filename

  if filename =~# '^headlines://'
    try
      quit
    catch //
      echohl ErrorMsg
      echo '[headlines]' matchstr(v:exception, '^Vim[^:]\+:\zs.*')
      echohl None
    endtry
    " if &l:modified
    "   echohl ErrorMsg
    "   echo '[headlines] There are unsaved changes. Use :wq or :q! instead.'
    "   echohl None
    " else
    "   wincmd c
    " endif
    return
  endif

  let existing_hbuf = bufname(hbufname)
  if existing_hbuf != -1

  endif

  let height = a:0 ? a:1 : get(g:, 'headlines_height', 20)
  let [line1, line2] = s:get_headlines()
  if !line1 || !line2
    echohl WarningMsg
    echo 'Headlines could not be found.'
    echohl None
    return
  endif

  let height = min([height, winheight(0) / 2])
  let buf = winbufnr(0)

  " Save view before opening the window
  let view = winsaveview()

  " Protect the buffer from going out of sync
  setlocal nomodifiable

  " Setup headlines window
  silent! execute 'keepalt noautocmd aboveleft' height 'new'
  let hwin = winnr()
  let swin = winnr('#')
  setlocal winfixwidth winfixheight buftype=acwrite bufhidden=wipe nobuflisted noswapfile

  " Prevent undoing to a blank buffer
  undojoin
  let ul = &l:undolevels
  let &l:undolevels = -1
  let lines = getbufline(buf, line1, line2)

  let b:_filename = fnamemodify(filename, ':p')
  let b:_window = swin
  let b:_buffer = buf
  let b:_lines = [line1, line2]

  " Get the lowest indent level
  let min_indent = min(filter(map(copy(lines), 'match(v:val, ''^\s*\_$\@!\zs'')'), 'v:val != -1'))
  let b:_indent = min_indent
  let b:_indent_char = &l:expandtab ? ' ' : "\t"
  " Strip mininum indent from all the lines.
  call map(lines, 'v:val[min_indent:]')

  call setline(1, lines)
  setlocal nomodified
  let &l:undolevels = ul

  execute 'setlocal filetype='.getbufvar(buf, '&l:filetype')
  if exists('w:airline_active')
    let w:airline_disabled = 1
  endif
  silent execute 'file '.hbufname

  " TODO: Make this less ugly
  execute 'setlocal statusline=%#headlines_label#'.substitute(' Headlines %#headlines_bg# '.filename.' %m %=L%l/%L: %c', ' ', '\\ ', 'g')

  if has_key(s:cursors, b:_filename)
    call winrestview(s:cursors[b:_filename])
  endif

  augroup headlines
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call s:write_headlines()
    autocmd CursorMoved <buffer> call s:save_cursor()
    autocmd BufWinLeave <buffer> call s:close_headlines()
  augroup END

  runtime! ftplugin/headlines.vim
  runtime! after/ftplugin/headlines.vim
endfunction
