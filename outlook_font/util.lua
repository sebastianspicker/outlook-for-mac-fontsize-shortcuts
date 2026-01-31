local M = {}

local function is_array(t)
    if type(t) ~= "table" then
        return false
    end
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" then
            return false
        end
        count = count + 1
    end
    return count == #t
end

function M.deep_copy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[M.deep_copy(k)] = M.deep_copy(v)
    end
    return out
end

function M.deep_merge(dst, src)
    if type(dst) ~= "table" then
        dst = {}
    end
    if type(src) ~= "table" then
        return dst
    end

    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" and (not is_array(v)) and (not is_array(dst[k])) then
            dst[k] = M.deep_merge(dst[k], v)
        else
            dst[k] = M.deep_copy(v)
        end
    end
    return dst
end

function M.strip_jsonc(raw)
    if type(raw) ~= "string" then
        return raw
    end

    local out = {}
    local i = 1
    local len = #raw

    local in_string = false
    local escape = false

    local in_line_comment = false
    local in_block_comment = false

    while i <= len do
        local ch = raw:sub(i, i)
        local next_ch = (i < len) and raw:sub(i + 1, i + 1) or ""

        if in_line_comment then
            if ch == "\n" then
                in_line_comment = false
                table.insert(out, ch)
            end
            i = i + 1
        elseif in_block_comment then
            if ch == "*" and next_ch == "/" then
                in_block_comment = false
                i = i + 2
            else
                i = i + 1
            end
        elseif in_string then
            table.insert(out, ch)
            if escape then
                escape = false
            elseif ch == "\\" then
                escape = true
            elseif ch == '"' then
                in_string = false
            end
            i = i + 1
        else
            if ch == '"' then
                in_string = true
                table.insert(out, ch)
                i = i + 1
            elseif ch == "/" and next_ch == "/" then
                in_line_comment = true
                i = i + 2
            elseif ch == "/" and next_ch == "*" then
                in_block_comment = true
                i = i + 2
            else
                table.insert(out, ch)
                i = i + 1
            end
        end
    end

    return table.concat(out)
end

return M
