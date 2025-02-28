--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

MapObjectsHiderDialog = {};
MapObjectsHiderDialog.INPUT_CONTEXT = "MapObjectsHiderDialog";

local MapObjectsHiderDialog_mt = Class(MapObjectsHiderDialog, ScreenElement);

--- create new object
-- @param table|any customMt
-- @return MapObjectsHiderDialog object
function MapObjectsHiderDialog.new(customMt)
    local newObject = ScreenElement.new(nil, customMt or MapObjectsHiderDialog_mt);

    newObject.startLoadingTime = 0;
    newObject.hiddenObjects = {};
    newObject.materialsBackup = {};

    return newObject;
end


---Callback on open
function MapObjectsHiderDialog:onOpen()
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onOpen()");
    MapObjectsHiderDialog:superClass().onOpen(self);

    self.ingameMap:onOpen()

    self.cameraId = createCamera("mohCam", math.rad(60), 0.1, 10000);
    self.mohCamera:createOverlay(self.cameraId, MapObjectsHider.mapNode);
    self:loadCamera()

    self.startLoadingTime = getTimeSec();
    RequestObjectsListEvent.sendToServer();
end

--- called when hidden object list is received from server
-- @param table hiddenObjects the objects to send
function MapObjectsHiderDialog:onHiddenObjectsReceived(hiddenObjects)
    self.hiddenObjects = hiddenObjects
    local mapNode = MapObjectsHider.mapNode
    local dateFormat = "%d/%m/%Y %H:%M:%S" -- change this based on locale
    for _, ho in pairs(self.hiddenObjects) do
        ho.id = EntityUtility.indexToNode(ho.index, mapNode);
        if ho.id == nil then
            ho.name = "Unnamed";
        else
            ho.name = getName(ho.id);
        end
        ho.datetime = getDateAt(dateFormat, 2018, 11, 20, 0, 0, 0, ho.timestamp, 0);
    end

    table.sort(
        self.hiddenObjects,
        function(a, b)
            return a.timestamp > b.timestamp
        end
    )

    MapObjectsHider.DebugText("Loaded %d hidden objects in %.2f ms", #self.hiddenObjects, (getTimeSec() - self.startLoadingTime) * 1000)

    self.mohList:setDataSource(self);
    self.mohList:reloadData(true);
end

---Get the numbers of items
-- @param table list
-- @param any section
-- @return integer number
function MapObjectsHiderDialog:getNumberOfItemsInSection(list, section)
    return #self.hiddenObjects;
end

---Get the numbers of items
-- @param table list
-- @param any section
-- @param integer index
-- @param any cell
function MapObjectsHiderDialog:populateCellForItemInSection(list, section, index, cell)
    local currentHiddenObject = self.hiddenObjects[index]

    cell:getAttribute("name"):setText(currentHiddenObject.name)
    cell:getAttribute("player"):setText(currentHiddenObject.player)
    cell:getAttribute("datetime"):setText(currentHiddenObject.datetime)
end

---Callback on close
-- @param table element
function MapObjectsHiderDialog:onClose(element)
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onClose()");

    self:hideLastHiddenObject()
    self.hiddenObjects = {}
    MapObjectsHiderDialog:superClass().onClose(self)

    self.ingameMap:onClose()
end

--- load the cam
function MapObjectsHiderDialog:loadCamera()
    local tY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, 0, 0, 0)
    self.originCameraPos = {0, tY + 1250, 0}
    self.originCameraRot = {math.rad(-90), 0, 0}
    self:resetCamera()
end

--- reset the cam to original position
function MapObjectsHiderDialog:resetCamera()
    if self.cameraId ~= nil then
        setWorldTranslation(self.cameraId, unpack(self.originCameraPos))
        setRotation(self.cameraId, unpack(self.originCameraRot))
    end
    self.mohCamera:setRenderDirty();
end

--- move the cam to the given object
-- @param integer objectId
-- @param float zoom
function MapObjectsHiderDialog:sendCameraTo(objectId, zoom)
    local x, y, z = getWorldTranslation(objectId)
    setWorldTranslation(self.cameraId, x, y + (4 * zoom), z + (4 * zoom))
    setRotation(self.cameraId, math.rad(-40), 0, 0)
    self.mohCamera:setRenderDirty();
end

---Callback on close
-- @param table element
function MapObjectsHiderDialog:onClickClose(element)
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onClickClose()");

    g_gui:closeDialogByName(MapObjectsHider.gui.name)
end

---Callback on click on restore button
function MapObjectsHiderDialog:onClickRestore()
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onClickRestore()");

    if self.currentSelectedHiddenObject ~= nil then
        ObjectShowRequestEvent.sendToServer(self.currentSelectedHiddenObject.index);

        self.startLoadingTime = getTimeSec();
        RequestObjectsListEvent.sendToServer();
    end
end

--- called when selection in a dialog list is changed
-- @param table list
-- @param integer selectedIndex
function MapObjectsHiderDialog:onListSelectionChanged(list, _, selectedIndex)
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onListSelectionChanged(%s, _, %s)", list, selectedIndex);
    if self.hiddenObjects[selectedIndex] ~= nil then
        self.currentSelectedHiddenObjectIndex = selectedIndex;
        self.currentSelectedHiddenObject = self.hiddenObjects[selectedIndex];

        MapObjectsHider.DebugText("self.currentSelectedHiddenObject.id - %s", self.currentSelectedHiddenObject.id);
        local posX, _, posY = getWorldTranslation(self.currentSelectedHiddenObject.id)
        MapObjectsHider.DebugText("getWorldTranslation - %s, %s", posX, posY);
        if posX ~= nil then
            local v84 = 650
            local v85 = 650
            if posX ~= nil then
                local v99 = posX - v84 * 0.5
                local v100 = posX + v84 * 0.5
                local v101 = posY - v85 * 0.5
                local v102 = posY + v85 * 0.5
                self.ingameMap:fitToBoundary(v99, v100, v101, v102, 0.1)
                self.ingameMap:setCenterToWorldPosition(posX, posY)
            end
        end

        self:sendCameraTo(self.currentSelectedHiddenObject.id, self:showHiddenObject(self.currentSelectedHiddenObject))
    else
        self:resetCamera();
    end
end

--- Show the hidden object for the cam and calulate best radius for view
-- @param table hiddenObject
-- @return integer bestRadius
function MapObjectsHiderDialog:showHiddenObject(hiddenObject)
    local bestRadius = -1
    EntityUtility.queryNodeHierarchy(
        hiddenObject.id,
        function(node)
            if getHasClassId(node, ClassIds.SHAPE) then
                self.materialsBackup[node] = getMaterial(node, 0)
                -- setMaterial(node, Placeable.GLOW_MATERIAL, 0)
                local _, _, _, radius = getShapeBoundingSphere(node)
                if radius > bestRadius then
                    bestRadius = radius
                end
            end
        end
    )
    setVisibility(hiddenObject.id, true)
    self.lastSelectedHiddenObject = hiddenObject
    return bestRadius
end

---hide the last shown object again
function MapObjectsHiderDialog:hideLastHiddenObject()
    if self.lastSelectedHiddenObject ~= nil then

        if not self.lastSelectedHiddenObject.onlyDecollide then
            setVisibility(self.lastSelectedHiddenObject.id, false)
        end
        EntityUtility.queryNodeHierarchy(
            self.lastSelectedHiddenObject.id,
            function(node)
                if getHasClassId(node, ClassIds.SHAPE) then
                    setMaterial(node, self.materialsBackup[node], 0)
                end
            end
        )
        self.materialsBackup = {}
        self.lastSelectedHiddenObject = nil
    end
end

---Set the IngameMap reference to use for display.
-- @param table map
function MapObjectsHiderDialog:setInGameMap(map)
    self.ingameMap:setIngameMap(map)
    self.ingameMapBase = map
    if map ~= nil then
        self.customFilter = map:createCustomFilter(true)
        self.customFilter[MapHotspot.CATEGORY_MISSION] = false
    end
end

---Callback from ui element
function MapObjectsHiderDialog:onDrawPostIngameMapHotspots()
--     MapObjectsHider.DebugText("MapObjectsHiderDialog:onDrawPostIngameMapHotspots()");
    if self.currentSelectedHiddenObject ~= nil then
--         MapObjectsHider.DebugText("self.currentSelectedHiddenObject.id - %s", self.currentSelectedHiddenObject.id);
        local posX, _, posY = getWorldTranslation(self.currentSelectedHiddenObject.id)
--         MapObjectsHider.DebugText("getWorldTranslation - %s, %s", posX, posY);
        if posX ~= nil then
            local hotspot = AbstractFieldMissionHotspot.new();
            hotspot:setWorldPosition(posX, posY);
            self.ingameMap:drawHotspot(hotspot, true)
        end
    end
end