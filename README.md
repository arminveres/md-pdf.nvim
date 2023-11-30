# Markdown to PDF

> [!NOTE]
> Pull requests are welcome!

> [!WARNING]
> This plugin is still very early in its development, so expect bugs and if possible report them here!
> Thanks and enjoy.

A very simple and easy plugin to convert open markdown files to PDFs and open them it to the side.

![image](https://github.com/arminveres/md-pdf.nvim/assets/45210978/0c9cefb4-43b0-4cb5-8cb6-4b74802d7838)

## Features

- Preview markdown documents easily on Linux, Mac, Windows or just define a custom preview command!
- Generate PDFs out of markdown
- Lightweight ~200 loc fully lua written plugin
- auto-generate on save, don't reopen new viewer

## Installation

Currently you can just put it into `lazy` or `packer` and require it at some point.

### Lazy

```lua
{
    'arminveres/md-pdf.nvim',
    branch = 'main', -- you can assume that main is somewhat stable until releases will be made
    lazy = true,
    keys = {
        {
            "<leader>,",
            function()
                require("md-pdf").convert_md_to_pdf()
            end,
            desc = "Markdown preview",
        },
    },
    opts = {},
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
  --- Define a custom preview command, enabling hooks and other custom logic
  preview_cmd = function() return 'firefox' end
})

-- setup mapping
vim.keymap.set("n", "<Space>,", function()
    require('md-pdf').convert_md_to_pdf()
end)
```

## Requirements

> [!WARNING]
> The plugin currently only recognizes the document being open on Zathura.
>
> Tested on Windows 10, MacOS 13, and Linux (Fedora Workstation 38)

- neovim >= 9, didn't test below that.
- PDF Viewer, uses `xdg-open` on Linux, `open` on Mac and `powershell` on Windows
- [`pandoc`](https://pandoc.org/installing.html) for conversion, also probably some TeX distribution
  with `pdflatex` included.

## Why

I have often found myself wanting to see my markdown files as a PDF, for which I usually created a
`Makefile` which converted the files through `pandoc`.

After having done it a few times it became repetitive and I thought to myself, why not just create a
plugin that does exactly that in my favorite text editor.
And tada, here it is! Enjoy :D

## TODO

- change file viewed on file change
- exit viewer if file left/buffer changed, or make it configurable
