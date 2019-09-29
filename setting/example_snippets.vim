"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setting exmpale file
" 
" Note:
" It's recommended to save this file as 'plugin/imagine_snippets.vim' under the 'runtimepath'. 
" Then add your custome snippets in it.
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:use_react = 0

" Check all characters before the cursor
let dict = {}
let dict_base = {}

" Only check the last character
let dict_1 = {}
let dict_1_base = {
        \'{': "{\<cr>\<esc>O",
        \'(': "(\<cr>\<esc>O", 
        \'`': "`\<cr>\<esc>O", 
        \'>': ">\<cr>\<esc>O", 
        \'<': "< />", 
        \}

" Only check last two characters
let dict_2 = {}

if (&filetype == 'html'  || &filetype == 'xml' || &filetype == '')
  let dict = {
        \'d'    : '$', 
        \'e'    : '{{}}', 
        \'r'    : 'return ',     
        \'f'    : "function (|) {\<cr>}", 
        \'cl'   : "console.log(|);", 
        \'al'    : "alert(|)",
        \'\sp'  : '&nbsp;', 
        \'\la'  : '&laquo;',  
        \'\ra'  : '&raquo;', 
        \'\he'  : '&hellip;', 
        \'ael' : "addEventListener('|')", 
        \'gebi' : "getElementById('|')", 
        \}

  let dict_1 = {
        \'A'    : ' && ', 
        \'O'    : ' || ', 
        \'L'    : '=""',
        \}
elseif &filetype == 'vim'
  let dict = {
        \'r'    : 'return ', 
        \'f'    : "function! (|)\rendfunction", 
        \'l'    : "for | in \<cr>endfor",
        \'aug'  : "augroup test\rautocmd!\rautocmd |\raugroup end", 
        \}

  let dict_1 = {
        \'E'    : ' == ', 
        \'L'    : ' <= ',
        \'N'    : ' >= ',
        \'P'    : ' += ',
        \'M'    : ' -= ',
        \'*'    : ' *= ',
        \'D'    : ' /= ',
        \'R'    : ' =~ ',
        \'U'    : ' !~ ',
        \'A'    : ' && ',
        \'O'    : ' || ',
        \'F'    : ' ! ' ,
        \'B'    : ' != ' ,
        \}
elseif (&filetype == 'javascript.jsx' 
      \|| &filetype == 'vue' 
      \|| &filetype == 'svelte' 
      \|| &filetype == 'javascript.typescript')
  let dict = {
        \'c'    : '// ', 
        \'co'   : 'const ',
        \'con'  : 'constructor',
        \'com'  : "component",
        \'v'    : '{ | }',
        \'t'    : 'this.',
        \'r'    : 'return |;', 
        \'u'    : 'undefined ', 
        \'tp'   : 'this.props.',
        \'ts'   : 'this.state.',
        \'tss'   : 'this.setState({});',
        \'tsd'   : 'this.setData({});',
        \'im'   : 'import  from ',
        \'doc'  : 'document',
        \'pro'  : 'prototype.',
        \'ins'  : 'instanceof ',
        \'hop'  : 'hasOwnProperty()',
        \'req'  : "require('')",
        \'mr'   : 'Math.random()',
        \'me'   : 'module.exports',
        \'ex'   : 'export ',
        \'ed'   : 'export default ',
        \'cl'   : "console.log(|);", 
        \'type' : "Object.prototype.toString.call() === 'object'", 
        \'push' : "Array.prototype.push.apply()",
        \'gebi' : "document.getElementById('')", 
        \'gebt' : "getElementsByTagName('')0]", 
        \'f'    : "function (|) {\<cr>}", 
        \'g'    : "function* (|) {\<cr>}", 
        \'F'    : "function (|) {  }",
        \'a'    : "(|) => {}", 
        \'s'    : "| => ", 
        \'S'    : "(|) => ()", 
        \'pde'   : "preventDefault();",
        \'spr'   : "stopPropagation();",
        \'cn'   : "className={|}",
        \'cN'   : "className=\"|\"",
        \'js'   : "JSON.stringify()",
        \}

  if s:use_react
    let dict_react = {
          \'ir'   : "import React from 'react';\<cr>",
          \'is'   : "import './index.less';",
          \'rc'   : "React.Component {|}",
          \'rr'   : "ReactDOM.render(<| />)",
          \'tpd'  : "this.props.dispatch({\<cr>type: '|',\<cr>payload: {},\<cr>})"
          \}
    call extend(dict, dict_react)
  endif

  let dict_1 = {
        \'V'    : '={}',
        \'L'    : '=""',
        \'M'    : "(|) {\r}",
        \'E'    : " === ", 
        \'A'    : ' && ', 
        \'O'    : ' || |', 
        \'P'    : ' += ', 
        \'I'    : '++', 
        \'D'    : '--', 
        \'N'    : '!', 
        \'B'    : ' !== ', 
        \}

  let dict_2 = {
        \'Ge': ' >= ',
        \'Le': ' <= ',
        \'Ne': ' !== ',
        \}
endif

let g:vim_imagine_dict = dict
let g:vim_imagine_dict_1 = extend(dict_1, dict_1_base)
let g:vim_imagine_dict_2 = dict_2
" vim: fdm=indent
