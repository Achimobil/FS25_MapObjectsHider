--[[
--DE--
Teil des Map Object Hider für den LS22 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the LS22 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.2.0.0 of 01.01.2023
]]

RequestObjectsListEvent = {}
local RequestObjectsListEvent_mt = Class(RequestObjectsListEvent, Event)

InitEventClass(RequestObjectsListEvent, "RequestObjectsListEvent")

---Create instance of Event class
-- @return table self instance of class event
function RequestObjectsListEvent.emptyNew()
    local o = Event.new(RequestObjectsListEvent_mt)
    o.className = "RequestObjectsListEvent"
    return o
end

---Create new instance of event
-- @return table self instance of class event
function RequestObjectsListEvent.new()
    local o = RequestObjectsListEvent.emptyNew()
    return o
end

---send event
-- @param integer streamId
function RequestObjectsListEvent:writeStream(streamId)
end

---receive event
-- @param integer streamId
-- @param Connection connection
function RequestObjectsListEvent:readStream(streamId, connection)
    self:run(connection)
end

---run event
-- @param Connection connection
function RequestObjectsListEvent:run(connection)
    if g_server ~= nil then
        connection:sendEvent(SendObjectsListEvent.new(MapObjectsHider.hiddenObjects))
    end
end

---Send the request to the server
function RequestObjectsListEvent.sendToServer()
    g_client:getServerConnection():sendEvent(RequestObjectsListEvent.new())
end
