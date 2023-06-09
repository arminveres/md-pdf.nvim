local uv = vim.loop

local M = {}

function M.setup()
  vim.keymap.set("n", "<Space>,", M.convert_md_to_pdf)
end

function M.convert_md_to_pdf()
  --- Absolute path of current file
  local filepath = "./" .. vim.fn.expand("%:p")
  local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()
  local output_handle = uv.spawn("./conv-pdf.sh",
    {
      args = { filepath },
      stdio = { stdin, stdout, stderr },
    },
    function(code, signal) -- on exit
      stdout:close()
      stderr:close()
      -- handle:close()
      print("exit code", code)
      print("exit signal", signal)
    end)

  print("process opened", handle)


  uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if data then
      print("stdout chunk", stdout, data)
    else
      print("stdout end", stdout)
    end
  end)

  uv.read_start(stderr, function(err, data)
    assert(not err, err)
    if data then
      print("stderr chunk", stderr, data)
    else
      print("stderr end", stderr)
    end
  end)
end

return M
