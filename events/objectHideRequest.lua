--[[
--DE--
Teil des Map Object Hider für den LS22 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the LS22 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.2.0.0 of 01.01.2023
]]

ObjectHideRequestEvent = {}
local ObjectHideRequestEvent_mt = Class(ObjectHideRequestEvent, Event)

InitEventClass(ObjectHideRequestEvent, "ObjectHideRequestEvent")

-- @return table
function ObjectHideRequestEvent.emptyNew()
    local o = Event.new(ObjectHideRequestEvent_mt)
    o.className = "ObjectHideRequestEvent"
    return o
end

-- @param objectIndex string
-- @return table
function ObjectHideRequestEvent.new(objectIndex, onlyDecollide)
    local o = ObjectHideRequestEvent.emptyNew()
    o.objectIndex = objectIndex
    o.onlyDecollide = onlyDecollide
    return o
end

-- @param streamId integer
function ObjectHideRequestEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.objectIndex)
    streamWriteBool(streamId, self.onlyDecollide)
end

-- @param streamId integer
-- @param connection Connection
function ObjectHideRequestEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self.onlyDecollide = streamReadBool(streamId)
    self:run(connection)
end

-- @param connection Connection
function ObjectHideRequestEvent:run(connection)
    if g_server ~= nil then
        MapObjectsHider:hideObject(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode), nil, g_currentMission.userManager:getUserByConnection(connection):getNickname(), self.onlyDecollide)
    end
end

-- @param objectId integer
function ObjectHideRequestEvent.sendToServer(objectId, onlyDecollide)
    MapObjectsHider.DebugText("ObjectHideRequestEvent.sendToServer(%s, %s)", objectId, onlyDecollide);
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ObjectHideRequestEvent.new(EntityUtility.nodeToIndex(objectId, MapObjectsHider.mapNode), onlyDecollide))
    end
end
