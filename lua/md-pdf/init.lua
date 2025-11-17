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

---@param quoted_text string|nil
---@return string|nil
local function trim_quotes(quoted_text)
    if not quoted_text then
        return nil
    end
    quoted_text = vim.trim(quoted_text)
    local first = quoted_text:sub(1, 1)
    local last = quoted_text:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
        return quoted_text:sub(2, -2)
    end
    return quoted_text
end

---@param fullname string
---@param file_dir string
---@return string|nil
local function resolve_header_logo_path(fullname, file_dir)
    local ok, lines = pcall(vim.fn.readfile, fullname)
    if not ok or #lines == 0 then
        return nil
    end
    if not lines[1]:match("^%-%-%-$") then
        return nil
    end

    for i = 2, #lines do
        local line = lines[i]
        if line:match("^%-%-%-$") then
            break
        end
        local key, value = line:match("^([%w_%-%:]+)%s*:%s*(.+)$")
        if key then
            key = vim.trim(key)
            if key == "logo" or key == "titlegraphic" then
                value = trim_quotes(value)
                if value and value ~= "" then
                    if value:sub(1, 1) == "~" then
                        value = vim.fn.expand(value)
                    elseif not vim.startswith(value, "/") then
                        value = vim.fs.normalize(file_dir .. "/" .. value)
                    end
                    return value
                end
            end
        end
    end
end

local function detokenize_path(path)
    if not path then
        return nil
    end
    return "\\detokenize{" .. path .. "}"
end

---@param fullname string
---@param file_dir string
---@return string[]
---@return string|nil
local function build_title_page_args(fullname, file_dir)
    if not config.options.title_page then
        return {}, nil
    end

    local pandoc_flags = {
        "-V",
        "classoption=titlepage",
    }
    local header_lines = {}
    local header_include
    local logo_path = resolve_header_logo_path(fullname, file_dir)

    if logo_path then
        table.insert(header_lines, [[\usepackage{graphicx}]])
        table.insert(header_lines, [[\usepackage{titling}]])
        table.insert(
            header_lines,
            string.format(
                [[\pretitle{\begin{center}\includegraphics[width=0.4\textwidth]{%s}\\[1em]}]],
                detokenize_path(logo_path)
            )
        )
        table.insert(header_lines, [[\posttitle{\par\end{center}}]])
    end

    if config.options.toc then
        table.insert(header_lines, [[\usepackage{etoolbox}]])
        table.insert(header_lines, [[\pretocmd{\tableofcontents}{\clearpage}{}{}]])
        table.insert(header_lines, [[\apptocmd{\tableofcontents}{\clearpage}{}{}]])
    end

    if #header_lines > 0 then
        local include_path = vim.fn.tempname() .. ".tex"
        local ok, err = pcall(vim.fn.writefile, header_lines, include_path)
        if ok then
            header_include = include_path
            table.insert(pandoc_flags, "--include-in-header=" .. include_path)
        else
            log.warn("Failed to prepare title page header include: " .. tostring(err))
        end
    end

    return pandoc_flags, header_include
end

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
    local file_dir = vim.fn.fnamemodify(fullname, ":h")
    local file_name_without_ext = vim.fn.fnamemodify(fullname, ":t:r")
    local updated_file_name = file_name_without_ext .. ".pdf"

    -- create dir if necessary
    local output_dir = file_dir .. "/" .. config.options.output_path
    vim.fn.mkdir(output_dir, "p")

    -- get a single string as a path
    pdf_output_path = output_dir .. "/" .. updated_file_name

    local pandoc_args = {
        "pandoc",
        "--standalone",
        "-V",
        "geometry:margin=" .. config.options.margins,
        fullname,
        "--output=" .. pdf_output_path,
        "--syntax-highlighting=" .. config.options.highlight,
        "--resource-path=" .. file_dir,
    }

    local header_include
    if config.options.title_page then
        local title_page_args
        title_page_args, header_include = build_title_page_args(fullname, file_dir)
        vim.list_extend(pandoc_args, title_page_args)
    end

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
        if header_include then
            pcall(vim.loop.fs_unlink, header_include)
        end
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
