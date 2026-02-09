local M = {}

local function children_of(node)
    if not node then
        return {}
    end
    return node:attributeValue("AXChildren") or {}
end

function M.find_first_by_role(root, role)
    if not root then
        return nil
    end
    if root:attributeValue("AXRole") == role then
        return root
    end
    for _, child in ipairs(children_of(root)) do
        local found = M.find_first_by_role(child, role)
        if found then
            return found
        end
    end
    return nil
end

function M.find_static_text(root, substring)
    if not root then
        return nil
    end
    if root:attributeValue("AXRole") == "AXStaticText" then
        local value = root:attributeValue("AXValue") or root:attributeValue("AXTitle") or ""
        if string.find(value, substring, 1, true) then
            return root
        end
    end
    for _, child in ipairs(children_of(root)) do
        local found = M.find_static_text(child, substring)
        if found then
            return found
        end
    end
    return nil
end

function M.find_ancestor_by_role(node, role)
    local current = node
    while current do
        if current:attributeValue("AXRole") == role then
            return current
        end
        current = current:attributeValue("AXParent")
    end
    return nil
end

function M.find_button_group_near_labels(root, label_texts)
    for _, label in ipairs(label_texts or {}) do
        local elem = M.find_static_text(root, label)
        if elem then
            local grp = elem
            while grp do
                local btns = {}
                for _, child in ipairs(children_of(grp)) do
                    if child:attributeValue("AXRole") == "AXButton" then
                        table.insert(btns, child)
                    end
                end
                if #btns >= 2 then
                    return btns
                end
                grp = grp:attributeValue("AXParent")
            end
        end
    end
    return nil
end

-- Returns the button for "larger" or "smaller" by matching AXTitle/AXValue to labels; nil if ambiguous.
function M.button_by_size_label(buttons, larger_text, smaller_text, want_larger)
    if not buttons or #buttons < 2 or not larger_text or not smaller_text then
        return nil
    end
    local larger_btn, smaller_btn
    for _, btn in ipairs(buttons) do
        local title = (btn:attributeValue("AXTitle") or btn:attributeValue("AXValue") or ""):gsub("^%s*(.-)%s*$", "%1")
        if string.find(title, larger_text, 1, true) then
            larger_btn = btn
        elseif string.find(title, smaller_text, 1, true) then
            smaller_btn = btn
        end
    end
    if want_larger then
        return larger_btn
    end
    return smaller_btn
end

return M
