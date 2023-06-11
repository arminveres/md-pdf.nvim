local M = {}

function M.has_value(tab, val)
    for index, value in pairs(tab) do
        if index == val then
            return true
        end
    end

    return false
end

return M
