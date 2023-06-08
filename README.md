# Markdown to PDF

A very simple and easy plugin to convert open markdown files to PDFs and open them it to the side.

## Installation

Currently you can just put it into `lazy` or `packer` and require it at some point.

```lua
'arminveres/md-pdf'
---
require('md-pdf)
```

## Usage

Default mapping, `<leader>,`, opens a view.

## Requirements

Currently only tested on Linux (Fedora Workstation 38)

- PDF Viewer, uses `xdg-open`
- `pandoc` for conversion

## TODO

- [ ] Don't open new window if one is already open
- [ ] Add configuration setup
- Platform support
  - [ ] Windows
