if exists('g:loaded_gitui_nvim')
  finish
endif
let g:loaded_gitui_nvim = 1

lua << EOF
require('gitui').setup({})
EOF

nnoremap <silent> <leader>gg :GitUIToggle<CR>
