local compiler = vim.fn.exepath("spawn.exe")
if compiler == "" then
  compiler = vim.fs.joinpath(vim.env.ProgramFiles, "Spawn", "spawn.exe")
end
return {
  {
    name = "spawn-sdk",
    dir = vim.fs.joinpath(vim.fs.dirname(compiler), "share", "spawn", "tooling", "nvim"),
    lazy = false,
    init = function()
      vim.g.spawn_compiler = compiler
    end,
  },
}
