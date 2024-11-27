--[[
--DE--
Teil des Map Object Hider für den LS22 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the LS22 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.2.0.0 of 01.01.2023
]]

DeleteSplitShapeEvent = {}
local DeleteSplitShapeEvent_mt = Class(DeleteSplitShapeEvent, Event)

InitEventClass(DeleteSplitShapeEvent, "DeleteSplitShapeEvent")

---Create instance of Event class
-- @return table self instance of class event
function DeleteSplitShapeEvent.emptyNew()
    local e = Event.new(DeleteSplitShapeEvent_mt)
    return e
end

---Create new instance of event
-- @param integer splitShapeId
-- @return table self instance of class event
function DeleteSplitShapeEvent.new(splitShapeId)
    local e = DeleteSplitShapeEvent.emptyNew()
    e.splitShapeId = splitShapeId
    return e
end

---Called on server side on join
-- @param integer streamId
-- @param Connection connection
function DeleteSplitShapeEvent:writeStream(streamId, connection)
    MapObjectsHider.DebugText("DeleteSplitShapeEvent.writeStream(%s, %s)", streamId, connection);
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
end

---Called on client side on join
-- @param integer streamId
-- @param Connection connection
function DeleteSplitShapeEvent:readStream(streamId, connection)
    MapObjectsHider.DebugText("DeleteSplitShapeEvent.readStream(%s, %s)", streamId, connection);
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self:run(connection)
end

---Run action on receiving side
-- @param Connection connection
function DeleteSplitShapeEvent:run(connection)
    MapObjectsHider.DebugText("DeleteSplitShapeEvent.run(%s)", connection);
    if self.splitShapeId ~= 0 then
        local x, y, z = getWorldTranslation(self.splitShapeId);

        -- try to look if it is needed to only delete or to split and then delete
        local needSplit = true;
        if getIsSplitShapeSplit(self.splitShapeId) then
            if getRigidBodyType(self.splitShapeId) ~= RigidBodyType.STATIC then
                needSplit = false;
            elseif getName(self.splitShapeId) == "splitGeom" then
                needSplit = false;
            end
        end

        g_currentMission:removeKnownSplitShape(self.splitShapeId);

        if needSplit then
            splitShape(self.splitShapeId, x, y + 0.2, z, 0, 1, 0, 0, 0, 0, 4, 4, "deleteCutSplitShapeCallback", DeleteSplitShapeEvent)
        else
            delete(self.splitShapeId)
        end

        g_treePlantManager:removingSplitShape(self.splitShapeId);

        local range = 10;

        g_densityMapHeightManager:setCollisionMapAreaDirty(x - range, z - range, x + range, z + range, true);
        g_currentMission.aiSystem:setAreaDirty(x - range, x + range, z - range, z + range);
    end
end

function DeleteSplitShapeEvent.deleteCutSplitShapeCallback(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    if shape ~= nil then
        delete(shape)
    end
end

---Send event to server
-- @param integer splitShapeId
function DeleteSplitShapeEvent.sendEvent(splitShapeId)
    MapObjectsHider.DebugText("DeleteSplitShapeEvent.sendEvent(%s)", splitShapeId);

    local event = DeleteSplitShapeEvent.new(splitShapeId);
    if g_server == nil then
        g_client:getServerConnection():sendEvent(event);
    else
        event:run();
    end
end
