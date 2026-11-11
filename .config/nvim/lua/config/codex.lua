-- Use the existing Codex CLI and ChatGPT login inside a project-scoped terminal.
local M = {}
local commands = {}

local function executable()
  local found = vim.fn.exepath("codex")
  if found ~= "" then
    return found
  end
  for _, path in ipairs({
    "/Applications/Codex.app/Contents/Resources/codex",
    "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
  }) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  vim.notify("Codex CLI was not found on PATH or in the desktop app.", vim.log.levels.ERROR)
end

local function context()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  -- Terminal toggles must keep using the terminal's project, not its term:// URI.
  local root = vim.bo[buf].buftype == "terminal" and vim.b[buf].codex_root
    or vim.fs.root(name ~= "" and name or vim.fn.getcwd(), { ".git", "CMakeLists.txt", "package.json" })
    or vim.fn.getcwd()
  return root, name, vim.api.nvim_win_get_cursor(0)[1]
end

local function open(root, prompt)
  local cmd = executable()
  if not cmd then
    return
  end
  local args = { cmd, "--no-alt-screen" }
  if prompt then
    args[#args + 1] = prompt
    commands[root] = args
  elseif commands[root] then
    args = commands[root]
  end
  local terminal = Snacks.terminal.toggle(args, {
    cwd = root,
    win = { position = "right", width = 0.45 },
    auto_close = false,
  })
  if terminal and terminal.buf then
    vim.b[terminal.buf].codex_root = root
  end
end

function M.toggle()
  local root = context()
  open(root)
end

function M.ask(selection)
  local root, file, line = context()
  local excerpt
  if selection then
    local mode = vim.fn.mode()
    excerpt = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode }), "\n")
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "nx", false)
  end
  local modified = vim.bo.modified
  vim.ui.input({ prompt = "Ask Codex: " }, function(question)
    if not question or question:match("^%s*$") then
      return
    end
    local prompt = question
    if file ~= "" then
      prompt = prompt .. "\n\nEditor context: " .. file .. ":" .. line
    end
    if modified then
      prompt = prompt .. "\nThe editor buffer has unsaved changes; the file on disk may differ."
    end
    if excerpt then
      prompt = prompt .. "\nSelected code (current editor contents):\n" .. excerpt
    end
    open(root, prompt)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("Codex", M.toggle, { desc = "Toggle project Codex terminal" })
  vim.api.nvim_create_user_command("CodexAsk", function()
    M.ask(false)
  end, { desc = "Ask Codex about the current file" })
  vim.keymap.set({ "n", "t" }, "<leader>ac", M.toggle, { desc = "Codex: toggle terminal" })
  vim.keymap.set("n", "<leader>aa", function()
    M.ask(false)
  end, { desc = "Codex: ask about file" })
  vim.keymap.set("x", "<leader>aa", function()
    M.ask(true)
  end, { desc = "Codex: ask about selection" })
end

return M
