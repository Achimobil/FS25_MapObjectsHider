--[[
--DE--
Teil des Map Object Hider für den LS22 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the LS22 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.2.0.0 of 01.01.2023
]]

---@class DebugUtility
DebugUtility = DebugUtility or {}

--- Render a table (for debugging purpose)
-- @param number posX
-- @param number posY
-- @param number textSize
-- @param table inputTable
-- @param integer|nil maxDepth
-- @param boolean|nil hideFunc
function DebugUtility.renderTable(posX, posY, textSize, inputTable, maxDepth, hideFunc)
    inputTable = inputTable or {tableIs = "nil"}
    hideFunc = hideFunc or false
    maxDepth = maxDepth or 2

    local function renderTableRecursively(x, t, depth, i)
        if depth >= maxDepth then
            return i
        end
        for k, v in pairs(t) do
            local vType = type(v)
            if not hideFunc or vType ~= "function" then
                local offset = i * textSize * 1.05
                setTextAlignment(RenderText.ALIGN_RIGHT)
                renderText(x, posY - offset, textSize, tostring(k) .. " :")
                setTextAlignment(RenderText.ALIGN_LEFT)
                if vType ~= "table" then
                    renderText(x, posY - offset, textSize, " " .. tostring(v))
                end
                i = i + 1
                if vType == "table" then
                    i = renderTableRecursively(x + textSize * 1.8, v, depth + 1, i)
                end
            end
        end
        return i
    end

    local i = 0
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
    textSize = getCorrectTextSize(textSize)
    for k, v in pairs(inputTable) do
        local vType = type(v)
        if not hideFunc or vType ~= "function" then
            local offset = i * textSize * 1.05
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(posX, posY - offset, textSize, tostring(k) .. " :")
            setTextAlignment(RenderText.ALIGN_LEFT)
            if vType ~= "table" then
                renderText(posX, posY - offset, textSize, " " .. tostring(v))
            end
            i = i + 1
            if vType == "table" then
                i = renderTableRecursively(posX + textSize * 1.8, v, 1, i)
            end
        end
    end
end