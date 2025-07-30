--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

ObjectShowRequestEvent = {}
local ObjectShowRequestEvent_mt = Class(ObjectShowRequestEvent, Event)

InitEventClass(ObjectShowRequestEvent, "ObjectShowRequestEvent")

---Create instance of Event class
-- @return table self instance of class event
function ObjectShowRequestEvent.emptyNew()
    local o = Event.new(ObjectShowRequestEvent_mt)
    o.className = "ObjectShowRequestEvent"
    return o
end

---Create new instance of event
-- @param integer objectIndex
-- @return table self instance of class event
function ObjectShowRequestEvent.new(objectIndex)
    local o = ObjectShowRequestEvent.emptyNew()
    o.objectIndex = objectIndex
    return o
end

---send event
-- @param integer streamId
function ObjectShowRequestEvent:writeStream(streamId, _)
    MapObjectsHider.DebugText("ObjectShowRequestEvent.writeStream(%s)", streamId);
    streamWriteString(streamId, self.objectIndex)
end

---receive event
-- @param integer streamId
-- @param Connection connection
function ObjectShowRequestEvent:readStream(streamId, connection)
    MapObjectsHider.DebugText("ObjectShowRequestEvent.readStream(%s)", connection);
    self.objectIndex = streamReadString(streamId)
    self:run(connection)
end

---run event
-- @param Connection connection
function ObjectShowRequestEvent:run(connection)
    MapObjectsHider.DebugText("ObjectShowRequestEvent.run(%s)", connection);
    if g_server ~= nil then
        MapObjectsHider:showObject(self.objectIndex)
    end
end

---Send the request to the server
-- @param string objectIndex
function ObjectShowRequestEvent.sendToServer(objectIndex)
    MapObjectsHider.DebugText("ObjectShowRequestEvent.sendToServer(%s)", objectIndex);
    g_client:getServerConnection():sendEvent(ObjectShowRequestEvent.new(objectIndex))
end
