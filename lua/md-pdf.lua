local uv = vim.loop

local M = {}

--- Absolute path of current file
local filepath = vim.fn.expand("%:p")

function M.convert_md_to_pdf()
  local output_handle = uv.spawn("./conv-pdf.sh",
    {
      args = { filepath },
      stdio = { nil, nil, nil },
    },
    nil
  )
end

vim.keymap.set("n", "<Space>,", M.convert_md_to_pdf)

return M
