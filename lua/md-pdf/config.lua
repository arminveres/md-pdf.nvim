local M = {}

---@return string: Command that will open the pdf
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
    require("md-pdf.utils").log.error("Unkown System: " .. os_used)
end

---@class md-pdf.config
local defaults = {
    ---@type string
    margins = "1.5cm",
    ---@type string Theme for the pdf document. `tango`, pygments are quite nice for white on white
    highlight = "tango",
    ---@type boolean Generate a table of contents, on by default
    toc = true,
    ---@type function The command to open the pdf with
    preview_cmd = M.default_preview_cmd,
    ---@type boolean if true, then the markdown file is continuously converted on each write,
    ---even if the file viewer closed, e.g., firefox is "closed" once the document is opened in it.
    ignore_viewer_state = false,
    ---@type table | nil
    -- Specify font, `nil` uses the default font of the theme
    fonts = nil,
    ---@type any Custom options passed to `pandoc` CLI call
    pandoc_user_args = nil,
    ---@type string Path to output. Needs to be always relative, e.g.: "./", "../", "./out" or
    ---simply "out", but not absolute e.g.: "/"!
    output_path = "",
    ---@type string PDF converter engine
    pdf_engine = "pdflatex",
}

---@class md-pdf.config
M.options = {}

---@param options md-pdf.config
function M.setup(options)
    M.options = vim.tbl_deep_extend("force", defaults, options or {})
end

return M
