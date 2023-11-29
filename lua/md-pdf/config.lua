local M = {}

local defaults = {
	margins = "1.5cm",
	--- tango, pygments are quite nice for white on white
	highlight = "tango",
	--- Generate a table of contents, on by default
	toc = true,
}

M.options = {}

function M.setup(options)
	M.options = vim.tbl_deep_extend("force", defaults, options or {})
end

return M
