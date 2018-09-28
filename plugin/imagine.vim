" vim-imagine.vim - Complete word with the most likely one
" Maintainer: Leaf
" Version 0.1

if exists('g:loaded_imagine') || &cp
  finish
endif

let g:loaded_imagine = 1
let b:imagine_use_emmet = 0
let g:imagine_prior_words = []

if !exists('g:imagine_matchchain')
  let g:imagine_matchchain = ['Prior', 'Capital', 
        \'UnderscoreOrDot', 'Hyphen', 'Dollar', 
        \'FirstMatchChars', 'Chars', 'Line']
endif

let s:name = 'vim-imagine'
let s:__DEBUG__ = 1
let s:max_length = 10

" =========================================================
" Main function
" =========================================================
function! Main()
  " can undo, can't traverse complete list
  "autocmd FileType * :inoremap<silent><buffer> <tab> <c-g>u<c-r>=TabRemap()<cr>
  " can't undo, can traverse complete list
  autocmd FileType * :inoremap<silent><buffer> <tab> <c-r>=TabRemap()<cr>

  " Load settings
  autocmd FileType * :runtime config/settings.vim
  autocmd BufEnter * :runtime config/settings.vim

  " Mappings
  noremap <leader>a :call AddPriorWords()<cr>
  " emmet config
  noremap <leader>e :call ToggleEmmet()<cr>
  autocmd FileType html,xml,vue,javascript.jsx,eruby,pug :inoremap<buffer> <c-f> <esc>:call ToggleEmmet()<cr>a

  " default use emmet
  autocmd FileType html,pug,xml :let b:imagine_use_emmet = 1
endfunction
" =========================================================
" Main function End
" =========================================================

call Main()

" =========================================================
" Helper functions
" =========================================================
" Toggle b:imagine_use_emmet
function! ToggleEmmet()
  if !exists('b:imagine_use_emmet')
    let b:imagine_use_emmet = 1
  else
    let b:imagine_use_emmet = 1-b:imagine_use_emmet
  endif
  if b:imagine_use_emmet == 1
    echom '['.s:name.'] Use emmet'
  else
    echom '['.s:name.'] Not use emmet'
  endif
endfunction

function! TabRemap()
  set undolevels=1000

  call SetType('')

  " Call SuperTab if the completion list is visible
  if pumvisible()
    call SetType('SuperTab Visible')
    return SuperTab('n')
  endif

  let ret = []
  let g:column = col('.')
  let line = getline('.')
  let g:line = line
  let g:word = GetWord(line)

  call LogMsg('word: '.g:word)

  " Return <tab> if in column 1 or prefixed by spaces
  unlet ret
  let ret = TabMatch()
  if count([0], ret) == 0
    return ret
  endif

  " custom Direct match
  unlet ret
  let ret = DirectMatch()
  if count([0], ret) == 0
    return ret
  endif

  " emmet match
  unlet ret
  let ret = EmmetMatch()
  if count([0], ret) == 0
    return ret
  endif


  " fuzzy match
  unlet ret
  let ret = FuzzyMatch()
  if count([0], ret) == 0
    return ret
  endif


  " SuperTab match
  unlet ret
  let ret = SuperTabMatch()
  if count([0], ret) == 0
    return ret
  endif

  return ''
endfunc

" Get the word to complete
function! GetWord(line)
  let line = a:line
  let column = g:column
  let end = column - 2
  let start = end - 1

  let match = '\v[0-9A-Za-z\-\$_]'

  while line[start] =~ match
    let start -= 1
  endwhile

  let word = line[start+1 : end]
  return word
endfunction

" Set complete type
function! SetType(type)
  if a:type != ''
    echom '['.s:name.'] Type: '.a:type
  endif
  let g:type = a:type
endfunction

function! TabMatch()
  let column = g:column
  let word = g:word

  if column == 1 || word == '' || word =~ '\v\s+'
    call SetType('Tab')
    return "\<tab>"
  endif
endfunction

function! DirectMatch()
  let column = g:column
  let word = g:word
  let length = len(g:word)

  let res = get(g:dict, word, [])
  if res == []
    let res = get(g:dict_end, word[-1:-1], [])
    if res != []
      let length = 1
    elseif length > 1
      let res = get(g:dict_end_2, word[-2:-1], [])
      if res != []
        let length = 2
      endif
    endif
  endif

  if res != []
    let new_word = [res[0]]
    let flag = res[1]
    if flag == '$'
      " For '$', return new_word as it is
      call SetType('Direct')
      return new_word[0]
    else
      " Else, complete the word with new_word
      " For issue, do complete() twice
      call complete(column - length, new_word)
      if g:type == ''
        call complete(column - length, new_word)
      endif

      call SetType('Direct')
      return MoveAfterDirectComplete(flag)
    endif
  endif
endfunction

function! EmmetMatch()
  if (exists('g:loaded_emmet_vim') && g:loaded_emmet_vim)
    let length = len(g:word)

    " length is 1 or 
    " can switch by b:imagine_use_emmet
    let types1 = ["html","css","less","xml","vim","jst","typescript","pug","ant", "eruby", "javascript.jsx", "javascript", "php"]
    let is_types1_use_emmet = count(types1, &filetype) > 0 &&
          \(length == 1 || (exists('b:imagine_use_emmet') && b:imagine_use_emmet))

    " length is 1 or
    " can't switch by b:imagine_use_emmet
    let types2 = ["python","markdown", 'cpp', 'c']
    let is_types2 = count(types2, &filetype) > 0 &&
          \(length == 1)

    if is_types1_use_emmet || is_types2
      call SetType('Emmet')

      if match(g:line, '=>') != -1 || match(g:line, '}') != -1
        return emmet#expandAbbr(1, "")
      else
        return emmet#expandAbbr(0, "")
      endif 
    endif
  endif
endfunction

function! FuzzyMatch()
  let column = g:column
  let word = g:word
  let length = len(g:word)

  if (length > 1 && length < s:max_length)
    let ret = FuzzyMatchChain(word)

    if len(ret) > 0 && ret[0] != word
      " For SuperTab issue, do complete() twice
      call complete(column - length, [ret[0]])
      call complete(column - length, [ret[0]])

      call SetType('Fuzzy')
      return ''
    endif
  endif
endfunction

function! NoValidRet(ret)
  let ret = a:ret
  return ret == [] || ret == [g:word]
endfunction

function! PostRet(ret, word)
  let ret = a:ret
  let word = a:word

  function! RemoveLeaderSpaces(val)
    return substitute(a:val, '\v^\s*', '', 'g')
  endfunction
  let ret = map(ret, "RemoveLeaderSpaces(".'v:val'.")")

  if ret == [word]
    call remove(ret, 0)
  endif
  return ret
endfunction

function! FuzzyMatchChain(word)
  call LogMsg('In Fuzzy')
  let word = a:word
  let lines = getline(1, '$')
  let ret = []

  "let g:split_str = '\v(\s|\{|\}|\=|\:|\''|\"|,|;|\<|\>|\[|\]|\/|\\|\+|\!|#|*|`)'
  let g:split_str = '\v(\s|\(|\)|\{|\}|\=|\:|\''|\"|,|;|\<|\>|\[|\]|\/|\\|\+|\!|#|*|`|\.)'

  " default: ['Prior', 'Capital', 'UnderscoreOrDot', 'Hyphen', 'Dollar', 'Chars', 'Line']

  let matchChain = g:imagine_matchchain

  for method in matchChain
    if NoValidRet(ret)
      let ret = function(method)(word, lines)
    endif
  endfor

  let ret = PostRet(ret, word)
  return ret
endfunction

function! SuperTabMatch()
  if exists("*SuperTab")
    call SetType('SuperTab')
    return SuperTab('n')
  endif
endfunction

let s:action_dict = {'h': "\<left>", 'r': "\<cr>"}
function! MoveAfterDirectComplete(action)
  let a = a:action
  let d = s:action_dict
  let ret = ''

  if a != '' && len(a) % 2 == 0
    let i = 0
    let l = len(a)

    while i < l
      let times = a[i+0]
      let action = a[i+1]

      for j in range(times)
        let ret = ret . d[action]
      endfor
      echom 'ret:'
      echom ret
      let i += 2
    endwhile
  endif

  return ret
endfunc

function! LengthDecrement(i1, i2)
  return len(a:i2) - len(a:i1)
endfunction

function! LengthIncrement(i1, i2)
  return len(a:i1) - len(a:i2)
endfunction

function! LogMsg(msg)
  if s:__DEBUG__
    echom '['.s:name.'] '. a:msg[0:50]
  endif
endfunction

function! Prior(word, lines)
  call LogMsg('Prior')
  let ret = []

  let regexp_word = a:word
  let regexp_word = join(split(regexp_word, '\zs'), '[a-zA-Z-_]*')
  let regexp_word = escape(regexp_word, '()@')
  let regexp_word = '\v^'.regexp_word

  let words = copy(g:imagine_prior_words)
  let compl_words = filter(words, 'v:val =~ '''.regexp_word.'''')
  let ret = ret + compl_words

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)

  call LogMsg(regexp_word)
  return ret
endfunction

function! Hyphen(word, lines)
  call LogMsg('Hyphen')
  let word = a:word
  let lines = a:lines
  "let split_str = '\v(\s|\(|\)|\{|\}|\=|\.|\:|\''|\"|,|;|\<|\>|\!|\*)'
  "let split_str = '\v(\s|\(|\)|\{|\}|\=|\.\:|\''|\"|,|;|\<|\>|\[|\]|#|\!|\*)'
  let split_str = g:split_str

  if word[0] == '@'
    let regexp_word = word[1:]
    let pre_char = '\@'
  else
    let regexp_word = word
    let pre_char = ''
  endif
  let regexp_word = pre_char.join(split(regexp_word, '\zs'), '\w*(-)')
  let regexp_word = '\v^\@?'.regexp_word.'[0-9a-zA-Z]*>'

  let ret = []
  for l in lines
    let words = split(l, split_str)
    let compl_words =
          \ filter(words, 'v:val =~ '''.regexp_word.'''')
    let ret = ret + compl_words
  endfor

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! Capital(word, lines)
  call LogMsg('Capital')
  let word = a:word
  let lines = a:lines
  "let split_str = '\v(\s|\(|\)|\{|\}|\=|\.\:|\''|\"|,|;|\<|\>|\[|\]|#|\!|\*)'
  let split_str = g:split_str

  if word[0] == '@'
    let regexp_word = word[1:]
    let pre_char = '\@'
  else
    let regexp_word = word
    let pre_char = ''
  endif
  let regexp_word = substitute(regexp_word, '\v.\zs\w*', '\U\0', 'g')
  let regexp_word = join(split(regexp_word, '\zs'), '\l*')
  let regexp_word = '['.regexp_word[0].toupper(regexp_word[0]).']'.
        \ regexp_word[1:]
  let regexp_word = pre_char.regexp_word
  let regexp_word = '\v\C^\@?'.regexp_word.'\l*>'

  let ret = []
  for l in lines
    let words = split(l, split_str)
    let compl_words =
          \ filter(words, 'v:val =~ '''.regexp_word.'''')
    let ret = ret + compl_words
  endfor

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! UnderscoreOrDot(word, lines)
  call LogMsg('Underscore Or Dot')
  let word = a:word
  let lines = a:lines
  let split_str = substitute(g:split_str, '|\\\.', '', 'g')

  let pre_char = ''
  if word[0] == '@'
    let regexp_word = word[1:]
    let pre_char = '\@'
  elseif word[0] == '$'
    let regexp_word = word[1:]
    let pre_char = '\$'
  else
    let regexp_word = word
  endif

  let regexp_word = join(split(regexp_word, '\zs'), '[0-9a-zA-Z]*(_|\.)')
  if pre_char != ''
    let regexp_word = pre_char.'[0-9a-zA-Z]*(_|\.)'.regexp_word
  endif
  let regexp_word = '\v^\$?'.regexp_word.'[0-9a-zA-Z]*>'

  let ret = []
  for l in lines
    let words = split(l, split_str)
    let compl_words =
          \ filter(words, 'v:val =~ '''.regexp_word.'''')
    let ret = ret + compl_words
  endfor
  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! Dollar(word, lines)
  call LogMsg('Dollar')
  let word = a:word
  let lines = a:lines
  let split_str = '\v(\s|\(|\)|\{|\}|\=|\.|\:|\''|\"|,|;|\<|\>|\[|\]|#|\!|\*)'
  "let split_str = g:split_str

  let regexp_word = word
  let regexp_word = join(split(regexp_word, '\zs'), '\w*')
  let regexp_word = escape(regexp_word, '()@')

  let regexp_word = '\v^\$'.regexp_word.'\w*>'

  let ret = []
  for l in lines
    let words = split(l, split_str)
    let compl_words =
          \ filter(words, 'v:val =~ '''.regexp_word.'''')
    let ret = ret + compl_words
  endfor

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! FirstMatchChars(word, lines)
  call LogMsg('Fisrt Match Chars')
  let word = a:word
  let lines = a:lines
  let split_str = substitute(g:split_str, '|\*', '', 'g')

  let regexp_word = word
  let regexp_word = join(split(regexp_word, '\zs'), '[.0-9A-Za-z_-]*')
  let regexp_word = escape(regexp_word, '()@.')

  " Add ^ to match frist character
  let regexp_word = '\v\S*^'.regexp_word

  let ret = []
  for l in lines
    let words = split(l, split_str)
    let compl_words = filter(words, 'v:val =~ '''.regexp_word.'''')
    let ret = ret + compl_words
  endfor

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! Chars(word, lines)
  call LogMsg('Chars')
  let word = a:word
  let lines = a:lines
  let split_str = substitute(g:split_str, '|\*', '', 'g')

  let regexp_word = word
  let regexp_word = join(split(regexp_word, '\zs'), '[.0-9A-Za-z_-]*')
  let regexp_word = escape(regexp_word, '()@.')

  let regexp_word = '\v\S*'.regexp_word

  let ret = []
  for l in lines
    let words = split(l, split_str)
    let compl_words = filter(words, 'v:val =~ '''.regexp_word.'''')
    let ret = ret + compl_words
  endfor

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! Line(word, lines)
  call LogMsg('Line')
  let word = a:word
  let lines = a:lines

  let regexp_word = word
  let regexp_word = join(split(regexp_word, '\zs'), '.*')
  let regexp_word = escape(regexp_word, '()@$')

  let regexp_word = '\v^\s*'.regexp_word.'$'

  let ret = []
  let compl_lines = filter(copy(lines), 'v:val =~ '''.regexp_word.'''')
  let ret = ret + compl_lines

  let ret = sort(ret, "LengthDecrement")
  let ret = RemoveDumplicateElem(ret)
  call LogMsg(regexp_word)
  return ret
endfunction

function! RemoveDumplicateElem(li)
  let old_list = a:li
  let new_list = []
  let i = 0

  for elem in old_list
    if (i == 0 || count(new_list, elem) == 0) && elem != g:word
      call add(new_list, elem)
      let i += 1
    endif
  endfor

  return new_list
endfunction

" Add word under cursor to prior words
function! AddPriorWords()
  normal! viw"zy
  let word = @z
  if count(g:imagine_prior_words, word) == 0
    call add(g:imagine_prior_words, word)
  endif

  echo '['.s:name.'] Prior words: '
  echo g:imagine_prior_words
endfunction
" =========================================================
" Helper functions End
" =========================================================

" vi:fdm=indent

