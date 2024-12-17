MapObjectsHiderDialog = {};
MapObjectsHiderDialog.INPUT_CONTEXT = "MapObjectsHiderDialog"

local MapObjectsHiderDialog_mt = Class(MapObjectsHiderDialog, ScreenElement)

--- create new object
-- @param table target
-- @return table object
function MapObjectsHiderDialog.new(target)
    local newObject = ScreenElement.new(nil, target or MapObjectsHiderDialog_mt);

    return newObject;
end

---Callback on open
function MapObjectsHiderDialog:onOpen()
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onOpen()");
    MapObjectsHiderDialog:superClass().onOpen(self);

    self.hiddenObjects = MapObjectsHider.hiddenObjects;

--     self.mohList:deleteListItems();
    self.mohList:setDataSource(self);
    self.mohList:reloadData(true);
    MapObjectsHider.DebugTable("self.hiddenObjects", self.hiddenObjects)

--     self:toggleCustomInputContext(true, MapObjectsHiderDialog.INPUT_CONTEXT)
--     self:registerActionEvents()--     self:registerActionEvents()
end

function MapObjectsHiderDialog:getNumberOfItemsInSection(list, selection)
    return #self.hiddenObjects;
end

function MapObjectsHiderDialog:populateCellForItemInSection(list, section, index, cell)
    local currentHiddenObject = self.hiddenObjects[index]

    cell:getAttribute("name"):setText(currentHiddenObject.name)
    cell:getAttribute("player"):setText(currentHiddenObject.player)
    cell:getAttribute("date"):setText(currentHiddenObject.date)
    cell:getAttribute("time"):setText(currentHiddenObject.time)
end

---Callback on close
-- @param table element
function MapObjectsHiderDialog:onClose(element)
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onClose()");

    MapObjectsHiderDialog:superClass().onClose(self)
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
-- @return boolean is the event unused?
function MapObjectsHiderDialog:onClickRestore()
    MapObjectsHider.DebugText("MapObjectsHiderDialog:onClickRestore()");
--     local eventUnused = MapObjectsHiderDialog:superClass().onClickCancel(self);
--     local selectedElement, selectedIndex = self.mohList:getSelectedElement()
--     if selectedElement ~= nil then
--         self:hideLastHiddenObject()
--         local selectedHiddenObject = self.hiddenObjects[selectedIndex]
--         ArrayUtility.removeAt(self.hiddenObjects, selectedIndex)
--         ObjectShowRequestEvent.sendToServer(selectedHiddenObject.index)
--         self.mohList:removeElement(selectedElement)
--         self.mohList:updateItemPositions()
--         self.mohList:setSelectedIndex(selectedIndex, true)
--         eventUnused = false
--     end
--     return eventUnused
end

function MapObjectsHiderDialog:registerActionEvents()
--     g_inputBinding:registerActionEvent(InputAction.AXIS_MTO_SCROLL, self, self.onInputScrollMTO, false, false, true, true)
end

---Remove non-GUI input action events.
function MapObjectsHiderDialog:removeActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)
end