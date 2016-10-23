command! -nargs=0 Headlines call headlines#toggle()


augroup headlines
  autocmd!
  autocmd SessionLoadPost headlines://* :bd!
augroup END


highlight default link HeadlinesStatusLabel WildMenu

nnoremap <silent> <Plug>(HeadlinesToggle) :<c-u>call headlines#toggle()<cr>

let s:map = get(g:, 'headlines_key', '<localleader><localleader>')
if !empty(s:map)
  execute 'nmap '.s:map.' <Plug>(HeadlinesToggle)'
endif
