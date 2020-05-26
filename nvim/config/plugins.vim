
" ====================
" Plugins
" ====================

call plug#begin()

" Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" File Explorer
Plug 'Shougo/defx.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'kristijanhusak/defx-git'
Plug 'kristijanhusak/defx-icons'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

" Git Diff
Plug 'airblade/vim-gitgutter'

" Color themes
Plug 'arzg/vim-colors-xcode'
Plug 'dikiaap/minimalist'
Plug 'joshdick/onedark.vim'

call plug#end()
