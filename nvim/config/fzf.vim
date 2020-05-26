let $FZF_DEFAULT_COMMAND = 'ag -g ""'
let $FZF_DEFAULT_OPTS='--layout=reverse --border'

function! CreateCenteredFloatingWindow()
  let width = float2nr(&columns * 0.7)
  let height = float2nr(&lines * 0.7)
  let opts = {
        \ 'relative': 'editor',
        \ 'row': (&lines - height) / 2,
        \ 'col': (&columns - width) / 2,
        \ 'width': width,
        \ 'height': height,
        \ 'style': 'minimal'
        \ }
  set winhl=Normal:Floating
  call nvim_open_win(nvim_create_buf(v:false, v:true), v:true, opts)
endfunction

function! s:goto_def(lines) abort
  silent! exe 'e +BTags '.a:lines[0]
  call timer_start(10, {-> execute('startinsert') })
endfunction

function! s:goto_line(lines) abort
  silent! exe 'e '.a:lines[0]
  call timer_start(10, {-> feedkeys(':') })
endfunction

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit',
  \ '@': function('s:goto_def'),
  \ ':': function('s:goto_line')
  \  }

let g:fzf_layout = { 'window': 'call CreateCenteredFloatingWindow()' }

command! -bang -nargs=* FZFHidden
  \ call fzf#run(fzf#wrap({'source': 'ag -g "" --hidden --ignore .git'}))

command! -bang -nargs=* FZFAll
  \ call fzf#run(fzf#wrap({'source': 'ag -g "" --skip-vcs-ignores --hidden --ignore .git'}))

nnoremap <silent><C-p> :FZF<CR>
nnoremap <silent><C-o> :FZFHidden<CR>
nnoremap <silent><Leader>p :FZFAll<CR>
