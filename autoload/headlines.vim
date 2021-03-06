let s:cursors = {}
let s:default_markers = {
      \ 'python': '\n\_^\%(@\|\%(def\|class\)\>\s\+\)\i\+',
      \ 'html': ['^\s*<head\>.*\_$\n\zs', '\n\_^\s*</head\>'],
      \ 'htmldjango': '\n\_^\s*\%({%\s*\<\%(load\|extends\)\>\_.\+\_$\|\_$\)\@!',
      \ 'go': '\n\%(\_^//.*\n\)*\_^\s*func\>',
      \ 'vim': '\n\_^\s*fu\%[nction]\>',
      \ 'markdown': function('headlines#markdown#find'),
      \ 'javascript': function('headlines#javascript#find'),
      \ 'coffee': function('headlines#coffee#find'),
      \ 'ruby': '\n\_^\%(module\|def\|class\)\>',
      \ }


function! s:save_cursor()
  let s:cursors[b:_hl.filename] = winsaveview()
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
  let ft = &l:filetype
  let s:_pattern = get(get(g:, 'headlines_markers', s:default_markers), ft, '')
  if empty(s:_pattern)
    unlet! s:_pattern
    return [0, 0, ft]
  endif

  let view = winsaveview()
  call cursor(1, 1)

  let line1 = 0
  let line2 = 0
  let ptype = type(s:_pattern)
  if ptype == type('')
    let line1 = 1
    let line2 = search(s:_pattern, 'nW')
  elseif ptype == type(function('tr'))
    let funcview = winsaveview()
    let ret = call(s:_pattern, [])
    if len(ret) > 1
      let [line1, line2] = ret[:1]
      if len(ret) > 2
        let ft = ret[-1]
      endif
    endif
    call winrestview(funcview)
  elseif ptype == type([])
    let line1 = search(s:_pattern[0], 'ceW')
    if line1
      let line2 = search(s:_pattern[1], 'W')
    endif
  endif

  unlet! s:_pattern
  call winrestview(view)

  if line2 <= 0 || line2 >= line('$')
    " An entire file can't be the headlines
    return [0, 0, ft]
  endif

  return [line1, prevnonblank(line2), ft]
endfunction


function! s:close_headlines() abort
  let last_win = winnr('$')
  if b:_hl.window > last_win
    return
  endif

  let buf = b:_hl.buffer
  call s:win_focus(b:_hl.window)
  execute 'noautocmd' buf 'bufdo setlocal modifiable'
endfunction


function! s:write_headlines() abort
  " The only event that should be triggered is TextChanged on the source
  " buffer.
  let ei = &eventignore
  set eventignore=all

  setlocal nomodified
  let hbuf = winbufnr(0)
  let sbuf = b:_hl.buffer

  " Restore indentation
  let new_lines = map(getline(1, '$'),
        \ '(v:val !~# ''^\s*$'' ? repeat(b:_hl.indent_char, b:_hl.indent) : '''').v:val')
  let cur_lines = getbufline(sbuf, b:_hl.lines[0], b:_hl.lines[1])

  if string(new_lines) == string(cur_lines)
    " Nothing to change
    let &eventignore = ei
    return
  endif

  let delta = (line('$') - 1) - (b:_hl.lines[1] - b:_hl.lines[0])

  let bwin = winnr()
  let undopoint = !exists('b:undopoint')
  let lines = b:_hl.lines

  call s:win_focus(b:_hl.window)
  execute sbuf 'bufdo setlocal modifiable'

  " Save all window views related to the buffer
  let views = s:save_views(expand('%:p'))
  for win in keys(views)
    let views[win].topline += delta
    let views[win].lnum += delta
  endfor

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
  let b:_hl.lines[1] += delta
endfunction


function! headlines#toggle(...) abort
  let filename = expand('%')

  if empty(filename)
    echohl WarningMsg
    echo 'Headlines cannot be displayed for unnamed files.'
    echohl None
    return
  endif

  let hbufname = 'headlines://'.filename

  if filename =~# '^headlines://'
    try
      quit
    catch
      echohl ErrorMsg
      echo '[headlines]' matchstr(v:exception, '^Vim[^:]\+:\zs.*')
      echohl None
    endtry
    return
  endif

  let existing_hbuf = bufname(hbufname)
  if existing_hbuf != -1

  endif

  let height = a:0 ? a:1 : get(g:, 'headlines_height', 20)
  let [line1, line2, ft] = s:get_headlines()
  if !line1 || !line2
    echohl WarningMsg
    echo 'Headlines could not be found.'
    echohl None
    return
  endif

  let height = min([height, winheight(0) / 2])
  let buf = winbufnr(0)

  " Protect the buffer from going out of sync
  setlocal nomodifiable

  " Setup headlines window
  silent! execute 'keepalt noautocmd aboveleft' height 'new'
  let swin = winnr('#')
  setlocal winfixwidth winfixheight buftype=acwrite bufhidden=wipe nobuflisted noswapfile

  " Prevent undoing to a blank buffer
  undojoin
  let ul = &l:undolevels
  let &l:undolevels = -1
  let lines = getbufline(buf, line1, line2)

  " Get the lowest indent level
  let min_indent = min(filter(map(copy(lines), 'match(v:val, ''^\s*\_$\@!\zs'')'), 'v:val != -1'))

  let b:_hl = {
        \ 'filename': fnamemodify(filename, ':p'),
        \ 'window': swin,
        \ 'buffer': buf,
        \ 'lines': [line1, line2],
        \ 'indent': min_indent,
        \ 'indent_char': &l:expandtab ? ' ' : "\t",
        \ }

  " Strip mininum indent from all the lines.
  call map(lines, 'v:val[min_indent:]')

  call setline(1, lines)
  setlocal nomodified
  let &l:undolevels = ul

  execute 'setlocal filetype='.ft
  if exists('w:airline_active')
    let w:airline_disabled = 1
  endif
  silent execute 'file '.hbufname

  execute 'setlocal statusline=%#HeadlinesStatusLabel#'
        \.substitute(' Headlines %* '.filename.' %m %=L%l/%L: %c', ' ', '\\ ', 'g')

  if has_key(s:cursors, b:_hl.filename)
    call winrestview(s:cursors[b:_hl.filename])
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
