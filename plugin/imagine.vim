"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Complete word with the most likely one
"
" Maintainer: leaf <leafvocation@gmail.com>
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists('g:loaded_vim_imagine') || &cp
  finish
endif
let g:loaded_vim_imagine = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Config {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetConfig(name, default)
  return exists(a:name) ? eval(a:name) : a:default
endfunction

let g:SuperTabMappingForward = s:GetConfig('g:vim_imagine_mapping_supertab_forward', '<Nop>')
let s:mapping_undo_completion = s:GetConfig('g:vim_imagine_mapping_undo_completion', '<c-u>')
let s:mapping_toggle_emmet = s:GetConfig('g:vim_imagine_mapping_toggle_emmet', '<c-f>')
let s:mapping_add_favoured_word = s:GetConfig('g:vim_imagine_mapping_add_favoured_word', '<leader>a')
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Mappings {{{
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
inoremap <c-u> <c-g>u<Esc>ua
inoremap <c-f> <esc>:call imagine#ToggleEmmet()<cr>a
noremap <leader>a :call imagine#AddFavouredWord()<cr>

" Can undo completion, but can't traverse the popup menu with <tab>
" You can still use <up>, <down> and <enter>
inoremap <silent> <tab>
      \ <c-g>u
      \<c-r>=imagine#TabRemap()<cr>
      \<c-r>=imagine#Move()<cr>

" Can't undo completion, but can traverse the popup menu with <tab>
" inoremap <silent> <tab> 
      " \ <c-r>=imagine#TabRemap()<cr>
      " \<c-r>=imagine#Move()<cr>

"}}}
"vim: fdm=marker
