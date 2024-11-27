--[[
--DE--
Map Object Hider für den LS25
Basierend auf den Prinzipien und Skripten des gleichnahmigen Mods von Royal Modding aus dem LS 19

Da das meiste hier von mir umgeschrieben und angepasst ist, ist das verändern und wiederveröffentlichen auch in Teilen untersagt.
Veröffentlichung generell nur durch mich. Verbreitung nur mit verlinkung auf original Veröffentlicungen gestattet

--EN--
Map Object Hider for the LS25
Based on the principles and scripts of the same mod by Royal Modding from LS 19.

Since most of the content is rewritten and adapted by me, it is forbidden to change or republish parts of it.
Publication generally only by me. Distribution is only allowed with a link to the original publication.
]]

local modName = g_currentModName

MapObjectsHider = {}
MapObjectsHider.SPEC_TABLE_NAME = "spec_"..modName..".moh"
MapObjectsHider.debug = true;
MapObjectsHider.hideConfirmEnabled = true;
MapObjectsHider.sellConfirmEnabled = true;
MapObjectsHider.deleteSplitShapeConfirmEnabled = true;

--- Print the given Table to the log
-- @param string text parameter Text before the table
-- @param table myTable The table to print
-- @param number maxDepth depth of print, default 2
function MapObjectsHider.DebugTable(text, myTable, maxDepth)
    if not MapObjectsHider.debug then return end
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
    if not MapObjectsHider.debug then return end
    Logging.info("MapObjectsHiderDebug: " .. string.format(text, ...));
end

--- on load the map
--@param string i3dName i3d name
function MapObjectsHider:loadMap(i3dName)
    MapObjectsHider.DebugText("loadMap: %s", i3dName)
--     MapObjectsHider.targeter = PlayerTargeter.new(self)
end

--- executed per frame
-- @param number dt
function MapObjectsHider:update(dt)





    -- Ausgabe der Debug Info wenn vorhanden
    if MapObjectsHider.debug and self.debugInfo ~= nil then
        DebugUtility.renderTable(0.05, 0.98, 0.009, self.debugInfo, 4, false)
    end

    if MapObjectsHider.debug and self.hideObjectDebugInfo ~= nil then
        DebugUtility.renderTable(0.35, 0.98, 0.009, self.hideObjectDebugInfo, 4, false)
    end




    -- raycast aus dem neuen 25er targeter abgerufen
    local hitObjectId = g_localPlayer.targeter:getClosestTargetedNodeFromType(MapObjectsHider);
    if hitObjectId ~= nil then
        if getHasClassId(hitObjectId, ClassIds.SHAPE) then
--             if hitObjectId == self.lastRaycastHitObjectId and not MapObjectsHider.debug then
            if hitObjectId == self.lastRaycastHitObjectId then
                self.raycastHideObject = self.lastRaycastHideObject
                return;
            end
            local objectFound = false
            local rigidBodyType = getRigidBodyType(hitObjectId)
--             MapObjectsHider.DebugText("rigidBodyType %s", rigidBodyType);

            if (rigidBodyType == RigidBodyType.STATIC or rigidBodyType == RigidBodyType.DYNAMIC) then
                if getSplitType(hitObjectId) ~= 0 then
                    self.raycastHideObject = {name = getName(getParent(hitObjectId)), objectId = hitObjectId, isSplitShape = true}
                    if MapObjectsHider.debug then
                        -- debug placeable
                        self.hideObjectDebugInfo = {type = "Split Type", splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(hitObjectId))}
                    end
                    objectFound = true
                elseif g_currentMission:getNodeObject(hitObjectId) == nil then
                    local object = {}
                    object.id, object.name = MapObjectsHider:getRealHideObject(hitObjectId)
                    if object.id ~= nil then
                        self.raycastHideObject = object
                        if MapObjectsHider.debug then
                            -- debug hide object
                            self.hideObjectDebugInfo = MapObjectsHider:getObjectDebugInfo(object.id)
                        end
                        objectFound = true
                    end
                else
                    local object = g_currentMission:getNodeObject(hitObjectId)
                    if object:isa(Placeable) then
                        local storeItem = g_storeManager:getItemByXMLFilename(object.configFileName)
                        if storeItem ~= nil then
                            local canSell = object:canBeSold() and storeItem.canBeSold and g_currentMission:getFarmId() == object:getOwnerFarmId();
                            if canSell then
                                self.raycastHideObject = {name = storeItem.name, object = object, isSellable = true}
                                if MapObjectsHider.debug then
                                    -- debug placeable
                                    self.hideObjectDebugInfo = {type = "Placeable", storeItem = storeItem}
                                end
                                objectFound = true
                            end
                        end
                    end
                end
            end
            if objectFound then
                self.lastRaycastHitObjectId = hitObjectId
                self.lastRaycastHideObject = self.raycastHideObject
            end
        end
    end
end

--- get the real object which should be hidden
-- @param integer objectId
-- @return integer | nil id of the object
-- @return string name of the object
function MapObjectsHider:getRealHideObject(objectId)
    MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject(%s)", objectId)
    -- local amo = self.animatedMapObjectCollisions[objectId]
    -- if amo ~= nil then
        -- return amo.mapObjectsHider.rootNode, getName(amo.mapObjectsHider.rootNode)
    -- end

    -- try to intercept big sized objects with LOD such as houses
    if getName(getParent(objectId)) == "LOD0" or getName(getParent(objectId)) == "LOD1" then
        local rootNode = getParent(getParent(objectId))
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - found LOD0/1 as parent")
        return rootNode, getName(rootNode)
    end

    if getName(objectId) == "LOD0" or getName(objectId) == "LOD1" then
        local rootNode = getParent(objectId)
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - found LOD0/1 as itself")
        return rootNode, getName(rootNode)
    end

    -- lockedgroups als grandpa should be used
    local parent = getParent(objectId)

    if getIsLockedGroup(getParent(parent)) then
        local rootNode = getParent(parent)
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - getIsLockedGroup")
        return rootNode, getName(rootNode)
    end

    local name = ""
    local id = nil

    -- try to intercept medium sized objects such as electric cabins
    -- check only when current and parent has 8 or less childs to avoid decoration groups
    if getNumOfChildren(objectId) <= 8 and getNumOfChildren(parent) <= 8 then
        EntityUtility.queryNodeHierarchy(
            parent,
            function(_, nodeName, depth)
                if depth == 2 then
                    if string.find(string.lower(nodeName), "decal", 1, true) then
                        name = getName(parent)
                        id = parent
                    end
                end
            end
        )
        if id ~= nil then
            MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - object and parent with <= 8 childs with %s, %s", id, name)
            return id, name
        end
    end

    EntityUtility.queryNodeParents(
        objectId,
        function(node, nodeName)
            -- do some extra checks to ensure that's the real object
            if getVisibility(node) then
                id = node
                name = nodeName
                return false
            end
            return true
        end
    )
--     MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - last return")
    return id, name
end

--- Get debug info for object
-- @param integer objectId
-- @return table info for debug view
function MapObjectsHider:getObjectDebugInfo(objectId)
    local debugInfo = {}
    debugInfo.type = "Object Debug Info"
    debugInfo.id = objectId
    debugInfo.objectClassId, debugInfo.objectClass = EntityUtility.getObjectClass(objectId)
    debugInfo.object = g_currentMission:getNodeObject(objectId) or "nil"
    debugInfo.rigidBodyType = getRigidBodyType(objectId)
    debugInfo.index = EntityUtility.nodeToIndex(objectId, self.mapNode)
    debugInfo.name = getName(objectId)
    debugInfo.clipDistance = getClipDistance(objectId)
    debugInfo.mask = getObjectMask(objectId)
    debugInfo.collisionMask = getCollisionFilterMask(objectId)

    if debugInfo.objectClassId == ClassIds.SHAPE then
        debugInfo.isNonRenderable = getIsNonRenderable(objectId)
        debugInfo.geometry = getGeometry(objectId)
        debugInfo.material = getMaterial(objectId, 0)
        debugInfo.materialName = getName(debugInfo.material)
    end

    return debugInfo
end

---Event callback for menu input.
function MapObjectsHider:hideObjectActionEvent(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
    MapObjectsHider.DebugText("hideObjectActionEvent(%s, %s, %s, %s, %s, %s)", actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
    self:baseObjectActionEvent(false)
end

--- base method for all callbacs
function MapObjectsHider:baseObjectActionEvent(onlyDecollide)
    MapObjectsHider.DebugText("baseObjectActionEvent(%s)", onlyDecollide);
    MapObjectsHider.DebugText("raycastHideObject(%s)", self.raycastHideObject);

    if self.raycastHideObject ~= nil then
        self.raycastHideObjectBackup = self.raycastHideObject
        self.onlyDecollide = onlyDecollide
        if self.raycastHideObject.isSellable then
            if MapObjectsHider.sellConfirmEnabled then
                YesNoDialog.show(self.deleteSplitShapeDialogCallback, self, g_i18n:getText("moh_sell_dialog_text"), g_i18n:getText("moh_dialog_title"))
            else
                self:sellObjectDialogCallback(true)
            end
        elseif self.raycastHideObject.isSplitShape then
            if MapObjectsHider.deleteSplitShapeConfirmEnabled then
                YesNoDialog.show(self.deleteSplitShapeDialogCallback, self, g_i18n:getText("moh_delete_split_shape_dialog_text"), g_i18n:getText("moh_dialog_title"))
            else
                self:deleteSplitShapeDialogCallback(true)
            end
        else
            if MapObjectsHider.hideConfirmEnabled then
                YesNoDialog.show(self.deleteSplitShapeDialogCallback, self, g_i18n:getText("moh_dialog_text"), g_i18n:getText("moh_dialog_title"))
            else
                self:hideObjectDialogCallback(true)
            end
        end
    end
end

--- Doalog call back
-- @param boolean yes
function MapObjectsHider:deleteSplitShapeDialogCallback(yes)
    MapObjectsHider.DebugText("deleteSplitShapeDialogCallback(%s)", yes);
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.objectId ~= nil then
        DeleteSplitShapeEvent.sendEvent(self.raycastHideObjectBackup.objectId)
    end
end

addModEventListener(MapObjectsHider);