local uv = vim.loop

local M = {}
local results = {}


function M.setup(config)
  if config == nil then
    vim.keymap.set("n", "<Space>,", M.convert_md_to_pdf)
  else
    config()
  end
end

function M.convert_md_to_pdf()
  --- Absolute path of current file
  local filepath = vim.fn.expand("%:p")
  local convpath = debug.getinfo(1, "S").source:sub(2):match("(.*/)"):sub(1, -5) .. "conv-pdf.sh"
  -- local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local function onread(err, data)
    if err then
      -- TODO handle err
      print('ERROR: ', err)
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
      print(results[i])
      results[i] = nil -- clear the table for next search
    end
  end

  handle = uv.spawn(convpath,
    {
      args = { filepath },
      stdio = { nil, stdout, stderr },
    },
    function(code, signal) -- on exit
      stdout:read_stop()
      stderr:read_stop()
      stdout:close()
      stderr:close()
      handle:close()
      print_out()
      -- print("exit code", code)
      -- print("exit signal", signal)
    end)

  print("process opened", handle)

  uv.read_start(stdout, onread)
  uv.read_start(stderr, onread)
end

return M
