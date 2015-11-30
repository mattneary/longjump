" longjump.vim - Cross-process buffer jumping.
" Maintainer:   Matt Neary <http://mattneary.com>
" Version:      1.0
function! BroadcastBuffers(window, pane, fifo)
  let currBuff=bufnr("%")
  bufdo execute "call system(\"echo '\". a:window . \"\t\" . a:pane . \"\t\" . bufnr('%') . \"\t\" . expand(\"%:p\") . \"' > \" . a:fifo)"
  execute 'buffer ' . currBuff
  call system("echo 'done' > " . a:fifo)
endfunction

