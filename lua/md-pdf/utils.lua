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
    if type(str) ~= "string" then
        str = tostring(str)
    end
    pcall(vim.notify,"md-pdf: " .. str, vim.log.levels.ERROR)
end

function M.log_info(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    pcall(vim.notify,"md-pdf: " .. str)
end

return M
