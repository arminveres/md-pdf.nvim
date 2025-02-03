local M = {}

function M.has_value(tab, val)
    for index, value in pairs(tab) do
        if index == val then
            return true
        end
    end

    return false
end

M.log = {}

---@param str string Log Message
function M.log.info(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    pcall(vim.notify, "md-pdf: " .. str)
end

---@param str string Log Message
function M.log.warn(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    pcall(vim.notify, "md-pdf: " .. str, vim.log.levels.WARN)
end

---@param str string Log Message
function M.log.error(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    pcall(vim.notify, "md-pdf: " .. str, vim.log.levels.ERROR)
end

return M
