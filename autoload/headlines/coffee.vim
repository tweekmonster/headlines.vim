function! headlines#coffee#find() abort
  let l2 = 0

  while l2 < line('$')
    let l2 += 1
    let text = getline(l2)
    if text !~# '^\s*$' && text !~# '^\%(\S\+\s*=\s*\)\?\<\%(import\|require\)\>'
      let l2 -= 1
      break
    endif
  endwhile

  return [1, l2]
endfunction
