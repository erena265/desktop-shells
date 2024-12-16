local Variable = require("astal").Variable

local M = {}

function M.src(path)
    local str = debug.getinfo(2, "S").source:sub(2)
    local src = str:match("(.*/)") or str:match("(.*\\)") or "./"
    return src .. path
end

---@generic T, R
---@param arr T[]
---@param func fun(T, integer): R
---@return R[]
function M.map(arr, func)
    local new_arr = {}
    for i, v in ipairs(arr) do
        new_arr[i] = func(v, i)
    end
    return new_arr
end

M.date = Variable(""):poll(1000, "date")

return M
