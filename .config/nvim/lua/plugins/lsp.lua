return {
  "neovim/nvim-lspconfig",
  config = function()
    -- This is the correct way to disable inlay hints on startup
    vim.lsp.inlay_hint.enable(false)

    -- Your other lspconfig setup goes here
    -- For example:
    local on_attach = function(client, bufnr)
      -- your on_attach mappings
    end

    require("lspconfig").tsserver.setup({
      on_attach = on_attach,
    })

    require("lspconfig").lua_ls.setup({
      on_attach = on_attach,
    })
  end,
}
