-- Run after init.lua so the configured LazyVim extras determine the tools to install.
local function bootstrap()
  local lazy = require("lazy")
  local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.env.DOTFILES_NVIM_LOCK), "\n"))
  local plugins = require("lazy.core.config").plugins
  local function mismatches()
    local missing = {}
    for name, plugin in pairs(plugins) do
      if lock[name] then
        local info = require("lazy.manage.git").info(plugin.dir)
        if not info or info.commit ~= lock[name].commit then table.insert(missing, name) end
      end
    end
    return missing
  end
  if #mismatches() > 0 then
    local manager = require("lazy.manage.lock")
    manager.load()
    manager.lock = vim.deepcopy(lock)
    lazy.restore({ wait = true, show = false })
    local missing = mismatches()
    assert(#missing == 0, "Could not restore locked plugins: " .. table.concat(missing, ", "))
  end

  lazy.load({ plugins = { "mason.nvim", "nvim-lspconfig", "nvim-treesitter" } })
  local registry = require("mason-registry")
  local ready = false
  registry.refresh(function() ready = true end)
  assert(vim.wait(120000, function() return ready end), "Mason registry refresh timed out")
  local tools = vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed)
  local map = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
  for _, server in ipairs(require("mason-lspconfig.settings").current.ensure_installed) do
    tools[#tools + 1] = assert(map[server], "Unknown Mason server: " .. server)
  end
  for _, name in ipairs(tools) do
    local pkg = registry.get_package(name)
    if not pkg:is_installed() and not pkg:is_installing() then pkg:install() end
  end
  local remaining = {}
  local done = vim.wait(900000, function()
    remaining = {}
    for _, name in ipairs(tools) do
      local pkg = registry.get_package(name)
      if pkg:is_installing() or not pkg:is_installed() then table.insert(remaining, name) end
    end
    local parsers = require("nvim-treesitter").get_installed("parsers")
    for _, lang in ipairs(LazyVim.opts("nvim-treesitter").ensure_installed) do
      if not vim.tbl_contains(parsers, lang) then table.insert(remaining, lang) end
    end
    return #remaining == 0
  end, 500)
  assert(done, "Unfinished tools or parsers (see :MasonLog and :TSLog): " .. table.concat(remaining, ", "))
end

local ok, err = xpcall(bootstrap, debug.traceback)
if not ok then io.stderr:write(err .. "\n") end
vim.cmd(ok and "qa!" or "cquit! 1")
