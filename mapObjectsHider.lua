--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.
]]

local modName = g_currentModName

MapObjectsHider = {}
MapObjectsHider.SPEC_TABLE_NAME = "spec_"..modName..".moh";
MapObjectsHider.modName = modName;
MapObjectsHider.debug = false;
MapObjectsHider.hideConfirmEnabled = true;
MapObjectsHider.sellConfirmEnabled = true;
MapObjectsHider.deleteSplitShapeConfirmEnabled = true;
MapObjectsHider.currentEventId = nil;
MapObjectsHider.currentEvent2Id = nil;
MapObjectsHider.hiddenObjects = {}
MapObjectsHider.revision = 1
MapObjectsHider.md5 = not MapObjectsHider.debug
MapObjectsHider.hasFrameTriggered = false;
MapObjectsHider.modDirectory = g_currentModDirectory

--- Print the given Table to the log
-- @param string text parameter Text before the table
-- @param table myTable The table to print
-- @param number|any maxDepth depth of print, default 2
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

---Print the text to the log as info. Example: BigDisplaySpecialization.info("Alter: %s", age)
-- @param string infoMessage the text to print formated
-- @param any ... format parameter
function MapObjectsHider.info(infoMessage, ...)
    if MapObjectsHider.Debug then
        MapObjectsHider.DebugText("Info:" .. infoMessage, ...)
    else
        Logging.info(MapObjectsHider.modName .. " - " .. infoMessage, ...);
    end
end

--- on load the map
--@param string i3dName i3d name
function MapObjectsHider:loadMap(i3dName)
    MapObjectsHider.DebugText("loadMap: %s", i3dName)

    -- speichern/laden mit dem savegame
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, MapObjectsHider.saveToXMLFile)

    self.mapNode = g_currentMission.maps[1];
    self:loadFromXML();

    -- Gui laden
    self.gui = g_gui:loadGui(self.modDirectory.."gui/mapObjectsHiderDialog.xml", "MapObjectsHiderDialog", MapObjectsHiderDialog.new())

    -- damit beim joinen im MP die einstellungen geholt werden senden wir ein event dass die einstellungen dann an alle schickt
    FSBaseMission.onConnectionFinishedLoading = Utils.overwrittenFunction(FSBaseMission.onConnectionFinishedLoading, MapObjectsHider.loadSettingsFromServer)
end

--- executed per frame
-- @param number dt
function MapObjectsHider:update(dt)


    -- Ausgabe der Debug Info wenn vorhanden
    if MapObjectsHider.debug and self.debugInfo ~= nil then
        DebugUtility.renderTable(0.05, 0.98, 0.010, self.debugInfo, 4, false);
    end

    if MapObjectsHider.debug and self.hideObjectDebugInfo ~= nil then
        DebugUtility.renderTable(0.35, 0.98, 0.010, self.hideObjectDebugInfo, 4, false);
        self.hideObjectDebugInfo = nil;
    end

    -- nil abfragen die eigentlich nicht sein können, aber doch gemeldet wurden
    if g_localPlayer == nil then return end;

    -- raycast aus dem neuen 25er targeter abgerufen
    local hitObjectId = g_localPlayer.targeter:getClosestTargetedNodeFromType(MapObjectsHider);
    if hitObjectId ~= nil and entityExists(hitObjectId) then
--         MapObjectsHider.DebugText("getHasClassId(%s, ClassIds.SHAPE) = %s", hitObjectId, getHasClassId(hitObjectId, ClassIds.SHAPE))
        if getHasClassId(hitObjectId, ClassIds.SHAPE) then
            if hitObjectId == self.lastRaycastHitObjectId and not MapObjectsHider.debug then
                self.raycastHideObject = self.lastRaycastHideObject
                return;
            end
            local objectFound = false;
            local actionText = "";
            local action2Text = "";
            local rigidBodyType = getRigidBodyType(hitObjectId)
--             MapObjectsHider.DebugText("rigidBodyType %s", rigidBodyType);

            -- Only Master User or on own land and having SELL_PLACEABLE permission can hide/delete/sell anything
            local playerX, _, playerZ = g_localPlayer:getPosition();
--             MapObjectsHider.DebugText("position %s %s", playerX, playerZ);
            local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(playerX, playerZ);
            local playerOnOwnFarmLand = farmlandId == g_currentMission:getFarmId();
--             MapObjectsHider.DebugText("playerOnOwnFarmLand %s", playerOnOwnFarmLand);
            local playerAllowedToDeleteOrHide = (playerOnOwnFarmLand and g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)) or g_currentMission.isMasterUser;

            if (rigidBodyType == RigidBodyType.STATIC or rigidBodyType == RigidBodyType.DYNAMIC) and playerAllowedToDeleteOrHide then
--                 MapObjectsHider.DebugText("splitType %s", getSplitType(hitObjectId));
                if getSplitType(hitObjectId) ~= 0 then
                    -- when is a tree deletable? Only when on own or unowned land
                    local splitTypeObject = g_splitShapeManager:getSplitTypeByIndex(getSplitType(hitObjectId))

                    self.raycastHideObject = {name = splitTypeObject.title or "something", objectId = hitObjectId, isSplitShape = true}
                    if MapObjectsHider.debug then
                        -- debug placeable
                        self.hideObjectDebugInfo = {type = "Split Type", splitType = splitTypeObject };
                    end
                    objectFound = true;
                    actionText = g_i18n:getText("moh_DELETE"):format(self.raycastHideObject.name);
                elseif g_currentMission:getNodeObject(hitObjectId) == nil then
--                     MapObjectsHider.DebugText("g_currentMission:getNodeObject(%s)", hitObjectId)
                    local object = {}
                    object.id, object.name = MapObjectsHider:getRealHideObject(hitObjectId)
                    if object.id ~= nil and EntityUtility.nodeToIndex(object.id, self.mapNode) ~= "" then
                        self.raycastHideObject = object
                        if MapObjectsHider.debug then
                            -- debug hide object
                            self.hideObjectDebugInfo = MapObjectsHider:getObjectDebugInfo(object.id)
                        end
                        objectFound = true
                        actionText = g_i18n:getText("moh_HIDE"):format(self.raycastHideObject.name);
                        action2Text = g_i18n:getText("moh_DECOLLIDE"):format(self.raycastHideObject.name);
                    end
                else
                    local object = g_currentMission:getNodeObject(hitObjectId)
--                     MapObjectsHider.DebugTable("else object", object)
--                     MapObjectsHider.DebugText("object:isa(Placeable)) - %s", object:isa(Placeable))
                    if object:isa(Placeable) then
                        local storeItem = g_storeManager:getItemByXMLFilename(object.configFileName)
                        if storeItem ~= nil then
--                             MapObjectsHider.DebugText("object:canBeSold() = %s - storeItem.canBeSold = %s - g_currentMission:getFarmId() = %s - object:getOwnerFarmId() = %s", object:canBeSold(), storeItem.canBeSold, g_currentMission:getFarmId(), object:getOwnerFarmId());


                            local allowedToSell = g_currentMission:getFarmId() == object:getOwnerFarmId();
                            local canSell = object:canBeSold() and storeItem.canBeSold and g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE);
                            local isFromSpectator = object:getOwnerFarmId() == 0;
--                             MapObjectsHider.DebugText("allowedToSell = %s - canSell = %s", allowedToSell, canSell);
                            MapObjectsHider.DebugText("g_currentMission.isMasterUser %s", g_currentMission.isMasterUser);
                            if canSell then
                                if allowedToSell then
                                    -- this is a placable and the user is allowed to sell
                                    self.raycastHideObject = {name = storeItem.name, object = object, isSellable = true, needsToBeDeleted = false};
                                    if MapObjectsHider.debug then
                                        self.hideObjectDebugInfo = {type = "Placeable", storeItem = storeItem};
                                    end
                                    objectFound = true;
                                    actionText = g_i18n:getText("moh_SELL"):format(self.raycastHideObject.name);
                                elseif isFromSpectator and g_currentMission.isMasterUser == true then
                                    -- this is a placable from spectator and then it needs to be deleted
                                    self.raycastHideObject = {name = storeItem.name, object = object, isSellable = true, needsToBeDeleted = true};
                                    if MapObjectsHider.debug then
                                        self.hideObjectDebugInfo = {type = "Placeable", storeItem = storeItem};
                                    end
                                    objectFound = true;
                                    actionText = g_i18n:getText("moh_DELETE"):format(self.raycastHideObject.name);
                                end
                            else
--                                 MapObjectsHider.DebugText("Placable not sellable");
                            end
                        end
                    end
                end
            end
            if objectFound then
                self.lastRaycastHitObjectId = hitObjectId;
                self.lastRaycastHideObject = self.raycastHideObject;

                -- update text of F1 menü
                if MapObjectsHider.currentEventId ~= nil then
                    g_inputBinding:setActionEventText(MapObjectsHider.currentEventId, actionText);
                    g_inputBinding:setActionEventActive(MapObjectsHider.currentEventId, true);
                    g_inputBinding:setActionEventTextVisibility(MapObjectsHider.currentEventId, true);
                end
                if MapObjectsHider.action2Text ~= "" then
                    g_inputBinding:setActionEventText(MapObjectsHider.currentEvent2Id, action2Text);
                    g_inputBinding:setActionEventActive(MapObjectsHider.currentEvent2Id, true);
                    g_inputBinding:setActionEventTextVisibility(MapObjectsHider.currentEvent2Id, true);
                else
                    g_inputBinding:setActionEventActive(MapObjectsHider.currentEvent2Id, false);
                end
            else
                self.lastRaycastHitObjectId = nil;
                self.lastRaycastHideObject = nil;

                -- hide and disable action when nothing is now in range
                if MapObjectsHider.currentEventId ~= nil then
                    g_inputBinding:setActionEventActive(MapObjectsHider.currentEventId, false)
                    g_inputBinding:setActionEventTextVisibility(MapObjectsHider.currentEventId, false)
                end
                if MapObjectsHider.currentEvent2Id ~= nil then
                    g_inputBinding:setActionEventActive(MapObjectsHider.currentEvent2Id, false)
                    g_inputBinding:setActionEventTextVisibility(MapObjectsHider.currentEvent2Id, false)
                end
            end
        end
    else
        self.lastRaycastHitObjectId = nil;
        self.lastRaycastHideObject = nil;

        -- hide and disable action when nothing is now in range
        if MapObjectsHider.currentEventId ~= nil then
            g_inputBinding:setActionEventActive(MapObjectsHider.currentEventId, false)
            g_inputBinding:setActionEventTextVisibility(MapObjectsHider.currentEventId, false)
        end
        if MapObjectsHider.currentEvent2Id ~= nil then
            g_inputBinding:setActionEventActive(MapObjectsHider.currentEvent2Id, false)
            g_inputBinding:setActionEventTextVisibility(MapObjectsHider.currentEvent2Id, false)
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

    -- lockedgroups als grandpa should be used
    local parent = getParent(objectId);

    -- try to intercept big sized objects with LOD such as houses
    if getName(parent) == "LOD0" or getName(parent) == "LOD1" then
        local rootNode = getParent(parent)
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - found LOD0/1 as parent")
        return rootNode, getName(rootNode)
    end

    if getName(objectId) == "LOD0" or getName(objectId) == "LOD1" then
        local rootNode = getParent(objectId)
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - found LOD0/1 as itself")
        return rootNode, getName(rootNode)
    end

    if getIsLockedGroup(getParent(parent)) then
        local rootNode = getParent(parent)
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - getIsLockedGroup grandparent")
        return rootNode, getName(rootNode)
    end

    -- when parent is locked group, then use this
    if getIsLockedGroup(parent) then
        local rootNode = parent;
        MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - getIsLockedGroup parent")
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
    MapObjectsHider.DebugText("MapObjectsHider:getRealHideObject - last return")
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
function MapObjectsHider:hideObjectActionEvent()
    MapObjectsHider.DebugText("hideObjectActionEvent()")
    self:baseObjectActionEvent(false)
end

---Event callback for menu input.
function MapObjectsHider:decollideObjectActionEvent()
    MapObjectsHider.DebugText("decollideObjectActionEvent()")
    self:baseObjectActionEvent(true)
end

--- base method for all callbacs
-- @param Boolean onlyDecollide
function MapObjectsHider:baseObjectActionEvent(onlyDecollide)
    MapObjectsHider.DebugText("baseObjectActionEvent(%s)", onlyDecollide);
    MapObjectsHider.DebugText("raycastHideObject(%s)", self.raycastHideObject);

    if self.raycastHideObject ~= nil then
        self.raycastHideObjectBackup = self.raycastHideObject
        self.onlyDecollide = onlyDecollide
        if self.raycastHideObject.isSellable then
            if self.raycastHideObject.needsToBeDeleted then
                -- here the Placeable is from spectator farm, so needs to be deleted
                if MapObjectsHider.sellConfirmEnabled then
                    YesNoDialog.show(self.sellObjectDialogCallback, self, g_i18n:getText("moh_delete_dialog_text"):format(self.raycastHideObject.name), g_i18n:getText("moh_dialog_title"))
                else
                    self:sellObjectDialogCallback(true)
                end
            else
                -- raycastHideObject only contains sellable object, when user is allowed to sell
                if MapObjectsHider.sellConfirmEnabled then
                    YesNoDialog.show(self.sellObjectDialogCallback, self, g_i18n:getText("moh_sell_dialog_text"):format(self.raycastHideObject.name), g_i18n:getText("moh_dialog_title"))
                else
                    self:sellObjectDialogCallback(true)
                end
            end
        elseif self.raycastHideObject.isSplitShape then
            if MapObjectsHider.deleteSplitShapeConfirmEnabled then
                YesNoDialog.show(self.deleteSplitShapeDialogCallback, self, g_i18n:getText("moh_delete_split_shape_dialog_text"), g_i18n:getText("moh_dialog_title"))
            else
                self:deleteSplitShapeDialogCallback(true)
            end
        else
            -- check if object to hide is on own or unowned farm land.
            -- But how to find that?
            if MapObjectsHider.hideConfirmEnabled then
                local textKey = "moh_ask_hide";
                if onlyDecollide then
                    textKey = "moh_ask_decollide"
                end

                YesNoDialog.show(self.hideObjectDialogCallback, self, g_i18n:getText(textKey):format(self.raycastHideObject.name), g_i18n:getText("moh_dialog_title"))
            else
                self:hideObjectDialogCallback(true)
            end
        end
    end
end

--- Dialog call back
-- @param boolean yes
function MapObjectsHider:sellObjectDialogCallback(yes)
    MapObjectsHider.DebugText("sellObjectDialogCallback(%s)", yes);
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.object ~= nil then
        if self.raycastHideObjectBackup.needsToBeDeleted then
            DeletePlacableEvent.sendEvent(self.raycastHideObjectBackup.object)
        else
            g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(self.raycastHideObjectBackup.object, false, true, true))
        end
    end
end

--- Dialog call back
-- @param boolean yes
function MapObjectsHider:deleteSplitShapeDialogCallback(yes)
    MapObjectsHider.DebugText("deleteSplitShapeDialogCallback(%s)", yes);
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.objectId ~= nil then
        DeleteSplitShapeEvent.sendEvent(self.raycastHideObjectBackup.objectId)
    end
end

--- Dialog call back
--@param boolean yes
function MapObjectsHider:hideObjectDialogCallback(yes)
    MapObjectsHider.DebugText("hideObjectDialogCallback(%s)", yes);
    if yes and self.raycastHideObjectBackup ~= nil and self.raycastHideObjectBackup.id ~= nil then
        self:hideObject(self.raycastHideObjectBackup.id, nil, nil, self.onlyDecollide)
        self.raycastHideObjectBackup = nil
    end
end

--- Hide the given object
-- @param integer objectId
-- @param string|nil name
-- @param string hiderPlayerName
-- @param Boolean onlyDecollide
function MapObjectsHider:hideObject(objectId, name, hiderPlayerName, onlyDecollide)
    MapObjectsHider.DebugText("MapObjectsHider:hideObject(%s, %s, %s, %s)", objectId, name, hiderPlayerName, onlyDecollide);
    if g_server ~= nil then
        local objectName = name or getName(objectId)

        local object = MapObjectsHider:getHideObject(objectId, objectName, hiderPlayerName);
        object.onlyDecollide = onlyDecollide;
--         MapObjectsHider.DebugTable("object", object);

        if MapObjectsHider:checkHideObject(object) then
            if not onlyDecollide then
                self:hideNode(object.id)
                HideDecollideNodeEvent.sendToClients(object.index, true)
            end
            for _, collision in pairs(object.collisions) do
                self:decollideNode(collision.id)
                HideDecollideNodeEvent.sendToClients(collision.index, false)
            end
            table.insert(self.hiddenObjects, object)
        end
    else
        ObjectHideRequestEvent.sendToServer(objectId, onlyDecollide)
    end
end

--- Show the given object index
-- @param string objectIndex
function MapObjectsHider:showObject(objectIndex)
    MapObjectsHider.DebugText("showObject:(%s)", objectIndex);
    if g_server ~= nil then
--         local myFunction =
        ArrayUtility.remove(
            self.hiddenObjects,
            -- @param hiddenObjects HideObject[]
            -- @param index integer
            -- @return boolean
            function(hiddenObjects, index)
                local hiddenObject = hiddenObjects[index]
                if hiddenObject.index == objectIndex then
                    MapObjectsHider.DebugTable("hiddenObject", hiddenObject)
                    self:showNode(hiddenObject.id)
                    ShowCollideNodeEvent.sendToClients(true, hiddenObject.index)
                    for _, col in pairs(hiddenObject.collisions) do
                        self:collideNode(col.id, col.rigidBodyType)
                        ShowCollideNodeEvent.sendToClients(false, col.index, col.rigidBodyType)
                    end
                    return true
                end
                return false
            end
        )
    end
end

--- get the object to hide
-- @param integer objectId
-- @param string objectName
-- @param string hiderPlayerName
-- @return table object
function MapObjectsHider:getHideObject(objectId, objectName, hiderPlayerName)
    -- @class HideObject
    local object = {}
    object.index = EntityUtility.nodeToIndex(objectId, self.mapNode);
    object.id = objectId;
    object.hash = EntityUtility.getNodeHierarchyHash(objectId, self.mapNode, self.md5);
    object.name = objectName;
    object.date = getDate("%d/%m/%Y");
    object.time = getDate("%H:%M:%S");
    object.timestamp = Utility.getTimestamp();
    object.player = hiderPlayerName or g_currentMission.playerNickname;

    -- @type HideObjectCollision[]
    object.collisions = {}
    EntityUtility.queryNodeHierarchy(
        objectId,
        -- @param node integer
        -- @param name string
        function(node, name)
            local rigidType = getRigidBodyType(node)
            if rigidType ~= RigidBodyType.NONE then
                -- @class HideObjectCollision
                local col = {}
                col.index = EntityUtility.nodeToIndex(node, self.mapNode)
                col.name = name
                col.id = node
                col.rigidBodyType = rigidType
                table.insert(object.collisions, col)
            end
        end
    )
    return object
end

--- Check Object to hide
-- @param table object
-- @return boolean isHideAllowed
function MapObjectsHider:checkHideObject(object)
    if type(object.id) ~= "number" or not entityExists(object.id) then
        return false
    end

    if object.hash ~= EntityUtility.getNodeHierarchyHash(object.id, self.mapNode, self.md5) then
        return false
    end

    if object.name ~= getName(object.id) then
        return false
    end

    for _, collision in pairs(object.collisions) do
        if type(collision.id) ~= "number" or not entityExists(collision.id) then
            return false
        end

        if collision.rigidBodyType ~= getRigidBodyType(collision.id) then
            return false
        end

        if collision.name ~= getName(collision.id) then
            return false
        end
    end

    return true
end

--- Hide the node
-- @param integer nodeId
function MapObjectsHider:hideNode(nodeId)
    if nodeId == nil then
        MapObjectsHider.info("node id null, not hiding node");
        return;
    end

    setVisibility(nodeId, false)
end

--- Show the node
-- @param integer nodeId
function MapObjectsHider:showNode(nodeId)
    MapObjectsHider.DebugText("showNode:(%s)", nodeId);
    if nodeId == nil then
        MapObjectsHider.info("node id null, not showing node");
        return;
    end
    setVisibility(nodeId, true)
end

--- remove collision from the node
-- @param integer nodeId
function MapObjectsHider:decollideNode(nodeId)

    if nodeId == nil then
        MapObjectsHider.DebugText("Get nil on decollideNode. Prevent executing");
        return;
    end

    setRigidBodyType(nodeId, RigidBodyType.NONE)
end

--- add collision from the node
-- @param integer nodeId
-- @param string rigidBodyType
function MapObjectsHider:collideNode(nodeId, rigidBodyType)
    MapObjectsHider.DebugText("collideNode:(%s, %s)", nodeId, rigidBodyType);
    if nodeId == nil then
        MapObjectsHider.DebugText("Get nil on decollideNode. Prevent executing");
        return;
    end

    setRigidBodyType(nodeId, rigidBodyType)
end

--- save the hidden list to the savegame
function MapObjectsHider:saveToXMLFile()
    MapObjectsHider.DebugText("saveToXMLFile()");

    if g_server ~= nil then
        local spec = MapObjectsHider
        local file = string.format("%s/mapObjectsHider.xml", g_currentMission.missionInfo.savegameDirectory)
        MapObjectsHider.DebugText("save to file %s", tostring(file));
        local xmlFile = createXMLFile("mapObjectsHider_xml_temp", file, "mapObjectsHider")
        setXMLInt(xmlFile, "mapObjectsHider#revision", spec.revision)
        setXMLBool(xmlFile, "mapObjectsHider#md5", spec.md5)
        local index = 0
        for _, object in pairs(spec.hiddenObjects) do
            local key = string.format("mapObjectsHider.hiddenObjects.object(%d)", index)
            setXMLString(xmlFile, key .. "#name", object.name)
            setXMLString(xmlFile, key .. "#index", object.index)
            setXMLString(xmlFile, key .. "#date", object.date)
            setXMLString(xmlFile, key .. "#time", object.time)
            setXMLString(xmlFile, key .. "#player", object.player)
            setXMLBool(xmlFile, key .. "#onlyDecollide", object.onlyDecollide or false)
            setXMLInt(xmlFile, key .. "#timestamp", object.timestamp)
            setXMLString(xmlFile, key .. "#hash", object.hash)

            local cIndex = 0
            for _, collision in pairs(object.collisions) do
                local cKey = string.format("%s.collision(%d)", key, cIndex)
                setXMLString(xmlFile, cKey .. "#name", collision.name)
                setXMLString(xmlFile, cKey .. "#index", collision.index)
                setXMLInt(xmlFile, cKey .. "#rigidBodyType", collision.rigidBodyType)
                cIndex = cIndex + 1
            end

            index = index + 1
        end
        saveXMLFile(xmlFile)
        delete(xmlFile)
    end
end

--- load the hidden list from the savegame
function MapObjectsHider:loadFromXML()
    MapObjectsHider.DebugText("MapObjectsHider:loadFromXML()");

    if g_server ~= nil then
        local file = string.format("%s/mapObjectsHider.xml", g_currentMission.missionInfo.savegameDirectory)
        if fileExists(file) then
            local xmlFile = loadXMLFile("mapObjectsHider_xml_temp", file)
            local savegameUpdate = false
            local savegameRevision = getXMLInt(xmlFile, "mapObjectsHider#revision") or 0
            if savegameRevision < self.revision then
                Logging.devInfo("[%s] Updating savegame from revision %d to %d", self.name, savegameRevision, self.revision)
                savegameUpdate = true
            end
            local savegameMd5 = getXMLBool(xmlFile, "mapObjectsHider#md5") or false
            if savegameMd5 ~= self.md5 then
                savegameUpdate = true
            end
            local index = 0
            while true do
                local key = string.format("mapObjectsHider.hiddenObjects.object(%d)", index)
                if hasXMLProperty(xmlFile, key) then
                    ---@type HideObject
                    local object = {}
                    object.name = getXMLString(xmlFile, key .. "#name") or ""
                    object.index = getXMLString(xmlFile, key .. "#index") or ""
                    object.hash = getXMLString(xmlFile, key .. "#hash") or ""
                    object.date = getXMLString(xmlFile, key .. "#date") or ""
                    object.time = getXMLString(xmlFile, key .. "#time") or ""
                    object.player = getXMLString(xmlFile, key .. "#player") or ""
                    object.onlyDecollide = getXMLBool(xmlFile, key .. "#onlyDecollide") or false
                    object.timestamp = getXMLInt(xmlFile, key .. "#timestamp") or self.getTimestampFromDateAndTime(object.date, object.time)
                    object.id = EntityUtility.indexToNode(object.index, self.mapNode)
                    if object.id ~= nil then
                        local newHash = EntityUtility.getNodeHierarchyHash(object.id, self.mapNode, self.md5)
                        if savegameUpdate then
                            object.hash = newHash
                        end
                        if newHash == object.hash then
                            if not object.onlyDecollide then
                                self:hideNode(object.id)
                            end
                            ---@type HideObjectCollision[]
                            object.collisions = {}
                            local cIndex = 0
                            while true do
                                local cKey = string.format("%s.collision(%d)", key, cIndex)
                                if hasXMLProperty(xmlFile, cKey) then
                                    local collision = {}
                                    collision.name = getXMLString(xmlFile, cKey .. "#name") or ""
                                    collision.index = getXMLString(xmlFile, cKey .. "#index") or ""
                                    collision.rigidBodyType = getXMLInt(xmlFile, cKey .. "#rigidBodyType") or RigidBodyType.NONE
                                    collision.id = EntityUtility.indexToNode(collision.index, self.mapNode)
                                    if collision.id ~= nil and getRigidBodyType(collision.id) == collision.rigidBodyType then
                                        self:decollideNode(collision.id)
                                        table.insert(object.collisions, collision)
                                    end
                                    cIndex = cIndex + 1
                                else
                                    break
                                end
                            end
                            table.insert(self.hiddenObjects, object)
                        else
                            self:printObjectLoadingError(object.name)
                            if self.debug then
                                Logging.devInfo("  Old: %s", object.hash)
                                Logging.devInfo("  New: %s", newHash)
                            end
                        end
                    else
                        self:printObjectLoadingError(object.name)
                    end
                    index = index + 1
                else
                    break
                end
            end
            delete(xmlFile)
        end
    end
end

--- print warning in log for not loadable item, even without debug enabled
-- @param string name
function MapObjectsHider:printObjectLoadingError(name)
    Logging.warning("[%s] Can't find %s, something may have changed in the map hierarchy, the object will be restored.", self.modName, name)
end

---override to load settings from server
-- @param any baseMission
-- @param function superFunc superFunc
-- @param table connection connection
-- @param float x x position
-- @param float y y position
-- @param float z z position
-- @param float viewDistanceCoeff coeff
function MapObjectsHider.loadSettingsFromServer(baseMission, superFunc, connection, x, y, z, viewDistanceCoeff)
--     MapObjectsHider.DebugText("loadSettingsFromServer(%s, %s, %s, %s, %s, %s, %s)", baseMission, superFunc, connection, x, y, z, viewDistanceCoeff);

    -- beim connecten auf den Server wird dieses auf dem Server aufgerufen und wir senden die auf dem Server stehenden daten an den neuen client

    superFunc(baseMission, connection, x, y, z, viewDistanceCoeff)

    connection:sendEvent(LoadMapObjectsHiderDataResult.new(), false)
end

---Open the UI to show hidden objects
function MapObjectsHider:openGui()
    MapObjectsHider.DebugText("openGui:()");

    if self.gui == nil then
        MapObjectsHider.info("UI not loaded and could not be opened");
        return;
    end
    if not self.gui.target:getIsOpen() then

        self.gui.target:setInGameMap(g_currentMission.hud:getIngameMap());
        g_gui:showDialog(self.gui.name)
    end
end

addModEventListener(MapObjectsHider);