-- Found this helpful site for vim.loop handling
--  https://teukka.tech/vimloop.html

local uv = vim.loop
local utils = require("md-pdf.utils")

local M = {}
local results = {}
local default_config = {
    margins = "1.5cm",
    --- tango, pygments are quite nice for white on white
    highlight = "tango",
    --- Generate a table of contents, on by default
    toc = true,
}
local viewer_open = false
local function get_preview_command()
    local os_used = uv.os_uname().sysname
    if os_used == 'Linux' then return 'xdg-open' end
    if os_used == 'Darwin' then return 'open' end
    return 'powershell.exe'
end


function M.setup(config)
    if config == nil then
        return
    end
    for index, entry in pairs(config) do
        if utils.has_value(config, index) then
            default_config[index] = entry
        end
    end
end

function M.convert_md_to_pdf()
    if vim.bo.filetype ~= "markdown" then
        utils.log_error("Incorrect filetype " .. vim.bo.filetype .. " not supported!")
        return
    end
    --- name of current file
    local shortname = vim.fn.expand("%:t:r")
    --- Absolute path of current file
    local fullname = vim.api.nvim_buf_get_name(0)
    --- pdf path name
    local pdf_output_path = string.sub(fullname, 1, -3) .. "pdf"
    -- local stdin = uv.new_pipe()
    local stdout = uv.new_pipe()
    local stderr = uv.new_pipe()

    local function onread(err, data)
        if err then
            -- TODO handle err
            utils.log_error("ERROR: " .. tostring(err))
        end
        if data then
            local vals = vim.split(data, "\n")
            for _, d in pairs(vals) do
                if d ~= "" then
                    table.insert(results, d)
                end
            end
        end
    end

    local function print_out()
        local count = #results
        for i = 0, count do
            utils.log_info(results[i])
            results[i] = nil -- clear the table for next search
        end
    end

    local function open_doc()
        if viewer_open then
            return
        else
            viewer_open = true
        end
        zathura_handle = uv.spawn(get_preview_command(), {
            args = { pdf_output_path },
        }, function(code, signal) -- on exit
            viewer_open = false
            zathura_handle:close()
            utils.log_info("Document viewer closed!")
        end)
    end

    local pandoc_args = {
        "-V",
        "geometry:margin=" .. default_config.margins,
        fullname,
        "-o",
        pdf_output_path,
        "--highlight",
        default_config.highlight,
    }

    if default_config.toc then
        table.insert(pandoc_args, "--toc")
    end

    pandoc_handle = uv.spawn("pandoc", {
        args = pandoc_args,
        stdio = { nil, stdout, stderr },
    }, function(code, signal) -- on exit
        stdout:read_stop()
        stderr:read_stop()
        stdout:close()
        stderr:close()
        pandoc_handle:close()
        print_out()
        open_doc()
        utils.log_info("DOCUMENT CONVERSION COMPLETE")
    end)

    utils.log_info("process opened " .. tostring(pandoc_handle))

    uv.read_start(stdout, onread)
    uv.read_start(stderr, onread)
end

vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("md-pdf", { clear = true }),
    pattern = "*.md",
    callback = function()
        if not viewer_open then return end
        M.convert_md_to_pdf()
    end
})

return M
