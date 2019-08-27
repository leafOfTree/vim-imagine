if !exists('g:imagine_prior_words')
  let g:imagine_prior_words = []
else
  let g:imagine_prior_words = g:imagine_prior_words
endif

let s:fuzzy_dict = {}
let s:name = 'vim-imagine'
let s:max_length = 15
let s:action_dict = {'h': "\<left>", 'r': "\<cr>"}
let s:splits = '\v(\s|\(|\)|\{|\}|\=|\:|\''|\"|,|;|\<|\>|\[|\]|\/|\\|\+|\!|#|*|`|\.)'
let s:filetype = ''
let s:loaded_emmet_vim = exists('g:loaded_emmet_vim') 
      \&& g:loaded_emmet_vim

function! imagine#TabRemap(...) abort
  set undolevels=1000

  call s:LogType('')

  " Call SuperTab if the completion list is visible
  if pumvisible()
    call s:LogType('SuperTab Visible')
    return SuperTab('n')
  endif

  if a:0 > 0
    " Set test context
    " Order: line, column, lines
    let line = a:1
    let column = a:2
    let lines = a:3
  else
    " Read user context
    let line = getline('.')
    let column = col('.')
    let lines = getline(1, '$')
  endif
  let word = s:GetWord(line, column)
  let ret = []

  call s:LogMsg('word: '.word)

  " Return <tab> if is in column 1 or behind spaces
  unlet ret
  let ret = s:TabMatch(word, column)
  if count([0], ret) == 0
    return ret
  endif

  " custom Direct match
  unlet ret
  let ret = s:DirectMatch(word, column)
  if count([0], ret) == 0
    return ret
  endif

  " emmet match
  if s:loaded_emmet_vim
    unlet ret
    let ret = imagine_emmet#EmmetMatch(word, line)
    if count([0], ret) == 0
      return ret
    endif
  endif

  " fuzzy match
  unlet ret
  let ret = s:FuzzyMatch(word, column, lines)
  if count([0], ret) == 0
    return ret
  endif

  " SuperTab match
  unlet ret
  let ret = s:SuperTabMatch()
  if count([0], ret) == 0
    return ret
  endif

  return ''
endfunc

" Add word under cursor to prior words
function! imagine#AddPriorWords() abort
  normal! viw"zy
  let word = @z
  if count(g:imagine_prior_words, word) == 0
    call add(g:imagine_prior_words, word)
  endif

  echo '['.s:name.'] Prior words: '
  echo g:imagine_prior_words
endfunction

" Get the word to complete
function! s:GetWord(line, column) abort
  let line = a:line
  let end = a:column - 2
  let start = end - 1

  let match = '\v[0-9A-Za-z\-\$_]'

  while line[start] =~ match
    let start -= 1
  endwhile

  let word = line[start+1 : end]
  return word
endfunction

" Set complete type
function! s:LogType(type) abort
  if a:type != ''
    call s:LogMsg('Type: '.a:type)
  endif
endfunction

function! s:TabMatch(word, column) abort
  let column = a:column
  let word = a:word

  if column == 1 || word == '' || word =~ '\v\s+'
    call s:LogType('Tab')
    return "\<tab>"
  endif
endfunction

function! s:PriorMatch(word) abort
  let word = a:word
  let regexp = escape(word, '()@$')
  let regexp = join(split(regexp, '\zs'), '[a-zA-Z-_]*')
  let regexp = '\v^'.regexp

  let words = copy(g:imagine_prior_words)
  let ret = filter(words, 'v:val =~ '''.regexp.'''')
  let ret = sort(ret, "s:LengthDecrement")
  let ret = s:RemoveDumplicateElem(ret, word)

  call s:LogMsg('== Prior')
  call s:LogMsg('== '.regexp)
  return ret
endfunction

" Function: Compare input word with g:dict/g:dict_end/g:dict_end2
" defined in config/imagine.vim
function! s:DirectMatch(word, column) abort
  " Load config when filetype is changed
  if &filetype !=? s:filetype
    let s:filetype = &filetype
    runtime config/imagine.vim
  endif

  let column = a:column
  let word = a:word
  let length = len(word)

  if !exists("g:vim_imagine_dict_end")
    call s:LogMsg('Please save config/example.vim to config/imagine.vim, add custome configs in it later', 'warning')
    call s:LogMsg('Load config in config/example.vim', 'warning')
    runtime config/example.vim
  endif
  let dict = g:vim_imagine_dict
  let dict_end = g:vim_imagine_dict_end
  let dict_end2 = g:vim_imagine_dict_end2
  if exists("g:vim_imagine_test_dict")
    let dict = g:vim_imagine_test_dict
  endif

  let res = get(dict, word, [])
  if res == []
    let res = get(dict_end, word[-1:-1], [])
    if res != []
      let length = 1
    elseif length > 1
      let res = get(dict_end2, word[-2:-1], [])
      if res != []
        let length = 2
      endif
    endif
  endif

  if res != []
    call s:LogType('Direct')
    let [new_word, flag] = res
    if flag == '$'
      " For '$', return new_word as it is
      return new_word
    else
      " Else, complete the word with new_word
      if mode() == 'i'
        call complete(column - length, [new_word])
        return s:MoveAfterDirectComplete(flag)
      else
        call s:LogMsg('Return: '.new_word)
        return new_word
      endif
    endif
  endif
endfunction

function! s:FuzzyMatch(word, column, lines) abort
  let column = a:column
  let word = a:word
  let length = len(word)

  if (length > 1 && length < s:max_length)
    let ret = FuzzyMatchChain(word, a:lines)

    if !s:InvalidRet(ret, word)
      call s:LogType('Fuzzy')
      if mode() == 'i'
        call complete(column - length, [ret[0]])
        return ''
      else
        call s:LogMsg('Return: '.ret[0])
        return ret[0]
      endif
    endif
  endif
endfunction

function! s:InvalidRet(ret, word) abort
  return a:ret == [] || a:ret == [a:word]
endfunction

function! s:CleanRet(ret, word) abort
  let ret = a:ret
  let word = a:word

  function! RemoveLeaderSpaces(val) abort
    return substitute(a:val, '\v^\s*', '', 'g')
  endfunction
  let ret = map(ret, "RemoveLeaderSpaces(".'v:val'.")")

  if ret == [word]
    call remove(ret, 0)
  endif
  return ret
endfunction

function! FuzzyMatchChain(word, lines) abort
  call s:LogMsg('In Fuzzy')
  let word = a:word
  let lines = a:lines
  let ret = []

  let matchchain = g:vim_imagine_matchchain
  call s:LogMsg(matchchain)
  let ret = s:PriorMatch(word)
  for method in matchchain
    if s:InvalidRet(ret, word)
      let ret = s:FuzzyMatchMethod(method, word, lines)
    endif
  endfor

  let ret = s:CleanRet(ret, word)
  return ret
endfunction

function! s:FuzzyMatchMethod(method, word, lines) abort
  let lines = a:lines
  let method = a:method
  let ret = []
  let word = escape(a:word, '()@$')

  " Get fuzzy_dict
  if has_key(s:fuzzy_dict, method)
    let fuzzy_dict = s:fuzzy_dict
  elseif exists('g:vim_imagine_custom_fuzzy_dict') 
        \&& has_key(g:vim_imagine_custom_fuzzy_dict, method)
    let fuzzy_dict = g:vim_imagine_custom_fuzzy_dict
  else
    call s:LogMsg('Warning: '.method.' not found on fuzzy_dict'
          \, 'warning')
    return ret
  endif

  " Get regexp
  let regexp = fuzzy_dict[method](word)
  if regexp == ''
    call s:LogMsg('Method: '.method)
    call s:LogMsg('Result: no regexp returned')
    return ret
  endif

  " Get splits
  if has_key(fuzzy_dict, method.'_splits')
    let splits = fuzzy_dict[method.'_splits']()
  else
    let splits = s:splits
  endif

  " Get match words
  for l in lines
    let words = split(l, splits)
    let match_words =
          \ filter(words, 'v:val =~ '''.regexp.'''')
    let ret = ret + match_words
  endfor

  " Return
  let ret = sort(ret, "s:LengthDecrement")
  let ret = s:RemoveDumplicateElem(ret, word)
  call s:LogMsg('Method: '.method)
  call s:LogMsg('Regexp: '.regexp)
  return ret
endfunction

function! s:fuzzy_dict.hyphen(word)
  let regexp = join(split(a:word, '\zs'), '\w*(-)')
  let regexp = '\v^\@?'.regexp.'\w*>'
  return regexp
endfunction

function! s:fuzzy_dict.capital(word)
  let regexp = substitute(a:word, '\v.\zs\w*', '\U\0', 'g')
  let regexp = join(split(regexp, '\zs'), '\l*')
  let regexp = '['.regexp[0].toupper(regexp[0]).']'.
        \ regexp[1:]
  let regexp = '\v\C^'.regexp.'\l*>'
  return regexp
endfunction

function! s:fuzzy_dict.dot(word)
  let regexp = join(split(a:word, '\zs'), '[^.]*\.')
  let regexp = '\v^\@?'.regexp.'[^.]*>'
  return regexp
endfunction

function! s:fuzzy_dict.dot_splits()
  return '\v(\s|\(|\)|\{|\}|\=|\:|\''|\"|,|;|\<|\>|\[|\]|\/|\\|\+|\!|#|*|`)'
endfunction

function! s:fuzzy_dict.underscore(word)
  let regexp = join(split(a:word, '\zs'), '[^_]*_')
  let regexp = '\v^'.regexp.'[^_]*>'
  return regexp
endfunction

function! s:fuzzy_dict.chars(word)
  let regexp = join(split(a:word, '\zs'), '.*')
  let regexp = '\v<.*'.regexp.'.*>'
  return regexp
endfunction

function! s:SuperTabMatch() abort
  if exists("*SuperTab")
    call s:LogType('SuperTab')
    return SuperTab('n')
  endif
endfunction

function! s:MoveAfterDirectComplete(action) abort
  let action = a:action
  let ret = ''

  if action != '' && len(action) % 2 == 0
    let i = 0
    let l = len(action)

    while i < l
      let times = action[i+0]
      let action = action[i+1]

      for j in range(times)
        let ret = ret . s:action_dict[action]
      endfor
      let i += 2
    endwhile
  endif

  return ret
endfunc

function! s:LengthDecrement(i1, i2) abort
  return len(a:i2) - len(a:i1)
endfunction

function! s:LengthIncrement(i1, i2) abort
  return len(a:i1) - len(a:i2)
endfunction

function! s:LogMsg(msg, ...) abort
  if exists("g:vim_imagine_debug")
        \ && g:vim_imagine_debug == 1
    if type(a:msg) == 3
      for i in a:msg
        echom '== List item: '.i
      endfor
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


function! s:RemoveDumplicateElem(list, word) abort
  let old_list = a:list
  let new_list = []
  let i = 0

  for item in old_list
    if (i == 0 || count(new_list, item) == 0) && item != a:word
      call add(new_list, item)
      let i += 1
    endif
  endfor

  return new_list
endfunction
