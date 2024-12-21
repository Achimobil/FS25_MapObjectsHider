--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

ShowCollideNodeEvent = {}
local ShowCollideNodeEvent_mt = Class(ShowCollideNodeEvent, Event)

InitEventClass(ShowCollideNodeEvent, "ShowCollideNodeEvent")

---Create instance of Event class
-- @return table self instance of class event
function ShowCollideNodeEvent.emptyNew()
    local o = Event.new(ShowCollideNodeEvent_mt)
    o.className = "ShowCollideNodeEvent"
    return o
end

---Create new instance of event
-- @param boolean show
-- @param integer objectIndex
-- @param string rigidBodyType
-- @return table self instance of class event
function ShowCollideNodeEvent.new(show, objectIndex, rigidBodyType)
    local o = ShowCollideNodeEvent.emptyNew()
    o.objectIndex = objectIndex
    o.show = show
    o.rigidBodyType = rigidBodyType
    return o
end

---send event
-- @param integer streamId
function ShowCollideNodeEvent:writeStream(streamId)
    streamWriteString(streamId, self.objectIndex)
    streamWriteBool(streamId, self.show)
    if not self.show then
        streamWriteInt32(streamId, self.rigidBodyType)
    end
end

---receive event
-- @param integer streamId
-- @param Connection connection
function ShowCollideNodeEvent:readStream(streamId, connection)
    self.objectIndex = streamReadString(streamId)
    self.show = streamReadBool(streamId)
    if not self.show then
        self.rigidBodyType = streamReadInt32(streamId)
    end
    self:run(connection)
end

---run event
-- @param Connection connection
function ShowCollideNodeEvent:run(connection)
    MapObjectsHider.DebugText("ShowCollideNodeEvent.run(%s)", connection);
    if g_server == nil then
        if self.show then
            MapObjectsHider:showNode(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode))
        else
            MapObjectsHider:collideNode(EntityUtility.indexToNode(self.objectIndex, MapObjectsHider.mapNode), self.rigidBodyType)
        end
    end
end

---Send the request to the server
-- @param boolean show
-- @param integer objectIndex
-- @param string|any rigidBodyType
function ShowCollideNodeEvent.sendToClients(show, objectIndex, rigidBodyType)
    MapObjectsHider.DebugText("ShowCollideNodeEvent.sendToClients(%s, %s, %s) - g_server - %s", show, objectIndex, rigidBodyType, g_server);
    if g_server ~= nil then
        g_server:broadcastEvent(ShowCollideNodeEvent.new(show, objectIndex, rigidBodyType))
    end
end
