let g:vjs_tags_enabled = 0
let g:vigun_mappings = [
      \ {
      \   'pattern': 'test/.*_test.rb$',
      \   'all': 'bin/test test #{file}',
      \   'nearest': 'bin/test test #{file}:#{line}',
      \ }
      \]
