-- Found this helpful site for vim.loop handling
--  https://teukka.tech/vimloop.html

local utils = require("md-pdf.utils")
local config = require("md-pdf.config")

local M = {}
local viewer_open = false
local pdf_output_path = ""

function M.setup(options)
    config.setup(options)
end

--- Returns the preview command, which can be either a string or a function.
local function get_preview_command()
    local preview_cmd = config.options.preview_cmd
    if type(preview_cmd) == "function" then
        return preview_cmd()
    elseif type(preview_cmd) == "string" then
        return preview_cmd
    else
        utils.log_error("Unknown preview command specified, return defaults")
        return config.default_preview_cmd
    end
end

--- Opens the previewer
local function open_doc()
    if viewer_open then
        return
    else
        viewer_open = true
    end

    vim.system({ get_preview_command(), pdf_output_path }, { text = true }, function()
        viewer_open = false
        utils.log_info("Document viewer closed!")
    end)
end

function M.convert_md_to_pdf()
    if vim.bo.filetype ~= "markdown" then
        utils.log_error("Filetype " .. vim.bo.filetype .. " not supported!")
        return
    end

    --- Absolute path of current file
    local fullname = vim.api.nvim_buf_get_name(0)
    --- pdf path name
    pdf_output_path = string.sub(fullname, 1, -3) .. "pdf"

    local pandoc_args = {
        "pandoc",
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

    vim.system(pandoc_args, { text = true }, function(obj)
        -- Early exit in case of error
        if obj.stderr ~= "" then
            utils.log_error(obj.stderr)
            return
        end
        if obj.stdout ~= "" then
            utils.log_info(obj.stdout)
        end
        open_doc()
        utils.log_info("Document conversion completed")
    end)
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
