--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(
    PlayerInputComponent.registerGlobalPlayerActionEvents,
    function(self, controlling)
        if controlling ~= "VEHICLE" then
            local inputAction = InputAction.MAP_OBJECT_HIDER_HIDE;
            local callbackTarget = MapObjectsHider
            local callbackFunc = MapObjectsHider.hideObjectActionEvent
            local triggerUp = false
            local triggerDown = true
            local triggerAlways = false
            local startActive = true

            local _, eventId = g_inputBinding:registerActionEvent(inputAction, callbackTarget, callbackFunc, triggerUp, triggerDown, triggerAlways, startActive);
            g_inputBinding:setActionEventText(eventId, g_i18n:getText("moh_HIDE"));
            g_inputBinding:setActionEventTextVisibility(eventId, true);
            MapObjectsHider.currentEventId = eventId;

            inputAction = InputAction.MAP_OBJECT_HIDER_DECOLLIDE;
            callbackFunc = MapObjectsHider.decollideObjectActionEvent

            local _, event2Id = g_inputBinding:registerActionEvent(inputAction, callbackTarget, callbackFunc, triggerUp, triggerDown, triggerAlways, startActive);
            g_inputBinding:setActionEventText(event2Id, g_i18n:getText("moh_DECOLLIDE"));
            g_inputBinding:setActionEventTextVisibility(event2Id, true);
            MapObjectsHider.currentEvent2Id = event2Id;

            local targeter = self.player.targeter
            targeter:addTargetType(MapObjectsHider, CollisionFlag.BUILDING + CollisionFlag.TREE + CollisionFlag.STATIC_OBJECT, 0.5, 3)

            inputAction = InputAction.MAP_OBJECT_HIDER_GUI;
            callbackFunc = MapObjectsHider.openGui

            local _, guiEventId = g_inputBinding:registerActionEvent(inputAction, callbackTarget, callbackFunc, triggerUp, triggerDown, triggerAlways, startActive)
            g_inputBinding:setActionEventText(guiEventId, g_i18n:getText("moh_MAP_OBJECT_HIDER_GUI"));
            g_inputBinding:setActionEventTextVisibility(guiEventId, true)
            g_inputBinding:setActionEventActive(guiEventId, true);
        end
end)