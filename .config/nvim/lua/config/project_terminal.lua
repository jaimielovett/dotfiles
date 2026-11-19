local M = {}
local windows = vim.fn.has("win32") == 1

local function spawn_root(path)
  if path == "" then return nil end
  -- Include a new main.spawn buffer before its first write.
  local root = vim.fs.basename(path) == "main.spawn" and vim.fs.dirname(path) or vim.fs.root(path, "main.spawn")
  return root and vim.fs.normalize(vim.uv.fs_realpath(root) or root, { expand_env = false })
end

local function options()
  local terminal = vim.b.snacks_terminal
  local location = terminal and terminal.cwd or vim.api.nvim_buf_get_name(0)
  local root = spawn_root(location ~= "" and location or vim.fn.getcwd())
  if not root then
    return { cwd = terminal and terminal.cwd or LazyVim.root() }
  end

  -- Pass paths as environment values so the shell never parses project names as commands.
  local name = vim.fs.basename(root) .. (windows and ".exe" or "")
  return {
    cwd = root,
    env = {
      NVIM_SPAWN_ROOT = root,
      NVIM_SPAWN_COMPILER = vim.g.spawn_compiler or vim.fn.exepath(windows and "spawn.exe" or "spawn"),
      NVIM_SPAWN_PROGRAM = vim.fs.joinpath(root, name),
    },
  }
end

function M.toggle()
  Snacks.terminal.toggle(nil, options())
end

local function build_command()
  local shell = Snacks.config.get("terminal").shell or vim.o.shell
  local argv = type(shell) == "table" and shell or Snacks.terminal.parse(shell)
  local name = vim.fs.basename(vim.fs.normalize(argv[1])):lower():gsub("%.exe$", "")
  if name == "cmd" then
    return 'cd /d "%NVIM_SPAWN_ROOT%" && "%NVIM_SPAWN_COMPILER%" . && "%NVIM_SPAWN_PROGRAM%"'
  elseif name == "powershell" or name == "pwsh" then
    return '& { Set-Location -LiteralPath $env:NVIM_SPAWN_ROOT -ErrorAction Stop; & $env:NVIM_SPAWN_COMPILER .; if ($? -and $LASTEXITCODE -eq 0) { & $env:NVIM_SPAWN_PROGRAM } }'
  end
  return 'cd "$NVIM_SPAWN_ROOT" && "$NVIM_SPAWN_COMPILER" . && "$NVIM_SPAWN_PROGRAM"'
end

function M.run_spawn()
  local opts = options()
  if not opts.env then
    return vim.notify("Open a file in a Spawn project containing main.spawn.", vim.log.levels.WARN)
  end
  if vim.fn.executable(opts.env.NVIM_SPAWN_COMPILER) ~= 1 then
    return vim.notify("Install the Spawn SDK or add its compiler to PATH.", vim.log.levels.ERROR)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.bo[buf].filetype == "spawn" and spawn_root(vim.api.nvim_buf_get_name(buf)) == opts.cwd then
      vim.api.nvim_buf_call(buf, function() vim.cmd.update() end)
    end
  end
  local term = Snacks.terminal.get(nil, opts)
  term:show():focus()
  vim.api.nvim_chan_send(vim.b[term.buf].terminal_job_id, build_command() .. "\r")
end

return M
