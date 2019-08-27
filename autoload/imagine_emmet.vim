" call s:InitUseEmmetVariable()
let s:name = 'vim-imagine'

" Toggle b:imagine_use_emmet
function! imagine_emmet#ToggleEmmet() abort
  call s:InitUseEmmetVariable()
  let b:imagine_use_emmet = 1-b:imagine_use_emmet
  if b:imagine_use_emmet == 1
    echom '['.s:name.'] Use emmet'
  else
    echom '['.s:name.'] Not use emmet'
  endif
endfunction

function! imagine_emmet#EmmetMatch(word, line) abort
  call s:InitUseEmmetVariable()
  let length = len(a:word)

  " switch by b:imagine_use_emmet
  if b:imagine_use_emmet 
        \|| (length == 1 && exists("b:imagine_always_use_emmet_for_one"))
    call s:SetType('Emmet')

    " emmet#expandAbbr(mode, abbr) range abort
    if match(a:line, '\v(\=\>)|(\})') != -1
      return emmet#expandAbbr(1, "")
    else
      return emmet#expandAbbr(0, "")
    endif 
  endif
endfunction


function! s:InitUseEmmetVariable()
  if !exists('b:imagine_use_emmet')
    let b:imagine_use_emmet = 0
  endif
endfunction

" Set complete type
function! s:SetType(type) abort
  if a:type != ''
    call s:LogMsg('Type: '.a:type)
  endif
endfunction

function! s:LogMsg(msg, ...) abort
  if exists("g:vim_imagine_debug")
        \ && g:vim_imagine_debug == 1
    " List
    if type(a:msg) == 3 
      for i in a:msg
        echom '== '.i
      endfor
    else
      " String
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

