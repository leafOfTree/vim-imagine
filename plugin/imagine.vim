" vim-imagine.vim - Complete word with the most likely one
" Maintainer: leaf <leafvocation@gmail.com>
" Repository: https://github.com/leafOfTree/vim-imagine

if exists('g:loaded_vim_imagine') || &cp
  finish
endif

let g:loaded_vim_imagine = 1

if !exists('g:vim_imagine_matchchain')
  let g:vim_imagine_matchchain = [
        \'capital', 
        \'hyphen', 
        \'dot', 
        \'underscore', 
        \'same_first_chars',
        \'chars',
        \]
endif

" =========================================================
" Main function
" =========================================================

" Mappings
noremap <leader>a :call imagine#AddPriorWords()<cr>
noremap <leader>e :call imagine_emmet#ToggleEmmet()<cr>

" can't undo, can traverse complete list
inoremap <tab> <c-r>=imagine#TabRemap()<cr>

" can undo, can't traverse complete list
" inoremap <tab> <c-g>u<c-r>=TabRemap()<cr>
