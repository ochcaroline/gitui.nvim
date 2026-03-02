--- @module gitui
local M = {}

local default_config = {
	width_percent = 0.9,
	height_percent = 0.9,
	border = "rounded",
}

local config = vim.deepcopy(default_config)

local state = {
	bif = nil,
	win = nil,
	term_job_id = nil,
}

local function calculate_dimensions()
	local width = math.floor(vim.o.columns * config.width_percent)
	local height = math.floor(vim.o.lines * config.height_percent)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	return {
		width = width,
		height = height,
		row = row,
		col = col,
	}
end

local function resize_window()
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return
	end
	local dims = calculate_dimensions()
	vim.api.nvim_win_set_config(state.win, {
		relative = "editor",
		width = dims.width,
		height = dims.height,
		row = dims.row,
		col = dims.col,
	})
end

local function close_window()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end

	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_buf_delete(state.buf, { force = true })
	end

	state.win = nil
	state.buf = nil
	state.term_job_id = nil
end

local function is_gitui_available()
	return vim.fn.executable("gitui") == 1
end

local function is_git_repo()
	local git_dir = vim.fn.systemlist("git rev-parse --git-dir 2>/dev/null")[1]
	return vim.v.shell_error == 0 and git_dir ~= nil
end

function M.open()
	if not is_gitui_available() then
		vim.notify("gitui is not installed or not in path", vim.log.levels.ERROR)
	end
	if not is_git_repo() then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
	end

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_set_current_win(state.win)
		return
	end

	state.buf = vim.api.nvim_create_buf(false, true)

	local dims = calculate_dimensions()

	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = dims.width,
		height = dims.height,
		row = dims.row,
		col = dims.col,
		style = "minimal",
		border = config.border,
	})

	vim.bo[state.buf].bufhidden = "hide"
	vim.bo[state.buf].filetype = "gitui"

	state.term_job_id = vim.fn.termopen("gitui", {
		on_exit = function()
			close_window()
		end,
	})

	vim.cmd("startinsert")

	vim.api.nvim_create_autocmd("VimResized", {
		buffer = state.buf,
		callback = resize_window,
		desc = "Resize gitui floating window on Vim resize",
	})
end

function M.close()
	close_window()
end

function M.toggle()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		M.close()
	else
		M.open()
	end
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", default_config, opts or {})

	vim.api.nvim_create_user_command("GitUI", function()
		M.open()
	end, { desc = "Open GitUI in floating window" })

	vim.api.nvim_create_user_command("GitUIToggle", function()
		M.toggle()
	end, { desc = "Toggle GitUI floating window" })
end

return M
