"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim autoload file
"
" Maintainer: leaf <leafvocation@gmail.com>
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Config {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetConfig(name, default)
  return exists(a:name) ? eval(a:name) : a:default
endfunction

let s:snippets_path = 
      \s:GetConfig('g:vim_imagine_snippets_path', 'plugin/imagine_snippets.vim')

let s:fuzzy_chain = s:GetConfig('g:vim_imagine_fuzzy_chain',  
      \[
      \  'capital', 
      \  'hyphen', 
      \  'dot', 
      \  'underscore', 
      \  'include',
      \])

let s:fuzzy_custom_methods = 
      \ s:GetConfig('g:vim_imagine_fuzzy_custom_methods', {})

let g:vim_imagine_fuzzy_favoured_words = 
      \ s:GetConfig('g:vim_imagine_fuzzy_favoured_words', [])

let s:loaded_emmet_vim = exists('g:loaded_emmet_vim') 
      \&& g:loaded_emmet_vim

let b:vim_imagine_use_emmet = s:GetConfig('b:vim_imagine_use_emmet', 0)
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Variables {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:name = 'vim-imagine'
let s:leading_char_regexp = '\v[0-9A-Za-z$_\-{(<>`]'
let s:chars_regexp = '\v[0-9A-Za-z$_\-\\]'

" Space and comma are added by default
let s:splits = '(,),{,},<,>,[,],=,:,'',",;,/,\,+,!,#,*,`,|,.' 
let s:snippets_path_example = 'setting/example_snippets.vim'
let s:fuzzy_methods = {}
let s:fuzzy_method = ''
" Avoid overuse of memory
let s:fuzzy_chars_max_length = 15
let s:type = ''
let s:filetype = ''
let s:snippet_result = ''
let s:emmet_special_line_regexp = '\v(\=\>)|(\>,)|(\})'
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Functions {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! imagine#TabRemap(...) abort
  call s:SetType('')
  call s:LogMsg('-------- Start ----------')

  " Only works when <tab> mapping is not prefixed with `<c-g>u`
  if pumvisible() && exists("*SuperTab")
    call s:LogMsg('SuperTab popup menu is visible')
    return SuperTab('n')
  endif

  if a:0 > 0
    " Read test arguments
    let line = a:1
    let column = a:2
    let lines = a:3
  else
    " Read user context
    let line = getline('.')
    let column = col('.')
  endif

  let chars = s:GetChars(line, column)

  echohl Identifier
  call s:LogMsg('chars: '.chars)
  echohl None

  let result = []

  " Return <tab> if the cursor is at col 1 or behind spaces
  unlet result
  let result = s:TryTab(chars, column)
  if result isnot 0
    return result
  endif
    
  " Try custom snippet
  unlet result
  let result = s:TrySnippet(chars, column)
  if result isnot 0
    return result
  endif

  " Try emmet match
  if s:loaded_emmet_vim
    unlet result
    let result = s:TryEmmet(chars, line)
    if result isnot 0
      return result
    endif
  endif

  " Try fuzzy match
  if a:0 < 1
    let lines = getline(1, '$')
  endif
  unlet result
  let result = s:TryFuzzy(chars, column, lines)
  if result isnot 0
    return result
  endif

  " SuperTab match
  unlet result
  let result = s:SuperTabMatch()
  if count([0], result) == 0
    return result
  endif

  call s:LogMsg('-------- Not matched ----------')
  return ''
endfunc

" Move cursor for snippet match
function! imagine#Move()
  if s:type == 'Snippet' && count(s:snippet_result, '|')
    call search('|', 'b', line("w0"))
    return "\<del>"
  else
    return ''
  endif
endfunction

function! imagine#ToggleEmmet() abort
  call s:InitUseEmmetVariable()
  let b:vim_imagine_use_emmet = 1 - b:vim_imagine_use_emmet
  if b:vim_imagine_use_emmet == 1
    echom '['.s:name.'] Use emmet'
  else
    echom '['.s:name.'] Not use emmet'
  endif
endfunction

" Add chars under cursor to favoured words
function! imagine#AddFavouredWord() abort
  let word = expand('<cwrod>')
  if count(g:vim_imagine_fuzzy_favoured_words, word) == 0
    call add(g:vim_imagine_fuzzy_favoured_words, word)
  endif

  echo '['.s:name.'] Fuzzy favoured words: '
        \.join(g:vim_imagine_fuzzy_favoured_words, ', ')
endfunction

function! imagine#Undo()
  undo
  return ''
endfunction

" Get the chars to complete
function! s:GetChars(line, column) abort
  let line = a:line
  let end = a:column - 2
  let start = end - 1

  if line[end] !~ s:leading_char_regexp
    return ''
  endif

  while line[start] =~ s:chars_regexp
    let start -= 1
  endwhile

  let chars = line[start + 1 : end]
  return chars
endfunction

" Set match type
function! s:SetType(type) abort
  if a:type != ''
    call s:LogMsg('Type: '.a:type)
    if a:type == 'Fuzzy'
      call s:LogMsg('-------- End with '.a:type.', '.s:fuzzy_method.' ----------')
    else
      call s:LogMsg('-------- End with '.a:type.' ----------')
    endif
  endif

  let s:type = a:type
endfunction

function! s:TryTab(chars, column) abort
  if a:chars == '' ||  a:chars =~ '\v\s+' || a:column == 1 
    call s:SetType('Tab')
    return "\<tab>"
  endif
endfunction

function! s:TryFavoured(chars) abort
  if len(g:vim_imagine_fuzzy_favoured_words) > 0
    let chars = a:chars
    let regexp = escape(chars, '()@$')
    let regexp = join(split(regexp, '\zs'), '[a-zA-Z-_]*')
    let regexp = '\v^'.regexp

    let words = copy(g:vim_imagine_fuzzy_favoured_words)
    let result = filter(words, 'v:val =~ '''.regexp.'''')
    let result = sort(result, "s:LengthDecrement")
    let result = s:RemoveDumplicate(result, chars)

    call s:LogMsg('Method: Favour')
    call s:LogMsg('Regexp: '.regexp)
    let s:fuzzy_method = 'Favour'
    return result
  else
    return []
  endif
endfunction

function! s:TrySnippet(chars, column) abort
  " Reload setting if filetype is changed
  if &filetype !=? s:filetype
    let s:filetype = &filetype
    call s:LogMsg('Filetype changed, reload '.s:snippets_path)
    let g:vim_imagine_dict = 0
    execute 'runtime '.s:snippets_path

    if g:vim_imagine_dict is 0
      call s:LogMsg('Load setting in '.s:snippets_path_example, 'warning')
      call s:LogMsg('Please save '.s:snippets_path_example.' as '.s:snippets_path
            \.', then add custom snippets in it', 'warning')
      execute 'runtime '.s:snippets_path_example
    endif
  endif

  let dict = exists("g:vim_imagine_test_dict")
        \ ? g:vim_imagine_test_dict
        \ : g:vim_imagine_dict
  let dict_1 = g:vim_imagine_dict_1
  let dict_2 = g:vim_imagine_dict_2

  let length = len(a:chars)
  let default = ''
  let result = get(dict, a:chars, default)
  if result == default
    let result = get(dict_1, a:chars[-1:-1], default)
    if result != default
      let length = 1
    elseif length > 1
      let result = get(dict_2, a:chars[-2:-1], default)
      if result != default
        let length = 2
      endif
    endif
  endif

  if result != default
    call s:SetType('Snippet')
    let s:snippet_result = result
    if mode() == 'i'
      let deletes = "\<bs>"
      while length > 1
        let deletes = deletes."\<bs>"
        let length = length - 1
      endwhile

      return deletes.result
    else
      call s:LogMsg('Return: '.result)
      return result
    endif
  else
    let s:snippet_result = ''
  endif
endfunction

function! s:TryFuzzy(chars, column, lines) abort
  let length = len(a:chars)

  if (length > 1 && length < s:fuzzy_chars_max_length)
    let result = TryFuzzyChain(a:chars, a:lines)

    if !s:InvalidRet(result, a:chars)
      let result_word = result[0]
      call s:SetType('Fuzzy')
      if mode() == 'i'
        call complete(a:column - length, [result_word])
        return ''
      else
        call s:LogMsg('Return: '.result_word)
        return result_word
      endif
    endif
  endif
endfunction

function! s:InvalidRet(result, chars) abort
  return a:result == [] || a:result == [a:chars]
endfunction

function! s:CleanRet(result, chars) abort
  let result = map(a:result, "s:RemoveLeaderSpaces(".'v:val'.")")

  if result == [a:chars]
    return []
  else
    return result
  endif
endfunction

function! s:RemoveLeaderSpaces(val) abort
  return substitute(a:val, '\v^\s+', '', '')
endfunction

function! TryFuzzyChain(chars, lines) abort
  let chars = escape(a:chars, '()@$')

  let s:fuzzy_method = ''
  call s:LogMsg('Try fuzzy')
  call s:LogMsg('Fuzzy chain: '.join(s:fuzzy_chain, ', '))

  let result = s:TryFavoured(chars)
  for method in s:fuzzy_chain
    if s:InvalidRet(result, chars)
      let result = s:CallFuzzyMethod(method, chars, a:lines)
    endif
  endfor

  let result = s:CleanRet(result, chars)
  return result
endfunction

function! s:CallFuzzyMethod(method, chars, lines) abort
  let method = a:method

  " Get fuzzy_methods
  if has_key(s:fuzzy_methods, method)
    let fuzzy_methods = s:fuzzy_methods
  elseif has_key(s:fuzzy_custom_methods, method)
    let fuzzy_methods = s:fuzzy_custom_methods
  else
    call s:LogMsg('Warning: '
          \.'chain method '.method.' was not found', 'warning')
    return []
  endif

  " Get regexp
  let regexp = fuzzy_methods[method](a:chars)
  if regexp == ''
    call s:LogMsg('Method: '.method, 'warning')
    call s:LogMsg('Regexp: no regexp is returned', 'warning')
    return []
  endif

  " Get splits
  if has_key(fuzzy_methods, method.'_splits')
    let splits = fuzzy_methods[method.'_splits'](s:splits)
    let splits_regexp = s:GetSplitsRegExp(splits)
  else
    let splits_regexp = s:GetSplitsRegExp(s:splits)
  endif

  " Get match words
  let result = []
  for l in a:lines
    let words = split(l, splits_regexp)
    let matchs = filter(words, 'v:val =~ '''.regexp.'''')
    let result = result + matchs
  endfor

  " Log
  call s:LogMsg('Method: '.method)
  call s:LogMsg('Regexp: '.regexp)
  let s:fuzzy_method = method

  " Return
  let result = sort(result, "s:LengthDecrement")
  let result = s:RemoveDumplicate(result, a:chars)
  return result
endfunction

function! s:GetSplitsRegExp(splits)
  let splits = substitute(a:splits, ',\+', ',', 'g')
  " Escape every char
  let escaped_splits = substitute(splits, '\([^,]\)', '\\\1', 'g')
  let splits_regexp = '\v(\s|,|' . join(split(escaped_splits, ','), '|') . ')'
  return splits_regexp
endfunction

function! s:fuzzy_methods.hyphen(chars)
  let regexp = join(split(a:chars, '\zs'), '[^-]*-')
  let regexp = '\v^(\@|\$)?'.regexp.'\w*>'
  return regexp
endfunction

function! s:fuzzy_methods.capital(chars)
  let regexp = substitute(a:chars, '\v.\zs\w+', '\U\0', 'g')
  let regexp = join(split(regexp, '\zs'), '\l*')
  let regexp = '['.regexp[0].toupper(regexp[0]).']'.
        \ regexp[1:]
  let regexp = '\v\C^(\@|\$)?'.regexp.'\l*>'
  return regexp
endfunction

function! s:fuzzy_methods.dot(chars)
  let regexp = join(split(a:chars, '\zs'), '[^.]*\.')
  let regexp = '\v^(\@|\$)?'.regexp.'[^.]*>'
  return regexp
endfunction

function! s:fuzzy_methods.dot_splits(splits)
  return substitute(a:splits, '\.' , '', 'g')
endfunction

function! s:fuzzy_methods.underscore(chars)
  let regexp = join(split(a:chars, '\zs'), '[^_]*_')
  let regexp = '\v^(\@|\$)?'.regexp.'[^_]*>'
  return regexp
endfunction

function! s:fuzzy_methods.include(chars)
  let regexp = join(split(a:chars, '\zs'), '.*')
  let regexp = '\v<.*'.regexp.'.*>'
  return regexp
endfunction

function! s:SuperTabMatch() abort
  if exists("*SuperTab")
    call s:SetType('SuperTab')
    return SuperTab('n')
  endif
endfunction

function! s:LengthDecrement(i1, i2) abort
  return len(a:i2) - len(a:i1)
endfunction

function! s:LengthIncrement(i1, i2) abort
  return len(a:i1) - len(a:i2)
endfunction

function! s:LogMsg(msg, ...) abort
  if exists("g:vim_imagine_debug")
        \ && g:vim_imagine_debug == 1
    if type(a:msg) == 3 "List
      echom '['.s:name.'] '. join(a:msg, ', ')
    else
      if a:0 == 1 && a:1 == 'warning'
        echohl WarningMsg
        echom '['.s:name.'] '. a:msg[0:100]
        echohl None
      else
        echom '['.s:name.'] '. a:msg[0:100]
      endif
    endif
  endif
endfunction

function! s:RemoveDumplicate(list, exclude_word) abort
  let old_list = a:list
  let new_list = []
  let i = 0

  for item in old_list
    if (i == 0 || count(new_list, item) == 0) && item != a:exclude_word
      call add(new_list, item)
      let i += 1
    endif
  endfor

  return new_list
endfunction

function! s:InitUseEmmetVariable()
  let b:vim_imagine_use_emmet = exists('b:vim_imagine_use_emmet') 
        \ ? b:vim_imagine_use_emmet
        \ : 0
endfunction

" Try emmet match
function! s:TryEmmet(chars, line) abort
  call s:InitUseEmmetVariable()
  let length = len(a:chars)

  " Enable when length is 1 or b:vim_imagine_use_emmet is 1
  let enable = length == 1 
        \|| b:vim_imagine_use_emmet == 1

  if enable
    call s:SetType('Emmet')

    " emmet#expandAbbr(mode, abbr) range abort
    " ...
    " if a:mode ==# 1
    "   let part = matchstr(line, '\([a-zA-Z0-9:_\-\@|]\+\)$')
    " else
    "   let part = matchstr(line, '\(\S.*\)$')
    " ...
    if a:line =~ s:emmet_special_line_regexp
      return emmet#expandAbbr(1, '')
    else
      return emmet#expandAbbr(0, '')
    endif 
  endif
endfunction

"vim: fdm=marker 
