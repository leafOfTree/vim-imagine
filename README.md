# imagine.vim
A vim compeletion plugin.

## Intro

vim-imagine can return the most likely word based on current editing file. Suppert [supertab](https://github.com/ervandew/supertab) and [emmet-vim](https://github.com/mattn/emmet-vim).

## Usage

In INSERT mode, press `tab` to complete the word.

## Install

- Use [VundleVim](https://github.com/VundleVim/Vundle.vim): 

        Plugin 'leafOfTree/vim-imagine'

- Or manual: download `vim-imagine` and drop it in `Vim/vimfiles/`.

## Help 
After installing, see `:h vim-imagine`.

## Matches

Matches can be defined in |g:imagine_matchchain|. Vim-imagine will traverse the chain in order until a matching word is returned.

Note: All these matches return the longest matching word.

---------------------------------------------------------------------------

**Prior**                                           

Match word from |g:imagine_prior_words|. Word should start with the same
letter.

Ex:

    " context
    let g:imagine_prior_words = ['abc', 'def']

    " word -> complete word
    ab -> abc
    ac -> abc
    de -> def
    df -> def

---------------------------------------------------------------------------

**Capital**                                         

Match word with same Capital, useful for camelCase situation.

Ex:

    " context
    openWindow, getName

    " word -> complete word
    ow -> openWindow
    gn -> getName
    

---------------------------------------------------------------------------

**UnderscoreOrDot**                                 

Match word with same letter after '_' or '.'.

Ex:

    " context
    window.href.location, syntastic_html_checkers, my_obj.text

    " word -> complete word
    whl -> window.href.location
    shc -> syntastic_html_checkers
    mot -> my_obj.text

---------------------------------------------------------------------------

**Hyphen**                                          

Match word with same letter after '-'.

Ex:

    " context
    col-xs-5

    " word -> complete word
    cx -> col-xs-5
    cx5 -> col-xs-5

---------------------------------------------------------------------------

**Dollar**                                          

Match word with leader '$'.

Ex:

    " context
    $scope.apply(), $location

    " word -> complete word
    sa -> $scope.apply
    lo -> $location

---------------------------------------------------------------------------

**Chars**                                           

Match word with same chars of the typed word.

Ex:

    " context
    variabletocomplete, longvariabletocomplete

    " word -> complete word
    vtc -> longvariabletocomplete

---------------------------------------------------------------------------

**Line**                                            

Match whoe line with same start and end of the typed word. Leading spaces 
are ingored.

Ex:

    " context
    a example $ line

    " word -> complete word
    a$e -> a example $ line
