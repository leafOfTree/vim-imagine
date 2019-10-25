"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Config {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vim_imagine_debug = 0
let g:vim_imagine_fuzzy_chain = [
      \'capital', 
      \'dot', 
      \'hyphen', 
      \'underscore', 
      \'include',
      \]

let s:test = {}

let s:test.lines = [
      \'These are contexts',
      \'hello html document.body.append(node)',
      \'hello html document.getElementById("node")',
      \'let vim_imagine_debug = 1',
      \'let vim_imagine_matchchain = []',
      \'import React from react componentWillMount () {...}',
      \'from react componentWillUnmount () {...}',
      \]
"}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Functions {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run test
function! s:test.run(test_data, test_name)
  if len(a:test_data) < 2
    call s:LogWarningMsg('test_data should be a list of length 2 or 3')
  endif

  if len(a:test_data) == 2
    let [line, expect] = a:test_data
    let lines = self.lines
  elseif len(a:test_data) == 3
    let [lines, line, expect] = a:test_data
  endif

  let column = len(line) + 1
  let ret = imagine#TabRemap(line, column, lines, [])

  if ret != expect
    let msg = a:test_name.' failed. '
          \.'Return '.ret.', expect '.expect
    call s:LogWarningMsg(msg)
  else
    let msg = a:test_name.' passed. '
    call s:LogMsg(msg)
  endif
endfunction

function s:StartTest()
  call s:LogMsg('--------- Test starts ------------')
  for key in keys(s:test)
    if key != 'lines' && key != 'run'
      let test_data = s:test[key]()
      call s:test.run(test_data, key)
    endif
  endfor
endfunction

" Log
function! s:LogWarningMsg(msg)
  echohl WarningMsg
  echom '[Test]: '.a:msg
  echohl None
endfunction

function! s:LogMsg(msg)
  echom '[Test]: '.a:msg
endfunction


"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Test cases {{{
"
" Format: test_data = [lines, input, output] | [input, output]
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:test.Prior()
  let g:vim_imagine_fuzzy_favoured_words = ['super', 'men', 'hero']
  let test_data = ['he', 'hero']
  return test_data
endfunction

function! s:test.TabMatch()
  let test_data = ['', "\<tab>"]
  return test_data
endfunction

function! s:test.DirectMatch()
  let g:vim_imagine_test_dict = {
        \'e'     : '{{ | }}', 
        \'f'     : 'function () {}', 
        \}

  let test_data  = ['e', '{{ | }}']
  return test_data
endfunction

function! s:test.FuzzyMatch_capital()
  return [
        \['import React from react componentWillMount () {...}'],
        \'cwm', 
        \"componentWillMount"
        \]
endfunction

function! s:test.FuzzyMatch_dot()
  return ['dba', "document.body.append"]
endfunction

function! s:test.FuzzyMatch_hyphen()
  return ['vid', "vim_imagine_debug"]
endfunction

function! s:test.FuzzyMatch_include()
  return ['txt', "contexts"]
endfunction

function! s:test.FuzzyMatch_mix()
  return [
        \['abc.def', 'abc_def', 'abc-def'],
        \'ad',
        \'abc.def',
        \]
endfunction
function! s:test.FuzzyMatch_mix_underscore()
  return [
        \['abc.def', 'abc_def', 'abc-def'],
        \'a_d',
        \'abc_def',
        \]
endfunction
function! s:test.FuzzyMatch_mix_hyphen()
  return [
        \['abc.def', 'abc_def', 'abc-def'],
        \'a-d',
        \'abc-def',
        \]
endfunction

call s:StartTest()
" vim: fdm=marker
