# Markdown to PDF

> **Warning**: This plugin is still very early in its development, so expect bugs and if possible
> report them here! Thanks and enjoy.

A very simple and easy plugin to convert open markdown files to PDFs and open them it to the side.

![image](https://github.com/arminveres/md-pdf.nvim/assets/45210978/0c9cefb4-43b0-4cb5-8cb6-4b74802d7838)

## Installation

Currently you can just put it into `lazy` or `packer` and require it at some point.

### Lazy

```lua
{
    'arminveres/md-pdf',
    branch = 'main', -- you can assume that main is somewhat stable until releases will be made
    lazy = true,
    keys = { { '<leader>,' } },
    config = function()
        require('md-pdf').setup() -- default options, or see down below for further options
        vim.keymap.set("n", "<leader>,", require('md-pdf').convert_md_to_pdf, { desc = "Markdown preview" })
    end
}
```

## Configuration

```lua
require('md-pdf').setup() -- default options, or
require('md-pdf').setup({
  --- Set margins around document
  margins = "1.5cm",
  --- tango, pygments are quite nice for white on white
  highlight = "tango",
  --- Generate a table of contents, on by default
  toc = true,
})

-- setup mapping
vim.keymap.set("n", "<Space>,", function()
    require('md-pdf').convert_md_to_pdf()
end)
```

## Requirements

Currently only tested on Linux (Fedora Workstation 38)

- PDF Viewer, uses `xdg-open` on Linux, `open` on Mac and `powershell` on Windows
- [`pandoc`](https://pandoc.org/installing.html) for conversion, also probably some TeX distribution
  with `pdflatex` included.

## TODO

- change file viewed on file change
