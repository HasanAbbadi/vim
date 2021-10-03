" .vimrc

" Plugins: ============ {{{
call plug#begin('~/.vim/plugged')
Plug 'junegunn/goyo.vim'
call plug#end()
" }}}

" Basics: ============= {{{
autocmd FileType vim setlocal foldlevel=0 foldmethod=marker
filetype plugin on
let mapleader = ' ' " magic key

set nocompatible " you're a big boi now
set hidden " more than one unsaved buffer
set nu relativenumber " line numbers
set backspace=indent,eol,start " normal backspace behavior
set ruler " show line info in statusline
set nowrap
set showmode!
set autoindent " auto indent new lines
set formatoptions+=r " easier commenting
set timeoutlen=1000 ttimeoutlen=0 " less timeout

" searching
set smartcase
set incsearch

" search down to subfolders
set path=$PWD/**

" display matching files in a nice menu
set wildmenu
set wildmode=longest,list,full


" prefer spaces over tabs
set expandtab
set smarttab
set shiftwidth=2
set tabstop=2

" eaiser time in visual block
set virtualedit=block

" make unwanted characters visible and also a hack around for indenting
if (&filetype != 'help')
  set listchars=tab:>~,nbsp:_,trail:·,extends:>,precedes:<
  set list
endif

" conceal settings for indenting lines
set conceallevel=1      " 0 is block shape, 1 is visible, 3 is hidden
set concealcursor=nic   " visible in normal, insert and command modes

" list of characters for line indenting
let g:indentLine_char_list = ['▏','|', '¦']
let g:showFirstIndentLevel = 1          " 1 = yes, 0 = no

" remove ~ at the end of the buffer
set fcs=eob:\ 

" folds
set foldcolumn=3

" spell checking
autocmd FileType tex,markdown,groff,html set spell! spelllang=en_us

" a life saver
if !isdirectory($HOME . '/.local/vim/undo')
  call mkdir($HOME . '/.local/vim/undo', 'p', 0700)
endif
set undodir=~/.local/vim/undo/
set undofile

" autocompletion
set completeopt=longest,menuone  " Show menu even if there is only one item

" StatusLine: ========== {{{
let g:currentmode={
      \ 'n'  : 'n',
      \ 'v'  : 'v',
      \ 'V'  : 'vl',
      \ '' : 'vb',
      \ 'i'  : 'i',
      \ 'R'  : 'r',
      \ 'Rv' : 'rv',
      \ 'c'  : 'c',
      \ 't'  : 'f',
      \}

set laststatus=2

" }}}

"===============================
" }}}

" Functions: ========== {{{

" Pretty: {{{
" blink (red) when flipping between matches
function! HLNext (blinktime)
  highlight BlackOnBlack ctermfg=black ctermbg=black
  let [bufnum, lnum, col, off] = getpos('.')
  let matchlen = strlen(matchstr(strpart(getline('.'),col-1),@/))
  let target_pat = '\c\%#'.@/
  let blinks = 1
  hi WhiteOnRed ctermbg=red ctermfg=white
  for n in range(1, blinks)
    let red = matchadd('WhiteOnRed', target_pat, 101)
    redraw
    exec 'sleep ' . float2nr(a:blinktime / (2*blinks) * 1000) . 'm'
    call matchdelete(red)
  endfor
endfunction

function! IndentLines()
  let space = &l:shiftwidth
  let n = len(g:indentLine_char_list)

  if g:showFirstIndentLevel
    let level = 1
    else
    let level = 0
  endif

  for i in range(3, space * 20 + 1, space)
    if n > 0
      let char = g:indentLine_char_list[level % n]
      let level += 1
    else
      let char = g:indentLine_char
    endif
    call add([], matchadd('Conceal', '^\s\+\zs\%'.i.'v ', 0, -1, {'conceal': char}))
  endfor
  if g:showFirstIndentLevel
    execute 'syntax match Underline /^ / containedin=ALL conceal cchar=' . g:indentLine_char_list[0]
  endif
endfunction

" }}}
"
" scrolling
function SmoothScroll(direction)
  let counter=1
  while counter<&scroll
    let counter+=1
    sleep 5m
    redraw
    if (a:direction == 1)
     normal! k
    else
     normal! j
    endif
  endwhile
endfunction

" disable status lien when netrw is in focus
function! NetrwSL()
   if 'netrw' == &filetype
       set laststatus=0
   else
       set laststatus=2
   endif
endfunction

" navigation between opened and closed folds
function! GoToFold(direction, status)
  let start = line('.')
  if (a:direction == "next")
    if(a:status == "opened")
      while (foldclosed(start) != -1)
        let start = start + 1
      endwhile
    else
      while (foldclosed(start) == -1)
        let start = start + 1
      endwhile
    endif
  else
    if(a:status == "opened")
      while (foldclosed(start) != -1)
        let start = start - 1
      endwhile
    else
      while (foldclosed(start) == -1)
        let start = start - 1
      endwhile
    endif
  endif
  call cursor(start, 0)
endfunction

function! SetVimrcMarkers()
  normal! /\v([P])lugins: =mp
  normal! /\v([B])asics: =mb
  normal! /\v([F])unctions: =mf
  normal! /\v([C])olorScheme: =mc
  normal! /\v([A])utoCmd: =ma
  normal! /\v([M])appings: =mm
  normal! /\v([S])nippets: =ms
  normal! /\v([F])ileExplorer: =me
  echohl FoldColumn
  echom "Marks Set"
  echohl none
endfunction

" toggle comments
function! ToggleComment()
  let line_num = line('.')
  if (matchstrpos(getline('.'), b:comment_leader)[1] == 0)
    execute "normal! :".line_num."s+^".b:comment_leader."++ "
    execute "normal! :".line_num."s/^\ *// "
  else
    execute "normal! I".b:comment_leader." "
  endif
endfunction

" kinda smart tab completion
function! TabCompletion()
  if (getline(".")[col(".")-2]) != '' && (getline(".")[col(".")-2]) != ' '
    return "\<C-x>\<C-p>"
  else
    return "\<Tab>"
  endif
endfunction
 
" auto pair punctuations
function! AutoPairs()

  " delete pairs
  function! IsPairClosed()
    " current character
    let cc = (getline(".")[col(".")-2])
    " latter character
    let lc = (getline(".")[col(".")-1])
    if cc == '[' || cc == '(' || cc == '{' || cc == '"' || cc == "'"
      if lc == ']' || lc == ')' || lc == '}' || lc == '"' || lc == "'"
        return "\<bs>\<right>\<bs>"
      else
        return "\<bs>"
      endif
    else
      return "\<bs>"
    endif
  endfunction

  inoremap <expr> < (getline(".")[col(".")]) != '>' ? '<><left>' : '<'
  inoremap <expr> ( (getline(".")[col(".")]) != ')' ? '()<left>' : '('
  inoremap <expr> [ (getline(".")[col(".")]) != ']' ? '[]<left>' : '['
  inoremap <expr> { (getline(".")[col(".")]) != ']' ? '{}<left>' : '{'
  inoremap <expr> ' (getline(".")[col(".")]) != "'" ? "''<left>" : "'"
  inoremap <expr> " (getline(".")[col(".")]) != '"' ? (col(".")-1) != 0 ? '""<left>' : '"' : '"'
 
  inoremap <expr> > (getline(".")[col(".")-1]) == '>' ? '<right>' : '>'
  inoremap <expr> ) (getline(".")[col(".")-1]) == ')' ? '<right>' : ')'
  inoremap <expr> ] (getline(".")[col(".")-1]) == ']' ? '<right>' : ']'
  inoremap <expr> } (getline(".")[col(".")-1]) == '}' ? '<right>' : '}'
  inoremap <expr> ' (getline(".")[col(".")-1]) == "'" ? "<right>" : "'"
  inoremap <expr> " (getline(".")[col(".")-1]) == '"' ? '<right>' : '"'
  inoremap <expr>  IsPairClosed()
endfunction

" puts you in an environment to modify some splits settings
function! SplitEnvironment()
  if !exists("g:environment")
    let g:environment = "normal"
  endif

  if g:environment == "Normal"
    let g:environment = "Split Modification"
    nnoremap - <C-w>-
    nnoremap = <C-w>+
    nnoremap + <C-w>=
    nnoremap j <C-w>j
    nnoremap k <C-w>k
    nnoremap h <C-w>h
    nnoremap l <C-w>l
    nnoremap q :call SplitEnvironment()<CR>
  else
    let g:environment = "Normal"
    nnoremap - -
    nnoremap + +
    nnoremap j j
    nnoremap k k
    nnoremap h h
    nnoremap l l
    nnoremap q q
  endif

  echohl WarningMsg
  echom g:environment
  echohl none
endfunction

" StatusLine: {{{
function! StatusLine()
  function! DefaultStatusLine()
    set statusline=
    set statusline+=%#NormalColor#%{(g:currentmode[mode()]=='n')?'\ \ NORMAL\ ':''}
    set statusline+=%#InsertColor#%{(g:currentmode[mode()]=='i')?'\ \ INSERT\ ':''}
    set statusline+=%#ReplaceColor#%{(g:currentmode[mode()]=='r')?'\ \ REPLACE\ ':''}
    set statusline+=%#ReplaceColor#%{(g:currentmode[mode()]=='rv')?'\ \ V-REPLACE\ ':''}
    set statusline+=%#VisualColor#%{(g:currentmode[mode()]=='v')?'\ \ VISUAL\ ':''}
    set statusline+=%#VisualColor#%{(g:currentmode[mode()]=='vl')?'\ \ V-LINE\ ':''}
    set statusline+=%#VisualColor#%{(g:currentmode[mode()]=='vb')?'\ \ V-BLOCK\ ':''}
    set statusline+=%#CommandColor#%{(g:currentmode[mode()]=='c')?'\ \ COMMAND\ ':''}
    set statusline+=%#NormalColor#%{(g:currentmode[mode()]=='f')?'\ \ FINDER\ ':''}
    set statusline+=%#DefaultColor#%{!(g:currentmode[mode()])?'\ ':'\ '}
    set statusline+=%1*\[%n]                               "buffer number
    set statusline+=%2*\ %<%F\                             "File+path
    set statusline+=%3*\ %m                                "modified?
    set statusline+=%4*\ %y\                               "FileType
  endfunction
  let splits_num = len(tabpagebuflist())
  if splits_num > 1
    call DefaultStatusLine()
    set statusline-=%5*\ %=\ %{''.(&fenc!=''?&fenc:&enc).''}   "Encoding
    set statusline-=%5*\ %{(&bomb?\",BOM\":\"\")}          "Encoding2
    set statusline-=%6*\ %{&ff}\                           "FileFormat (dos/unix..) 
    set statusline-=%7*\ %{&spelllang}\ %{&hls?'H':''}\    "Spellanguage & Highlight on?
    set statusline-=%8*\ line:%l/%L\ (%02p%%)\         "currentline/total (%)
    set statusline-=%9*\ col:%02c\ \ \                     "Column number
    set statusline+=%8*\ %=\ %l/%L\ (%02p%%)\         "currentline/total (%)
  else
    call DefaultStatusLine()
    set statusline-=%8*\ %=\ %l/%L\ (%02p%%)\         "currentline/total (%)
    set statusline+=%5*\ %=\ %{''.(&fenc!=''?&fenc:&enc).''}   "Encoding
    set statusline+=%5*\ %{(&bomb?\",BOM\":\"\")}          "Encoding2
    set statusline+=%6*\ %{&ff}\                           "FileFormat (dos/unix..) 
    set statusline+=%7*\ %{&spelllang}\ %{&hls?'H':''}\    "Spellanguage & Highlight on?
    set statusline+=%8*\ line:%l/%L\ (%02p%%)\         "currentline/total (%)
    set statusline+=%9*\ col:%02c\ \ \                     "Column number
  endif
endfunction
" }}}
"===============================
" }}}

" ColorScheme: ======== {{{
"===============================
syntax on
" colorscheme default
hi Normal ctermbg=234

" the color column when exceeding 80 characters
call matchadd('ColorColumn', '\%80v', 100)
hi ColorColumn ctermbg=134 ctermfg=0
" line number
hi LineNr cterm=italic ctermfg=65
" special keys
hi SpecialKey ctermbg=NONE ctermfg=110
" vertical split line
hi VertSplit cterm=NONE ctermbg=0
" visual mode
hi Visual cterm=NONE ctermbg=150 ctermfg=16 gui=NONE

" indenting characters color
hi Conceal ctermfg=8 ctermbg=NONE

" folds
hi Folded ctermbg=0 ctermfg=65
hi FoldColumn ctermbg=none ctermfg=yellow

" cool italic comments
hi Comment cterm=Italic

" pop up menu for auto completion
hi Pmenu      cterm=NONE ctermbg=234   ctermfg=64
hi PmenuSel   cterm=bold ctermbg=0     ctermfg=green
hi PmenuSbar  cterm=bold ctermbg=0
hi PmenuThumb ctermbg=64

" tabline
hi TabLineFill cterm=NONE   ctermbg=0
hi TabLineSel  cterm=BOLD   ctermbg=NONE ctermfg=white
hi TabLine     cterm=Italic ctermbg=0    ctermfg=8

" status line
hi DefaultColor  ctermbg=0         ctermfg=white
hi NormalColor   ctermbg=234       ctermfg=255
hi InsertColor   ctermbg=darkgreen ctermfg=black
hi ReplaceColor  ctermbg=darkred   ctermfg=black
hi VisualColor   ctermbg=darkblue  ctermfg=black
hi CommandColor  ctermbg=yellow    ctermfg=black
hi User1         ctermbg=black     ctermfg=63
hi User2         ctermbg=black     ctermfg=64
hi User3         ctermbg=black     ctermfg=yellow
hi User4         ctermbg=black     ctermfg=203
hi User5         ctermbg=black     ctermfg=8
hi User6         ctermbg=black     ctermfg=8
hi User7         ctermbg=black     ctermfg=8
hi User8         ctermbg=black     ctermfg=white
hi User9         ctermbg=black     ctermfg=white
"===========================ctermbg=black ====
" }}}

" Mappings: =========== {{{
"-----------------------------
" General:  {{{

" smooth scrolling
nnoremap <silent> <C-U> :call SmoothScroll(1)<Enter>
nnoremap <silent> <C-D> :call SmoothScroll(0)<Enter>
inoremap <silent> <C-U> <Esc>:call SmoothScroll(1)<Enter>i
inoremap <silent> <C-D> <Esc>:call SmoothScroll(0)<Enter>i

" makes it easier to find the cursor when n or N
nnoremap <silent> n n:call HLNext(0.1)<CR>
nnoremap <silent> N N:call HLNext(0.1)<CR>

" moving text up and down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
inoremap <C-j> <esc>:m .+1<CR>==a
inoremap <C-k> <esc>:m .-2<CR>==a
nnoremap <leader>j :m .+1<CR>==
nnoremap <leader>k :m .-2<CR>==

" remove highlighting after search
nnoremap <silent> ,, :nohl<CR>
" source current file
nnoremap <Leader>s :so %<CR>

" regex completion instead of whole word completion
nnoremap <Leader><leader>f :find *

" inserting empty lines
nnoremap <Leader>o mxo<ESC>k`x
nnoremap <Leader>O mxO<ESC>j`x

" saving a document
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>Q :q!<CR>

" changing between splits made easier
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" changing between tabs made easier
nnoremap <silent> <Tab> :tabnext<CR>
nnoremap <silent> <S-Tab> :tabprevious<CR>
nnoremap <Leader>tn :tabnew 
nnoremap <Leader>te :tabnew<CR>
nnoremap <Leader>tt :tabs<CR>:tab 
nnoremap <Leader>tf :tabe %<CR>
" open help docs in new tab
nnoremap <Leader>th :tab help 

" changing between buffers made easier
nnoremap <silent> <Leader>bn :bn<CR>
nnoremap <silent> <Leader>bp :bp<CR>
nnoremap <silent> <Leader>bl :buffers<CR>
nnoremap <Leader>bt :buffers<CR>:buffer 

" navigating between folds made easier
nnoremap <silent> ]z :call GoToFold("next", "closed")<CR>
nnoremap <silent> [z :call GoToFold("prev", "closed")<CR>
nnoremap <silent> ]Z :call GoToFold("next", "opened")<CR>
nnoremap <silent> [Z :call GoToFold("prev", "opened")<CR>

" toggling folds
nnoremap <Leader>f za
nnoremap <Leader>F zA

" copying and pasting in native vim :O
vnoremap <Leader>y y:!xsel -b <<< '<C-r>"'<CR><CR>:echo 'copied to clipboard'<CR>
nnoremap <Leader>Y ggVG<Leader>y
nnoremap <Leader>p :read !xsel -b<CR>
vnoremap <Leader>p "_dP

" delete the content of a line
nnoremap <Leader>d S<ESC>

" commenting lines
nnoremap <silent> <Leader>/ :call ToggleComment()<CR>
vnoremap <silent> <Leader>/ :call ToggleComment()<CR>

" auto completion with tab
inoremap <expr> <tab> TabCompletion()

" changing the size of splits
nnoremap <Leader>M :call SplitEnvironment()<CR>

" AutoCompletion: {{{
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
      \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
      \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
" open omni completion menu closing previous if open and opening new menu without changing the text
inoremap <expr> <C-Space> (pumvisible() ? (col('.') > 1 ? '<Esc>i<Right>' : '<Esc>i') : '') .
      \ '<C-x><C-o><C-r>=pumvisible() ? "\<lt>C-n>\<lt>C-p>\<lt>Down>" : ""<CR>'
" open user completion menu closing previous if open and opening new menu without changing the text
inoremap <expr> <S-Space> (pumvisible() ? (col('.') > 1 ? '<Esc>i<Right>' : '<Esc>i') : '') .
      \ '<C-x><C-u><C-r>=pumvisible() ? "\<lt>C-n>\<lt>C-p>\<lt>Down>" : ""<CR>'
" }}}

" }}}
"-----------------------------
" Plugins: {{{
nnoremap <Leader>G :Goyo<CR>
" }}}
"-----------------------------
" FileExplorer: {{{
" NETRW built-in filemangaer
function! NetrwMapping()
" navigation
  nmap <buffer> <C-h> gh
  nmap <buffer> H u
  nmap <buffer> h -^
  nmap <buffer> l <CR>
  nmap <buffer> . gh
  nmap <buffer> P <C-w>z
  nmap <buffer> L <CR>:Lexplore<CR>
  nmap <buffer> <Leader>dd :Lexplore<CR>
  nmap <buffer> ml :echo join(netrw#Expose("netrwmarkfilelist"), "\n")<CR>
  nmap <buffer> <C-l> <C-w>l
" files
  nmap <buffer> ff %:w<CR>:buffer #<CR>
  nmap <buffer> fe R
  nmap <buffer> fc mc
  nmap <buffer> fC mtmc
  nmap <buffer> fx mm
  nmap <buffer> fX mtmm
  nmap <buffer> f; mx
" bookmarks
  nmap <buffer> bb mb
  nmap <buffer> bd mB
  nmap <buffer> bl gb
endfunction

nnoremap <silent> <Leader>e :Lexplore<CR>       " current pwd
nnoremap <silent> <Leader>E :Lexplore %:p:h<CR> " current file dir
" }}}
"-----------------------------
" Snippets: ----------- {{{
autocmd FileType tex,html,markdown nnoremap <Leader><Leader> /<++><CR>"_c4l
autocmd FileType tex,html,markdown inoremap ;; <ESC>/<++><CR>"_c4l

" LaTeX: {{{
autocmd FileType tex call SetLaTeXMaps()
function! SetLaTeXMaps()
  inoremap ;1 \section{}<CR><++><ESC>kf{a
  inoremap ;2 \subsection{}<CR><++><ESC>kf{a
  inoremap ;3 \subsubsection{}<CR><++><ESC>kf{a
  inoremap ;i \textit{} <++><ESC>F{a
  inoremap ;b \textbf{} <++><ESC>F{a
  inoremap ;e \emph{} <++><ESC>F{a
endfunction
" }}}
"-----------------------------

" HTML: {{{
autocmd FileType html call SetHtmlMaps()
function! SetHtmlMaps()
  inoremap ;! <ESC>:read ~/.vim/templates/html<CR>gg/<title><CR>f>a
  inoremap ;1 <h1></h1><CR><++><ESC>k/<h1><CR>f>a
  inoremap ;2 <h2></h2><CR><++><ESC>k/<h2><CR>f>a
  inoremap ;3 <h3></h3><CR><++><ESC>k/<h3><CR>f>a
  inoremap ;4 <h4></h4><CR><++><ESC>k/<h4><CR>f>a
  inoremap ;5 <h5></h5><CR><++><ESC>k/<h5><CR>f>a
  inoremap ;i <i></i> <++><ESC>2F>a
  inoremap ;b <b></b> <++><ESC>2F>a
  inoremap ;p <p></p><CR><++><ESC>k/<p><CR>f>a
  inoremap ;s <script></script><CR><++><ESC>k/<script><CR>f>a
  inoremap ;S <script src=""></script><CR><++><ESC>k/<script src<CR>f"a
  inoremap ;c <link rel="stylesheet" href=""/><ESC>F"i
  inoremap ;I <input></input><CR><++><ESC>k/<input><CR>f>a
  inoremap ;B <button></button><CR><++><ESC>k/<button><CR>f>a
endfunction
" }}}

" MarkDown: {{{
autocmd FileType markdown call SetMdMaps()
function! SetMdMaps()
  inoremap ;1 #<CR><++><ESC>k0A
  inoremap ;2 ##<CR><++><ESC>k0A
  inoremap ;3 ###<CR><++><ESC>k0A
  inoremap ;i ** <++><ESC>F*i
  inoremap ;b **** <++><ESC>2F*i
endfunction
" }}}

"===============================
" }}}
"-----------------------------
"===============================
" }}}

" AutoCmd: ============ {{{
" making marks for easier movment
"autocmd BufWinEnter ~/.vimrc call SetVimrcMarkers()
" indenting lines
autocmd VimEnter,BufNew,BufNewFile,BufWinEnter * call IndentLines()
" status line
autocmd VimEnter,BufWinEnter,BufWinLeave,BufHidden,BufRead * call StatusLine()
autocmd VimEnter * call AutoPairs()

" Commenting blocks of code.
augroup commenting_blocks_of_code
  autocmd!
  autocmd FileType c,cpp,java,scala let b:comment_leader = '//'
  autocmd FileType javascript       let b:comment_leader = '//'
  autocmd FileType sh,ruby,python   let b:comment_leader = '#'
  autocmd FileType conf,fstab       let b:comment_leader = '#'
  autocmd FileType tex              let b:comment_leader = '%'
  autocmd FileType mail             let b:comment_leader = '>'
  autocmd FileType vim              let b:comment_leader = '"'
augroup END
" }}}

" FileExplorer: ======= {{{
"===============================

let g:netrw_banner=0                            " disble banner 
let g:netrw_browse_split=4                      " open in prior window
let g:netrw_altv=1                              " splits right
let g:netrw_liststyle=0                         " display style
let g:netrw_keepdir = 0
let g:netrw_list_hide = '\(^\|\s\s\)\zs\.\S\+'  " hide dotfiles on open
let g:netrw_winsize = 20                        " size of split
let g:netrw_localcopydircmd = 'cp -r'           " copy recursively

" highlight marked files
hi! link netrwMarkFile Search

augroup netrw_mapping
  autocmd!
  autocmd filetype netrw call NetrwMapping()
augroup END

"===============================
" }}}

" 2021
