-- Found this helpful site for vim.loop handling
--  https://teukka.tech/vimloop.html

local uv = vim.loop
local utils = require("md-pdf.utils")

local M = {}
local results = {}
local default_config = {
    margins = "1cm",
    --- tango, pygments are quite nice for white on white
    highlight = "tango",
    --- Generate a table of contents, on by default
    toc = true,
}
local viewer_open = false

function M.setup(config)
    for index, entry in pairs(config) do
        if utils.has_value(config, index) then
            default_config[index] = entry
        end
    end
end

function M.convert_md_to_pdf()
    --- name of current file
    local shortname = vim.fn.expand("%:t:r")
    --- Absolute path of current file
    local fullname = vim.api.nvim_buf_get_name(0)
    -- local stdin = uv.new_pipe()
    local stdout = uv.new_pipe()
    local stderr = uv.new_pipe()

    local function onread(err, data)
        if err then
            -- TODO handle err
            print("ERROR: ", err)
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
            print(results[i])
            results[i] = nil -- clear the table for next search
        end
    end

    local function open_doc()
        if viewer_open then
            return
        else
            viewer_open = true
        end
        zathura_handle = uv.spawn("zathura", {
            args = { string.sub(fullname, 1, -3) .. "pdf" },
        }, function(code, signal) -- on exit
            viewer_open = false
            zathura_handle:close()
            print('Document viewer closed!')
        end)
    end

    local pandoc_args = {
        "-V",
        "geometry:margin=" .. default_config.margins,
        fullname,
        "-o",
        string.format("%s.pdf", shortname),
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
        print("DOCUMENT CONVERSION COMPLETE")
    end)

    print("process opened", pandoc_handle)

    uv.read_start(stdout, onread)
    uv.read_start(stderr, onread)
end

return M
