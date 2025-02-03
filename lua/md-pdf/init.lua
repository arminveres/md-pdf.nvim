---@diagnostic disable: undefined-field, need-check-nil

-- Found this helpful site for vim.loop handling
--  https://teukka.tech/vimloop.html

local config = require("md-pdf.config")
local utils = require("md-pdf.utils")
local log = utils.log

local M = {}
local viewer_open = false
local conv_started = false
local pdf_output_path = ""

---@param options md-pdf.config
function M.setup(options)
    config.setup(options)
end

--- @return string: preview command, which can be either a string or a function.
local function get_preview_command()
    local preview_cmd = config.options.preview_cmd
    if type(preview_cmd) == "function" then
        return preview_cmd()
    elseif type(preview_cmd) == "string" then
        return preview_cmd
    else
        log.error("Unknown preview command specified, return defaults")
        return config.default_preview_cmd()
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
        if not config.options.ignore_viewer_state then
            log.info("Document viewer closed!")
        end
    end)
end

--- Converts markdown file to pdf. If called a second time, the automatic conversion is stopped
function M.convert_md_to_pdf()
    if vim.bo.filetype ~= "markdown" then
        log.error("Filetype " .. vim.bo.filetype .. " not supported!")
        return
    end

    -- Get the absolute path of current file
    local fullname = vim.api.nvim_buf_get_name(0)
    -- split on slashes because of absolute
    local path_parts = vim.split(fullname, "/")
    -- get file name and change filetype
    local file_name = path_parts[#path_parts]
    local updated_file_name = string.sub(file_name, 1, -3) .. "pdf"
    -- remove file from table
    path_parts[#path_parts] = nil

    -- repeat with user specified path
    local config_paths = vim.split(config.options.output_path, "/")
    path_parts = vim.list_extend(path_parts, config_paths)

    -- create dir if necessary
    vim.fn.mkdir(table.concat(path_parts, "/"), "p")

    -- add updated filename
    path_parts[#path_parts + 1] = updated_file_name

    -- get a single string as a path
    pdf_output_path = table.concat(path_parts, "/")

    local pandoc_args = {
        "pandoc",
        "-V",
        "geometry:margin=" .. config.options.margins,
        fullname,
        "--output=" .. pdf_output_path,
        "--highlight-style=" .. config.options.highlight,
    }

    if config.options.pdf_engine then
        table.insert(pandoc_args, "--pdf-engine=" .. config.options.pdf_engine)
    end

    if config.options.toc then
        table.insert(pandoc_args, "--toc")
    end

    if config.options.fonts then
        local ftable = config.options.fonts
        if ftable.main_font then
            table.insert(pandoc_args, "-V")
            table.insert(pandoc_args, "mainfont:" .. ftable.main_font)
        end
        if ftable.sans_font then
            table.insert(pandoc_args, "-V")
            table.insert(pandoc_args, "sansfont:" .. ftable.sans_font)
        end
        if ftable.mono_font then
            table.insert(pandoc_args, "-V")
            table.insert(pandoc_args, "monofont:" .. ftable.mono_font)
        end
        if ftable.math_font then
            table.insert(pandoc_args, "-V")
            table.insert(pandoc_args, "mathfont:" .. ftable.math_font)
        end
    end

    if config.options.pandoc_user_args then
        for _, value in ipairs(config.options.pandoc_user_args) do
            for token in string.gmatch(value, "[^%s]+") do
                table.insert(pandoc_args, token)
            end
        end
    end

    -- Add courtesy warning in case of non-specified pdf engine
    if config.options.fonts then
        for _, value in ipairs(pandoc_args) do
            if string.gmatch(value, "[pdflatex]") then
                log.warn(
                    "When specifying custom fonts, you may encounter utf-8 error. Consider switching to another engine, e.g., lualatex"
                )
                break
            end
        end
    end

    log.info("Markdown to PDF conversion started...")
    vim.system(pandoc_args, { text = true }, function(obj)
        -- Early exit in case of error
        if obj.stderr ~= "" then
            log.error(obj.stderr)
            return
        end
        if obj.stdout ~= "" then
            log.info(obj.stdout)
        end
        log.info("Document conversion completed")
        open_doc()
        conv_started = true
    end)
end

local mdaugroup = vim.api.nvim_create_augroup("md-pdf", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
    group = mdaugroup,
    pattern = "*.md",
    callback = function()
        -- Skip auto conversion if we are considering the viewer state, which can be annoying
        -- with applications such as firefox.
        if not config.options.ignore_viewer_state and not viewer_open then
            return
        end
        -- Also skip auto conversion, if we have not yet initiated such conversion.
        if not conv_started then
            return
        end
        M.convert_md_to_pdf()
    end,
})

return M
