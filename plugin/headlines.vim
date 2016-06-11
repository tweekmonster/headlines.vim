command! -nargs=0 Headlines call headlines#toggle()


augroup headlines
  autocmd!
  autocmd SessionLoadPost headlines://* :bd!
augroup END


" Ugly on purpose at the moment
highlight headlines_bg ctermfg=0 ctermbg=3
highlight headlines_label ctermfg=0 ctermbg=6


nnoremap <silent> <Plug>(HeadlinesToggle) :<c-u>call headlines#toggle()<cr>

let s:map = get(g:, 'headlines_key', '<localleader><localleader>')
if !empty(s:map)
  execute 'nmap '.s:map.' <Plug>(HeadlinesToggle)'
endif
