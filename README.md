# Markdown to PDF

A very simple and easy plugin to convert open markdown files to PDFs and open them it to the side.

## Installation

Currently you can just put it into `lazy` or `packer` and require it at some point.

```lua
'arminveres/md-pdf'
---
require('md-pdf').setup() -- default mapping
require('md-pdf').setup(
  function()
    local mdfpdf = require('md-pdf')
    vim.keymap.set("n", "<Space>,", mdpdf.convert_md_to_pdf)
  end
) -- default mapping
```

## Usage

Default mapping, `<leader>,`, opens a view.

## Requirements

Currently only tested on Linux (Fedora Workstation 38)

- PDF Viewer, uses `xdg-open` on Linux, `open` on Mac and `powershell` on Windows
- [`pandoc`](https://pandoc.org/installing.html) for conversion, also probably some TeX distribution
  with `pdflatex` included.

## TODO

- [ ] Migrate fully to lua
- [ ] Don't open new window if one is already open
- [ ] Add configuration setup
- Platform support
  - [ ] Windows, see #1
