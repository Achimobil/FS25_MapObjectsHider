--[[
--DE--
Teil des Map Object Hider für den LS22 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the LS22 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.2.0.0 of 01.01.2023
]]

DeletePlacableEvent = {}
local DeletePlacableEvent_mt = Class(DeletePlacableEvent, Event)

InitEventClass(DeletePlacableEvent, "DeletePlacableEvent")

---Create instance of Event class
-- @return table self instance of class event
function DeletePlacableEvent.emptyNew()
    local o = Event.new(DeletePlacableEvent_mt)
    o.className = "DeletePlacableEvent"
    return o
end

---Create new instance of event
-- @param table object
-- @return table self instance of class event
function DeletePlacableEvent.new(object)
    local o = DeletePlacableEvent.emptyNew()
    o.object = object
    return o
end

---send event
-- @param integer streamId
function DeletePlacableEvent:writeStream(streamId)
--     MapObjectsHider.DebugText("DeletePlacableEvent.writeStream(%s)", streamId);
    NetworkUtil.writeNodeObject(streamId, self.object)
end

---receive event
-- @param integer streamId
-- @param Connection connection
function DeletePlacableEvent:readStream(streamId, connection)
--     MapObjectsHider.DebugText("DeletePlacableEvent.readStream(%s, %s)", streamId, connection);
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end

---run event
-- @param Connection connection
function DeletePlacableEvent:run(connection)
--     MapObjectsHider.DebugText("DeletePlacableEvent.run(%s)", connection);
    if self.object == nil then
        MapObjectsHider.DebugText("Get nil in DeletePlacableEvent. Skip running.");
        return;
    end

    self.object:delete();
end

---Send event to server
-- @param table object
function DeletePlacableEvent.sendEvent(object)
--     MapObjectsHider.DebugText("DeletePlacableEvent.sendEvent(%s)", object);

    local event = DeletePlacableEvent.new(object);
    if g_server == nil then
        g_client:getServerConnection():sendEvent(event);
    else
        event:run();
    end
end