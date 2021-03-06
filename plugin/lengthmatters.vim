" Prevent from loading multiple times.
if exists('g:loaded_lengthmatters') | finish | endif


" A couple of helper funcs to set the default value of an int/string variable.
function! s:DefaultInt(name, value)
  if exists('g:lengthmatters_' . a:name) | return | endif
  exec 'let g:lengthmatters_' . a:name . ' = ' . a:value
endfunction
function! s:DefaultStr(name, value)
  if exists('g:lengthmatters_' . a:name) | return | endif
  exec 'let g:lengthmatters_' . a:name . ' = ' . string(a:value)
endfunction

" Set some defaults.
call s:DefaultInt('on_by_default', 1)
call s:DefaultInt('use_textwidth', 1)
call s:DefaultInt('start_at_column', 81)
call s:DefaultStr('match_name', 'OverLength')
call s:DefaultStr('colors', 'ctermbg=lightgray guibg=gray')
if (!exists('g:lengthmatters_excluded'))
  let g:lengthmatters_excluded = ['unite', 'tagbar', 'startify',
        \ 'gundo', 'vimshell', 'w3m', 'nerdtree']
endif



" Enable the highlighting (if the filetype is not an excluded ft). Reuse the
" match of the current window if available, unless the textwidth has changed. If
" it has, force a reload by disabling the highlighting and re-enabling it.
function! s:Enable()
  " Do nothing if this is an excluded filetype.
  if index(g:lengthmatters_excluded, &ft) >= 0 | return | endif

  if s:ShouldUseTw() && s:TwChanged()
    call s:Disable()
    let w:lengthmatters_tw = &tw
  endif

  let w:lengthmatters_active = 1
  call s:Highlight()

  " Create a new match if it doesn't exist already (in order to avoid creating
  " multiple matches for the same window).
  if !exists('w:lengthmatters_match')
    let l:column = s:ShouldUseTw() ? &tw + 1 : g:lengthmatters_start_at_column
    let l:regex = '\%' . l:column . 'v.\+'
    let w:lengthmatters_match = matchadd(g:lengthmatters_match_name, l:regex)
  endif
endfunction


" Force the disabling of the highlighting and delete the match of the current
" window, if available.
function! s:Disable()
  let w:lengthmatters_active = 0

  if exists('w:lengthmatters_match')
    call matchdelete(w:lengthmatters_match)
    unlet w:lengthmatters_match
  endif
endfunction


" Toggle between active and inactive states.
function! s:Toggle()
  if !exists('w:lengthmatters_active') || !w:lengthmatters_active
    call s:Enable()
  else
    call s:Disable()
 endif
endfunction


" Return true if the textwidth should be used for creating the hl match.
function s:ShouldUseTw()
  return g:lengthmatters_use_textwidth && &tw > 0
endfunction


" Execute the highlight command.
function! s:Highlight()
  exec 'highlight ' g:lengthmatters_match_name . ' ' . g:lengthmatters_colors
endfunction


" Return true if the textwidth has changed since the last time this plugin saw
" it. We're assuming that no recorder tw means it changed.
function! s:TwChanged()
  return !exists('w:lengthmatters_tw') || &tw != w:lengthmatters_tw
endfunction


" This function gets called on every autocmd trigger (defined later in this
" script). It disables the highlighting on the excluded filetypes and enables it
" if it wasn't enabled/disabled before or if there's a new textwidth.
function! s:AutocmdTrigger()
  if index(g:lengthmatters_excluded, &ft) >= 0
    call s:Disable()
  elseif !exists('w:lengthmatters_active') && g:lengthmatters_on_by_default
        \ || (s:ShouldUseTw() && s:TwChanged())
    call s:Enable()
  endif
endfunction



augroup lengthmatters
  autocmd!
  " Enable (if it's the case) on a bunch of events (the filetype event is there
  " so that we can avoid highlighting excluded filetypes.
  autocmd WinEnter,BufEnter,BufRead,FileType * call s:AutocmdTrigger()
  " Re-highlight the match on every colorscheme change (includes bg changes).
  autocmd ColorScheme * call s:Highlight()
augroup END



" Define the a bunch of commands (which map one to one with the functions
" defined before).
command! LengthmattersEnable call s:Enable()
command! LengthmattersDisable call s:Disable()
command! LengthmattersToggle call s:Toggle()
command! LengthmattersReload call s:Disable() | call s:Enable()
command! LengthmattersEnableAll windo call s:Enable()
command! LengthmattersDisableAll windo call s:Disable()



" The plugin has been loaded.
let g:loaded_lengthmatters = 1
