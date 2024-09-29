local M = {}

---@return string
M.default_preview_cmd = function()
    local os_used = vim.uv.os_uname().sysname
    if os_used == "Linux" then
        return "xdg-open"
    end
    if os_used == "Darwin" then
        return "open"
    end
    if os_used == "Windows_NT" then
        return "powershell.exe"
    end
    require("md-pdf.utils").log_error("Unkown System: " .. os_used)
end

local defaults = {
    margins = "1.5cm",
    --- Theme for the pdf document. `tango`, pygments are quite nice for white on white
    highlight = "tango",
    --- Generate a table of contents, on by default
    toc = true,
    --- The command to open the pdf with
    preview_cmd = M.default_preview_cmd,
    --- if true, then the markdown file is continuously converted on each write, even if the
    --- file viewer closed, e.g., firefox is "closed" once the document is opened in it.
    ignore_viewer_state = false,
    --- Specify font, `nil` uses the default font of the theme
    fonts = nil,
    --- Custom options passed to `pandoc` CLI call
    pandoc_user_args = nil,
    --- Path to output. Needs to be always relative, e.g.: "./", "../", "./out" or simply "out", but
    --- not absolute e.g.: "/"!
    output_path = "",
}

M.options = {}

function M.setup(options)
    M.options = vim.tbl_deep_extend("force", defaults, options or {})
end

return M
