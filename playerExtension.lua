-- MapObjectsHider.DebugTable("PlayerInputComponent", PlayerInputComponent)

PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(
    PlayerInputComponent.registerGlobalPlayerActionEvents,
    function(self, controlling)
        if controlling ~= "VEHICLE" then
            local inputAction = InputAction.MAP_OBJECT_HIDER_HIDE;
            local callbackTarget = self
            local callbackFunc = self.hideObjectActionEvent
            local triggerUp = false
            local triggerDown = true
            local triggerAlways = false
            local startActive = true

            local _, eventId = g_inputBinding:registerActionEvent(inputAction, callbackTarget, callbackFunc, triggerUp, triggerDown, triggerAlways, startActive);

            g_inputBinding:setActionEventText(eventId, g_i18n:getText("moh_HIDE"));
            g_inputBinding:setActionEventTextVisibility(eventId, true)
        end
end)

function PlayerInputComponent:hideObjectActionEvent(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
    MapObjectsHider.DebugText("hideObjectActionEvent(%s, %s, %s, %s, %s, %s)", actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
end