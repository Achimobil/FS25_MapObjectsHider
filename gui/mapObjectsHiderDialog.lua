MapObjectsHiderDialog = {};
MapObjectsHiderDialog.INPUT_CONTEXT = "MapObjectsHiderDialog"

local MapObjectsHiderDialog_mt = Class(MapObjectsHiderDialog, ScreenElement)

--- create new object
-- @param table target
-- @return table object
function MapObjectsHiderDialog.new(target)
    local newObject = ScreenElement.new(nil, target or MapObjectsHiderDialog_mt);

    newObject.startLoadingTime = 0;
    newObject.hiddenObjects = {};

    return newObject;
end

---Callback on open
function MapObjectsHiderDialog:onOpen()
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onOpen()");
    MapObjectsHiderDialog:superClass().onOpen(self);

    self.startLoadingTime = getTimeSec();
    RequestObjectsListEvent.sendToServer();

    self.ingameMap:onOpen()
--     self:toggleCustomInputContext(true, MapObjectsHiderDialog.INPUT_CONTEXT)
--     self:registerActionEvents()--     self:registerActionEvents()
end

--- called when hidden object list is received from server
-- @param table hiddenObjects the objects to send
function MapObjectsHiderDialog:onHiddenObjectsReceived(hiddenObjects)
    self.hiddenObjects = hiddenObjects
    local mapNode = MapObjectsHider.mapNode
    local dateFormat = "%d/%m/%Y %H:%M:%S" -- change this based on locale
    for _, ho in pairs(self.hiddenObjects) do
        ho.id = EntityUtility.indexToNode(ho.index, mapNode)
        ho.name = getName(ho.id)
        ho.datetime = getDateAt(dateFormat, 2018, 11, 20, 0, 0, 0, ho.timestamp, 0)
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

    MapObjectsHiderDialog:superClass().onClose(self)

    self.ingameMap:onClose()
--     self.controller:reset()

--     self:removeActionEvents()
--     self:toggleCustomInputContext(false, MapObjectsHiderDialog.INPUT_CONTEXT)
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

function MapObjectsHiderDialog:registerActionEvents()
--     g_inputBinding:registerActionEvent(InputAction.AXIS_MTO_SCROLL, self, self.onInputScrollMTO, false, false, true, true)
end

---Remove non-GUI input action events.
function MapObjectsHiderDialog:removeActionEvents()
--     g_inputBinding:removeActionEventsByTarget(self)
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
--                 local posX, posY = hotspot:getWorldPosition()
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

    end
end

function MapObjectsHiderDialog:setInGameMap(map)
    self.ingameMap:setIngameMap(map)
    self.ingameMapBase = map
    if map ~= nil then
        self.customFilter = map:createCustomFilter(true)
        self.customFilter[MapHotspot.CATEGORY_MISSION] = false
    end
end

function MapObjectsHiderDialog:onDrawPostIngameMapHotspots()
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onDrawPostIngameMapHotspots()");
    if self.currentSelectedHiddenObject ~= nil then
        MapObjectsHider.DebugText("self.currentSelectedHiddenObject.id - %s", self.currentSelectedHiddenObject.id);
        local posX, _, posY = getWorldTranslation(self.currentSelectedHiddenObject.id)
        MapObjectsHider.DebugText("getWorldTranslation - %s, %s", posX, posY);
        if posX ~= nil then
            local hotspot = AbstractFieldMissionHotspot.new();
            hotspot:setWorldPosition(posX, posY);
            self.ingameMap:drawHotspot(hotspot, true)
        end
    end
end