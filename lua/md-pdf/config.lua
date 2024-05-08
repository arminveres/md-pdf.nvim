local uv = vim.loop

local M = {}

local defaults = {
    margins = "1.5cm",
    --- tango, pygments are quite nice for white on white
    highlight = "tango",
    --- Generate a table of contents, on by default
    toc = true,
    --- The command to open the pdf with
    --- @type string | function
    preview_cmd = function()
        local os_used = uv.os_uname().sysname
        if os_used == "Linux" then
            return "xdg-open"
        end
        if os_used == "Darwin" then
            return "open"
        end
        -- assume the other OS is windows for now
        return "powershell.exe"
    end,
}

M.options = {}

function M.setup(options)
    M.options = vim.tbl_deep_extend("force", defaults, options or {})
end

return M
