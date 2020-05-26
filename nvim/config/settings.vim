set nocompatible
filetype off

set cursorline
set cursorcolumn
set number
set showmatch
set colorcolumn=80

set list
set listchars=tab:▸\ ,eol:¬,trail:-,precedes:<,extends:>

set scrolloff=8
set sidescrolloff=15

set hlsearch
set incsearch
map <silent> <Leader>, :nohlsearch<CR>  " Clears previous search

syntax on

set splitright
set splitbelow

augroup vimrc
  autocmd!
  autocmd BufWritePre * call s:strip_trailing_whitespace()                      " Auto-remove trailing spaces
  autocmd InsertEnter * set nocursorline                                        " Remove cursorline highlight
  autocmd InsertLeave * set cursorline                                          " Add cursorline highlight in normal mode
  autocmd FocusGained,BufEnter * silent! exe 'checktime'                        " Refresh file when vim gets focus
  autocmd FileType vim inoremap <buffer><silent><C-Space> <C-x><C-v>
  autocmd TermOpen * setlocal nonumber norelativenumber
  autocmd VimEnter * call s:set_path()
augroup END

" Function definitions
"
function! s:strip_trailing_whitespace()
  if &modifiable
    let l:l = line('.')
    let l:c = col('.')
    call execute('%s/\s\+$//e')
    call histdel('/', -1)
    call cursor(l:l, l:c)
  endif
endfunction

function! s:set_path() abort
  let l:dirs = filter(systemlist('find . -maxdepth 1 -type d'), {_,dir ->
        \ !empty(dir) && empty(filter(split(&wildignore, ','), {_,v -> v =~? dir[2:]}))
        \ })

  if !empty(l:dirs)
    let &path = &path.','.join(map(l:dirs, 'v:val[2:]."/**/*"'), ',')
  endif
endfunction
