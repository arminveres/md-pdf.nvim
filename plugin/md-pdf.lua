vim.api.nvim_create_user_command("MdPreview", function(arg)
    return require("md-pdf").convert_md_to_pdf()
end, {})
