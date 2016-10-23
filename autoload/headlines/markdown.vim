function! headlines#markdown#find() abort
  let head = getline(1)
  if head !~# '^\%(+++\|---\)$'
    return [0, 0]
  endif

  call cursor(2, 1)
  let tail = search('^'.head.'$', 'nW')

  if tail && tail - head > 0
    return [2, tail - 1, head == '+++' ? 'toml' : 'yaml']
  endif
endfunction
