# vim-imagine

A simple context-based vim completion plugin. It wil try to return the most possible word based on current context. Choosing a word from the menu should be avoided.

**Supports**

- Literial <kbd>tab</kbd>.
- [Custom snippets](#custom_snippets).
- [Extensible fuzzy match](#fuzzy_match).
- [emmet-vim][0].
- [supertab][1].

## Usage

In INSERT mode, press <kbd>tab</kbd> to complete the word. Press <kbd>c-u</kbd> to undo the completion.

## Install

- Use [VundleVim](https://github.com/VundleVim/Vundle.vim): 

        Plugin 'leafOfTree/vim-imagine'

- Or manually, clone this plugin, drop it in custom `path/to/this_plugin`, and add it to `rtp` in vimrc

        set rpt+=path/to/this_plugin

## How it works

It tries these methods in order to find out the completion word.

- Literial <kbd>tab</kbd>.
- [Custom snippets](#custom_snippets).
- [Extensible fuzzy match](#fuzzy_match).
- [emmet-vim][0].
- [supertab][1].

### Literial <kbd>tab</kbd>

It will return literial <kbd>tab</kbd> if there are blanks or the start of line before the cursor.

### Custom snippets <a name="custom_snippets"></a>

It will return the snippet if the characters before the cursor match the key in the dictionary defined by [snippets file](#snippets).

### Extensible fuzzy search <a name="fuzzy_match"></a>

It will return the first match that fuzzy methods find in current file. The longest will be used if there are more than one matched words.

#### Builtin methods

- hyphen

        adg -> abc-def-ghi

- capital

        adg -> abcDefGhi

- dot

        adg -> abc.def.ghi

    **Note**: context words won't be split by `.` in this method
    
- underscore

        adg -> abc_def_ghi

- include

        xyz -> 000x111y222z


#### Custom methods 

All methods defined in [g:vim_imagine_fuzzy_custom_methods](#fuzzy_custom_methods) are used in fuzzy completion. See the [example](#custom_methods_eample).

### Emmet

It will return [emmet-vim][0]'s result if it's installed when there is only one character before the cursor or [b:vim_imagine_use_emmet](#use_emmet) is 1.

### Supertab

It will return [supertab][1]'s result if it's installed. It's worth nothing that <kbd>tab</kbd> can't be used to move in popup menu, but <kbd>up</kbd>, <kbd>down</kbd>, <kbd>enter</kbd> still work.

## Configuration

### Variables

#### g:vim_imagine_snippets_path <a name="snippets"></a>

- description: the path of the snippets file under the `runtimepath`. See [the example snippets](/setting/example_snippets.vim)
- type: `string`.
- default: `'plugin/imagine_snippets.vim'`. 

It's recommended to put it in `.vim` or `vimfiles`. The only requirement is that these variables 
`g:vim_imagine_dict`,
`g:vim_imagine_dict_1`,
`g:vim_imagine_dict_2`
are defined as expected. If the path is not readable, [the example snippets](/setting/example_snippets.vim) will be used.

#### g:vim_imagine_fuzzy_chain

- description: the order of methods that fuzzy search uses.
- type: `list`.
- default: 

    ```vim
    let g:vim_imagine_fuzzy_chain = [
        \'capital', 
        \'hyphen', 
        \'dot', 
        \'underscore', 
        \'include',
        \]
    ```

#### g:vim_imagine_fuzzy_custom_methods <a name="fuzzy_custom_methods"></a>

- description: defines custom methods that fuzzy search uses.
- type: `dictionary`.

    - members: `chars => regexp`. The `chars` is the characters before the cursor and the `regexp` is used to match words in current file. The member name can be used in `g:vim_imagine_fuzzy_chain`.

    - members end with `_splits`: `splits => modified splits`. Modify `splits` which determines how words is generated from current file. Default is a comma-separated string(comma and space will always be added).

            (,),{,},<,>,[,],=,:,'',",;,/,\,+,!,#,*,`,|,.
        

- default: `{}`
- example:<a name="custom_methods_eample"></a> 

    ```vim
    let g:vim_imagine_fuzzy_custom_methods = {}

    function! g:vim_imagine_fuzzy_custom_methods.same_first(chars)
      let case_flag = ''
      if a:chars =~ '\v\C[A-Z]'
        let case_flag = '\C'
      endif

      let regexp = join(split(a:chars, '\zs'), '.*')
      let regexp = '\v'.case_flag.'^(\@|\$)?'.regexp.'.*>'
      return regexp
    endfunction

    let g:vim_imagine_fuzzy_chain = [
        \'capital', 
        \'hyphen', 
        \'dot', 
        \'underscore', 
        \'same_first',
        \'include',
        \]
    ```

#### g:vim_imagine_fuzzy_favoured_words

- description: The words to check firstly when fuzzy search starts. The list can also be changed while editing files by <kbd>leader</kbd> <kbd>a</kbd> in NORMAL mode.
- type: `list`.
- default: `[]`

#### b:vim_imagine_use_emmet <a name="use_emmet"></a>

- description: Enable emmet method.
- type: 'int' (0 or 1)
- default: 0
- example:

```vim
autocmd FileType html,pug,xml,css,less let b:vim_imagine_use_emmet = 1
```

### Mappings

#### INSERT mode

- <kbd>tab</kbd>: complete the chars before the cursor

- <kbd>c-u</kbd>: undo the completion. 

    ```vim
    let g:vim_imagine_mapping_undo_completion = '<c-u>'
    ```

- <kbd>c-f</kbd>: toggle emmet

    ```vim
    let g:vim_imagine_mapping_toggle_emmet = '<c-f>'
    ```

#### NORMAL mode

- <kbd>leader</kbd> <kbd>a</kbd>: add the word under the cursor to favoured words <a name="add_favoured_word"></a>

    ```vim
    let g:vim_imagine_mapping_add_favoured_word = '<leader>a'
    ```

[0]: https://github.com/mattn/emmet-vim
[1]: https://github.com/ervandew/supertab
