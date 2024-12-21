--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

Utility = Utility or {}

--- Get elapsed seconds between given date and FS19 release date
-- @param integer? year
-- @param integer? month
-- @param integer? day
-- @param integer? hour
-- @param integer? minute
-- @param integer? second
-- @return any second date time diff in seconds
function Utility.getTimestampAt(year, month, day, hour, minute, second)
    year = year or 0
    month = month or 0
    day = day or 0
    hour = hour or 0
    minute = minute or 0
    second = second or 0
    return getDateDiffSeconds(year, month, day, hour, minute, second, 2018, 11, 20, 0, 0, 0)
end

--- Get elapsed seconds since FS19 release date
-- @return any time stamp
function Utility.getTimestamp()
    local date = getDate("%Y-%m-%d_%H-%M-%S")
    local year, month, day, hour, minute, second = date:match("(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)-(%d%d)")
    return Utility.getTimestampAt(tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(minute), tonumber(second))
end
