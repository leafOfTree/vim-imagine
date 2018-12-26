let g:vim_imagine_debug = 0
let g:vim_imagine_matchchain = [
      \'capital', 
      \'hyphen', 
      \'dot', 
      \'underscore', 
      \'chars',
      \]

let s:test = {}

function! s:test.run(test_data, test_name)
  if len(a:test_data) != 2
    call s:LogWarningMsg('test_data should be a list of length 2')
  endif
  let [line, expect] = a:test_data
  let column = len(line)+2
  let ret = imagine#TabRemap(line, column, self.lines)
  if ret != expect
    let msg = a:test_name.' failed. '
          \.'Return '.ret.', expect '.expect
    call s:LogWarningMsg(msg)
  else
    let msg = a:test_name.' passed. '
    call s:LogMsg(msg)
  endif
endfunction

function! s:LogWarningMsg(msg)
  echohl WarningMsg
  echom '[Test]: '.a:msg
  echohl None
endfunction

function! s:LogMsg(msg)
  echom '[Test]: '.a:msg
endfunction

"""
""" Function: Define test case
""" Format: test_data = [input_word, output_expected]
"""
function! s:test.Prior()
  let g:imagine_prior_words = ['super', 'men', 'hero']
  let test_data = ['he', 'hero']
  return test_data
endfunction

function! s:test.TabMatch()
  let test_data = ['', "\<tab>"]
  return test_data
endfunction

function! s:test.DirectMatch()
  let g:vim_imagine_test_dict = {
        \'gi' : ["getElementById('')", ''], 
        \}
  let test_data = ['gi', "getElementById('')"]
  return test_data
endfunction

let s:test.lines = [
        \'These are contexts',
        \'hello html document.body.append(node)',
        \'hello html document.getElementById("node")',
        \'let vim_imagine_debug = 1',
        \'let vim_imagine_matchchain = []',
        \'import React from react componentWillMount () {...}',
        \'from react componentWillUnmount () {...}',
        \]

function! s:test.FuzzyMatch_dot()
  let test_data = ['dba', "document.body.append"]
  return test_data
endfunction
function! s:test.FuzzyMatch_hyphen()
  let test_data = ['vid', "vim_imagine_debug"]
  return test_data
endfunction
function! s:test.FuzzyMatch_capital()
  let test_data = ['cwm', "componentWillMount"]
  return test_data
endfunction
function! s:test.FuzzyMatch_chars()
  let test_data = ['ctx', "contexts"]
  return test_data
endfunction

for key in keys(s:test)
  if key != 'lines' && key != 'run'
    let test_data = s:test[key]()
    call s:test.run(test_data, key)
  endif
endfor
