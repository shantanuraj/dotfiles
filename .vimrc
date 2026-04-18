if has('termguicolors')
  set termguicolors
endif
syntax enable
filetype plugin indent on

" core
set nocompatible
set autoread
set hidden
set noerrorbells
set belloff=all
set backspace=indent,eol,start
set encoding=utf-8
set fileencoding=utf-8
set re=0
set mouse=a
set undofile
set clipboard=unnamedplus
set timeoutlen=500

" MacVim / GUI
set guicursor=a:blinkon0
set guifont=BerkeleyMono-Regular:h14

" ui
set number
set relativenumber
set noshowmode
set cursorline
set cursorlineopt=number
set scrolloff=10
set sidescrolloff=10
set virtualedit=block
set showmatch
set splitbelow
set splitright
set laststatus=2
set statusline=%f\ %m%r%=%{&filetype}\ %l:%c\

" indentation
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set smarttab
set autoindent

" search
set ignorecase
set smartcase
set hlsearch
set incsearch
set wildmenu
set wildmode=longest,full
set wildignorecase
set wildignore+=*.o,*.obj,*.so,*.a,*.dylib,*.pyc,*.hi
set wildignore+=*.zip,*.gz,*.xz,*.tar,*.rar
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*
set wildignore+=*.png,*.jpg,*.jpeg,*.gif
set wildignore+=*.pdf,*.dmg
set wildignore+=.*.sw*,*~
set wildignore+=.DS_Store

" grep via ripgrep if available
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --glob=!.git
  set grepformat=%f:%l:%c:%m
endif

" netrw
let g:netrw_banner = 0
let g:netrw_list_hide = '\(^\|\s\)\zs\(\.\.\/\|\.\/\|\/\)$'

" built-in %
packadd! matchit

" colorscheme: prefer catppuccin if installed
try
  colorscheme catppuccin
catch /^Vim\%((\a\+)\)\=:E185:/
  colorscheme habamax
endtry

" leader
nnoremap <Space> <Nop>
let mapleader = "\<Space>"
let g:mapleader = "\<Space>"

" movement
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
xnoremap <expr> j v:count == 0 ? 'gj' : 'j'
xnoremap <expr> k v:count == 0 ? 'gk' : 'k'

" clear hlsearch on esc
nnoremap <silent> <esc> :nohlsearch<CR>
inoremap <silent> <esc> <esc>:nohlsearch<CR>

" visual tweaks
vnoremap < <gv
vnoremap > >gv
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
xnoremap <leader>p "_dP

" misc keymaps
nnoremap <C-c> ciw
nnoremap <leader>w :%s/\<<C-r><C-w>\>//g<Left><Left>
nnoremap - :Explore %:p:h<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprev<CR>

" window maximizer toggle
let s:saved_layout = 0
function! s:MaxToggle() abort
  if s:saved_layout
    wincmd =
    let s:saved_layout = 0
  else
    let s:saved_layout = 1
    wincmd _
    wincmd |
  endif
endfunction
nnoremap <silent> <C-w>m :call <SID>MaxToggle()<CR>

" trim trailing whitespace
autocmd BufWritePre * %s/\s\+$//e

" open PDF files
autocmd BufReadPost *.pdf silent %!pdftotext -nopgbrk -layout -q -eol unix "%" - | fmt -w78

" fzf popup picker (no plugin; needs fzf binary + Vim 8.2+ popupwin)
function! s:FzfPickExit(ctx) abort
  let lines = filereadable(a:ctx.tempfile) ? readfile(a:ctx.tempfile) : []
  call delete(a:ctx.tempfile)
  if a:ctx.popup_id > 0
    silent! call popup_close(a:ctx.popup_id)
  endif
  if !empty(lines) && lines[0] !=# ''
    let Sink = a:ctx.Sink
    call timer_start(0, {id -> Sink(lines)})
  endif
endfunction

function! s:FzfPick(cmd, Sink, ...) abort
  if !executable('fzf')
    echohl ErrorMsg | echomsg 'fzf not in PATH' | echohl None
    return
  endif
  if !has('popupwin') || !has('terminal')
    echohl ErrorMsg | echomsg 'Vim missing popup/terminal support' | echohl None
    return
  endif
  let fzf_flags = a:0 >= 1 ? a:1 : ''
  let ctx = {'tempfile': tempname(), 'Sink': a:Sink, 'popup_id': 0}
  let shell_cmd = a:cmd . ' | fzf ' . fzf_flags . ' > ' . ctx.tempfile
  let buf = term_start(['sh', '-c', shell_cmd], {
        \ 'hidden': 1,
        \ 'term_finish': 'close',
        \ 'exit_cb': {job, code -> s:FzfPickExit(ctx)},
        \ })
  let ctx.popup_id = popup_create(buf, {
        \ 'minwidth': float2nr(&columns * 0.6),
        \ 'minheight': float2nr(&lines * 0.6),
        \ 'border': [],
        \ 'padding': [0, 1, 0, 1],
        \ })
endfunction

function! s:FzfOpenFile(lines) abort
  if len(a:lines) == 1
    execute 'edit ' . fnameescape(a:lines[0])
  else
    let items = map(copy(a:lines), '{"filename": v:val, "lnum": 1, "col": 1}')
    call setqflist(items, 'r')
    copen
  endif
endfunction

function! s:FzfFiles() abort
  let cmd = executable('fd')
        \ ? 'fd --type f --hidden --exclude .git'
        \ : 'find . -type f -not -path "*/\.git/*"'
  call s:FzfPick(cmd, function('<SID>FzfOpenFile'),
        \ "--multi --bind 'ctrl-q:select-all+accept'")
endfunction

function! s:FzfOpenGrep(lines) abort
  let items = []
  for line in a:lines
    let l = substitute(line, '\e\[[0-9;]*m', '', 'g')
    let m = matchlist(l, '\v([^:]+):(\d+):(\d+):(.*)')
    if !empty(m)
      call add(items, {'filename': m[1], 'lnum': str2nr(m[2]), 'col': str2nr(m[3]), 'text': m[4]})
    endif
  endfor
  if empty(items) | return | endif
  if len(items) == 1
    execute 'edit ' . fnameescape(items[0].filename)
    call cursor(items[0].lnum, items[0].col)
  else
    call setqflist(items, 'r')
    copen
  endif
endfunction

function! s:FzfGrep() abort
  let rg = 'rg --vimgrep --smart-case --color=always'
  call s:FzfPick(':', function('<SID>FzfOpenGrep'),
        \ "--ansi --disabled --multi"
        \ . " --bind 'change:reload:" . rg . " -- {q} || true'"
        \ . " --bind 'ctrl-q:select-all+accept'")
endfunction

function! s:FzfOpenTag(lines) abort
  execute 'tjump ' . a:lines[0]
endfunction

function! s:FzfTags() abort
  call s:FzfPick("awk -F'\\t' '!/^!/ {print $1}' tags | sort -u",
        \ function('<SID>FzfOpenTag'))
endfunction

nnoremap <silent> <leader><space> :call <SID>FzfFiles()<CR>
nnoremap <silent> <leader>/ :call <SID>FzfGrep()<CR>
nnoremap <silent> <leader>t :call <SID>FzfTags()<CR>

" ctags generation for Go projects
command! MakeTags silent !gotags -R -exclude=vendor -exclude=.git -exclude=node_modules . > tags
nnoremap <silent> <leader>T :MakeTags<CR>
