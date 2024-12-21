--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

StringUtility = StringUtility or {}

--- Split a string
-- @param string s
-- @param string sep
-- @return table fields
function StringUtility.split(s, sep)
    sep = sep or ":"
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    s:gsub(
        pattern,
        function(c)
            fields[#fields + 1] = c
        end
    )
    return fields
end