require("core.options")
require("core.keymaps")

-- Function to handle the async git job response
local function GitAsyncHandler(_, data, event)
	if event == "exit" then
		if data == 0 then
			print("Git commit and push successful.")
		else
			print("Git commit and push failed.")
		end
	end
end

-- Function to handle git commit and push asynchronously
local function GitCommitAndPush()
	local cmd = 'git commit -am "Autocommit (on save) @ $(hostname -s)" && git push'
	vim.fn.jobstart(cmd, {
		on_exit = function(job_id, data, event)
			GitAsyncHandler(job_id, data, event)
		end,
	})
end

-- Function to perform git pull
local function GitPull()
	local output = vim.fn.system("git pull")
	if vim.v.shell_error ~= 0 then
		print("Git pull failed: " .. output)
	else
		print("Git pull successful")
	end
end

-- Create augroup for auto commands
local group = vim.api.nvim_create_augroup("org_autocommit", { clear = true })

-- Pull on read
vim.api.nvim_create_autocmd("BufReadPre", {
	-- Use vim.fn.expand to correctly resolve the home directory
	pattern = vim.fn.expand("$HOME") .. "/projects/org/**",
	callback = function()
		GitPull()
	end,
	group = group,
})

-- Commit and push on write
vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = vim.fn.expand("$HOME") .. "/projects/org/**",
	callback = function()
		GitCommitAndPush()
	end,
	group = group,
})

-- Auto-command to treat .svx files as markdown
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.svx",
	callback = function()
		vim.bo.filetype = "markdown"
	end,
})
