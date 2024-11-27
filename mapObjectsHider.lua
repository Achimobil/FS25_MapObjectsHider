local modName = g_currentModName

MapObjectsHider = {}
MapObjectsHider.SPEC_TABLE_NAME = "spec_"..modName..".atm"
MapObjectsHider.Debug = true;


--- Print the given Table to the log
-- @param string text parameter Text before the table
-- @param table myTable The table to print
-- @param number maxDepth depth of print, default 2
function MapObjectsHider.DebugTable(text, myTable, maxDepth)
    if not MapObjectsHider.Debug then return end
    if myTable == nil then
        Logging.info("MapObjectsHiderDebug: " .. text .. " is nil");
    else
        Logging.info("MapObjectsHiderDebug: " .. text)
        DebugUtil.printTableRecursively(myTable,"_",0, maxDepth or 2);
    end
end

--- Print the text to the log. Example: MapObjectsHider.DebugText("Alter: %s", age)
-- @param string text the text to print formated
-- @param any ... format parameter
function MapObjectsHider.DebugText(text, ...)
    if not MapObjectsHider.Debug then return end
    Logging.info("MapObjectsHiderDebug: " .. string.format(text, ...));
end

function MapObjectsHider:loadMap(a)
    MapObjectsHider.DebugText("loadMap: %s", a)
end

addModEventListener(MapObjectsHider);