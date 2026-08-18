-- Project-local Neovim config, auto-loaded via Neovim's 'exrc' feature.
-- Requires `vim.o.exrc = true` in your user config; Neovim will prompt to
-- trust this file the first time (see :h :trust) — accept once and it's
-- remembered for future sessions.

vim.lsp.config('vtsls', {
  cmd = { 'vtsls', '--stdio' },
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_markers = { 'tsconfig.json', 'package.json', '.git' },
})

vim.lsp.enable('vtsls')
