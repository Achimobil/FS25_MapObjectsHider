--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

---@alias Array table<integer, any> Table with numeric indexes only, always ordered and sequential

--- Array utilities class built with performances in mind (with 'array' we mean tables with numeric indexes only, always ordered and sequential)
ArrayUtility = ArrayUtility or {}

---Remove matching elements from an array
-- @param table array Array
-- @param function removeFunc fun(array: Array, index: number, moveAt: number): boolean | "function(array, index, moveAt) local element = array[index] return true end"
-- @return number removedCount count of removed elements
function ArrayUtility.remove(array, removeFunc)
    local removedCount = 0
    local moveAt, length = 1, #array
    for index = 1, length do
        if removeFunc(array, index, moveAt) then
            array[index] = nil
            removedCount = removedCount + 1
        else
            -- move kept element's value to moveAt's position, if it's not already there
            if (index ~= moveAt) then
                array[moveAt] = array[index]
                array[index] = nil
            end
            -- increment position of where we'll place the next kept value
            moveAt = moveAt + 1
        end
    end
    return removedCount
end

---Remove element at the given index from an array
-- @param table array Array
-- @param number index
function ArrayUtility.removeAt(array, index)
    ArrayUtility.remove(
        array,
        function(_, i)
            return index == i
        end
    )
end
