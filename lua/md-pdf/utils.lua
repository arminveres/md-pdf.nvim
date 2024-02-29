local M = {}

function M.has_value(tab, val)
    for index, value in pairs(tab) do
        if index == val then
            return true
        end
    end

    return false
end

function M.log_error(str)
    pcall(vim.notify, str, vim.log.levels.ERROR)
end

function M.log_info(str)
    pcall(vim.notify, str)
end

return M
