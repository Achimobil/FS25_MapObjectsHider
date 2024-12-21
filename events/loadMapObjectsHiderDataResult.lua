--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

LoadMapObjectsHiderDataResult = {}
LoadMapObjectsHiderDataResult_mt = Class(LoadMapObjectsHiderDataResult, Event)
InitEventClass(LoadMapObjectsHiderDataResult, "LoadMapObjectsHiderDataResult")

---Create instance of Event class
-- @return table self instance of class event
function LoadMapObjectsHiderDataResult.emptyNew()
    local self = Event.new(LoadMapObjectsHiderDataResult_mt)
    return self
end


---Create new instance of event
-- @return table self instance of class event
function LoadMapObjectsHiderDataResult.new()
    MapObjectsHider.DebugText("LoadMapObjectsHiderDataResult.new");
    local self = LoadMapObjectsHiderDataResult.emptyNew()
    return self
end

---send event
-- @param integer streamId
-- @param Connection connection
function LoadMapObjectsHiderDataResult:writeStream(streamId, connection)
    MapObjectsHider.DebugText("LoadMapObjectsHiderDataResult:writeStream");

    local objectsCount = #MapObjectsHider.hiddenObjects
    local collisions = {}
    streamWriteInt32(streamId, objectsCount)
    for i = 1, objectsCount, 1 do
        local obj = MapObjectsHider.hiddenObjects[i]
        for colIndex, col in pairs(obj.collisions) do
            if col.index == nil then
                Logging.warning("[%s] index of collision %s of object %s is nil, do not send to client", MapObjectsHider.modName, colIndex, obj.index);
            else
                table.insert(collisions, col.index)
            end
        end
        streamWriteString(streamId, obj.index)
        streamWriteBool(streamId, obj.onlyDecollide)
    end

    local collisionsCount = #collisions;
    streamWriteInt32(streamId, collisionsCount);

    for i = 1, collisionsCount, 1 do
        streamWriteString(streamId, collisions[i])
    end
end

---receive event
-- @param integer streamId
-- @param Connection connection
function LoadMapObjectsHiderDataResult:readStream(streamId, connection)
    MapObjectsHider.DebugText("LoadMapObjectsHiderDataResult:readStream");

    local objectsCount = streamReadInt32(streamId)
    for i = 1, objectsCount, 1 do
        local objIndex = streamReadString(streamId)
        local onlyDecollide = streamReadBool(streamId)
        if not onlyDecollide then
            MapObjectsHider:hideNode(EntityUtility.indexToNode(objIndex, MapObjectsHider.mapNode))
        end
    end
    local collisionsCount = streamReadInt32(streamId);
    for i = 1, collisionsCount, 1 do
        local colIndex = streamReadString(streamId);
        local colNodeId = EntityUtility.indexToNode(colIndex, MapObjectsHider.mapNode);
        if colNodeId ~= nil then
            MapObjectsHider:decollideNode(colNodeId)
        else
            Logging.warning("[%s] Can't find collision node for collision index '%s' in LoadMapObjectsHiderDataResult readStream. Collision %s of %s", MapObjectsHider.modName, colIndex, i, collisionsCount);
        end
    end

    self:run(connection)
end

---run event
-- @param Connection connection
function LoadMapObjectsHiderDataResult:run(connection)
    MapObjectsHider.DebugText("LoadMapObjectsHiderDataResult:run");
end
