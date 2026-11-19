local windows = vim.fn.has("win32") == 1
local executable = windows and "spawn.exe" or "spawn"
local candidates = { vim.fn.exepath(executable) }
if windows and vim.env.ProgramFiles then
  table.insert(candidates, vim.fs.joinpath(vim.env.ProgramFiles, "Spawn", executable))
elseif vim.fn.has("macunix") == 1 then
  table.insert(candidates, "/Library/Spawn/spawn")
end

for _, path in ipairs(candidates) do
  if path ~= "" and vim.fn.executable(path) == 1 then
    -- A PATH entry can be a symlink to the compiler inside an extracted SDK.
    local compiler = vim.uv.fs_realpath(path) or path
    local runtime = vim.fs.joinpath(vim.fs.dirname(compiler), "share", "spawn", "tooling", "nvim")
    if vim.fn.isdirectory(runtime) == 1 then
      return {
        {
          name = "spawn-sdk",
          dir = runtime,
          lazy = false,
          init = function()
            vim.g.spawn_compiler = compiler
          end,
        },
      }
    end
  end
end

return {}
