-- Found this helpful site for vim.loop handling
--  https://teukka.tech/vimloop.html

local uv = vim.loop
local utils = require("md-pdf.utils")
local config = require("md-pdf.config")

local M = {}
local results = {}

local viewer_open = false

function M.setup(options)
    config.setup(options)
end

local function get_preview_command()
    local preview_cmd = config.options.preview_cmd
    if type(preview_cmd) == "function" then
        return preview_cmd()
    end
    return preview_cmd
end

function M.convert_md_to_pdf()
    if vim.bo.filetype ~= "markdown" then
        utils.log_error("Incorrect filetype " .. vim.bo.filetype .. " not supported!")
        return
    end

    --- name of current file
    -- local shortname = vim.fn.expand("%:t:r")
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
        }, function(_, _) -- on exit
            viewer_open = false
            zathura_handle:close()
            utils.log_info("Document viewer closed!")
        end)
    end

    local pandoc_args = {
        "-V",
        "geometry:margin=" .. config.options.margins,
        fullname,
        "-o",
        pdf_output_path,
        "--highlight",
        config.options.highlight,
    }

    if config.options.toc then
        table.insert(pandoc_args, "--toc")
    end

    pandoc_handle = uv.spawn("pandoc", {
        args = pandoc_args,
        stdio = { nil, stdout, stderr },
    }, function(_, _) -- on exit
        ---@diagnostic disable-next-line: need-check-nil
        stdout:read_stop()
        ---@diagnostic disable-next-line: need-check-nil
        stderr:read_stop()
        ---@diagnostic disable-next-line: need-check-nil
        stdout:close()
        ---@diagnostic disable-next-line: need-check-nil
        stderr:close()
        pandoc_handle:close()
        print_out()
        open_doc()
        utils.log_info("DOCUMENT CONVERSION COMPLETE")
    end)

    utils.log_info("process opened " .. tostring(pandoc_handle))

    ---@diagnostic disable-next-line: param-type-mismatch
    uv.read_start(stdout, onread)
    ---@diagnostic disable-next-line: param-type-mismatch
    uv.read_start(stderr, onread)
end

local mdaugroup = vim.api.nvim_create_augroup("md-pdf", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
    group = mdaugroup,
    pattern = "*.md",
    callback = function()
        if not viewer_open then
            return
        end
        M.convert_md_to_pdf()
    end,
})

return M
