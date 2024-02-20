local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "tsserver", "tailwindcss", "prismals", "emmet_ls" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig["svelte"].setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
  on_attach(client, bufnr)
        
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { "*.js", "*.ts" },
    callback = function(ctx)
      if client.name == "svelte" then
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
      end
    end,
  })
  end,
})
