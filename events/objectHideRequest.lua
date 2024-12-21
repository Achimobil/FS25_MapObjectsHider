--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

ObjectHideRequestEvent = {}
local ObjectHideRequestEvent_mt = Class(ObjectHideRequestEvent, Event)

InitEventClass(ObjectHideRequestEvent, "ObjectHideRequestEvent")

---Create instance of Event class
-- @return table self instance of class event
function ObjectHideRequestEvent.emptyNew()
    local o = Event.new(ObjectHideRequestEvent_mt)
    o.className = "ObjectHideRequestEvent"
    return o
end

---Create new instance of event
-- @param integer objectIndex
-- @param boolean onlyDecollide
-- @return table self instance of class event
function ObjectHideRequestEvent.new(objectIndex, onlyDecollide)
    local o = ObjectHideRequestEvent.emptyNew()
    o.objectIndex = objectIndex
    o.onlyDecollide = onlyDecollide
    return o
end

---send event
-- @param integer streamId
function ObjectHideRequestEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.objectIndex)
    streamWriteBool(streamId, self.onlyDecollide)
end

---receive event
-- @param integer streamId
-- @param Connection connection
function ObjectHideRequestEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self.onlyDecollide = streamReadBool(streamId)
    self:run(connection)
end

---run event
-- @param Connection connection
function ObjectHideRequestEvent:run(connection)
    if g_server ~= nil then
        MapObjectsHider:hideObject(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode), nil, g_currentMission.userManager:getUserByConnection(connection):getNickname(), self.onlyDecollide)
    end
end

---Send the request to the server
-- @param integer objectId
-- @param boolean onlyDecollide
function ObjectHideRequestEvent.sendToServer(objectId, onlyDecollide)
    MapObjectsHider.DebugText("ObjectHideRequestEvent.sendToServer(%s, %s)", objectId, onlyDecollide);
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ObjectHideRequestEvent.new(EntityUtility.nodeToIndex(objectId, MapObjectsHider.mapNode), onlyDecollide))
    end
end
