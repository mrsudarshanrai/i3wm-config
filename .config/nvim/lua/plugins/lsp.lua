return {
  "neovim/nvim-lspconfig",
  init = function()
    -- Disables inlay hints globally on startup safely
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
      end,
    })
  end,
  opts = {
    inlay_hints = { enabled = false },
    servers = {
      -- Use ts_ls instead of the deprecated tsserver
      ts_ls = {},
    },
    setup = {
      -- Let LazyVim handle standard ts_ls setup automatically
    },
  },
}