--[[
--DE--
Teil des Map Object Hider für den LS22/LS25 von Achimobil aufgebaut auf den Skripten von Royal Modding aus dem LS 19.
Kopieren und wiederverwenden ob ganz oder in Teilen ist untersagt.

--EN--
Part of the Map Object Hider for the FS22/FS25 by Achimobil based on the scripts by Royal Modding from the LS 19.
Copying and reusing in whole or in part is prohibited.

Skript version 0.3.0.0 of 21.12.2024
]]

CameraElement = {}
local CameraElement_mt = Class(CameraElement, GuiElement);
Gui.registerGuiElement("Camera", CameraElement)

--- create a new object
-- @param table target
-- @param table? custom_mt
-- @return RenderElement self
function CameraElement.new(target, custom_mt)
    local self = GuiElement.new(target, custom_mt or CameraElement_mt);

    -- overlay attributes
    self.cameraId = nil;
    self.overlay = nil;
    self.useAlpha = true;
    self.superSamplingFactor = 1;
    self.shapesMask = 255;
    self.lightMask = 67108864;
    self.renderShadows = false
    self.bloomQuality = 0
    self.enableDof = false
    self.ssaoQuality = 0
    self.asyncShaderCompilation = false
    self.isRenderDirty = false;

    return self
end

---delete the object
function CameraElement:delete()
    self:destroyOverlay()
    CameraElement:superClass().delete(self)
end

--- load from xml of the ui
-- @param entityId xmlFile
-- @param string key
function CameraElement:loadFromXML(xmlFile, key)
    CameraElement:superClass().loadFromXML(self, xmlFile, key)

    self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor") or self.superSamplingFactor
    self.shapesMask = getXMLInt(xmlFile, key .. "#shapesMask") or self.shapesMask
    self.lightsMask = getXMLInt(xmlFile, key .. "#lightsMask") or self.lightsMask
end

--- load profile data
-- @param table profile
-- @param boolean applyProfile
function CameraElement:loadProfile(profile, applyProfile)
    CameraElement:superClass().loadProfile(self, profile, applyProfile)

    self.superSamplingFactor = profile:getNumber("superSamplingFactor", self.superSamplingFactor)
    self.shapesMask = profile:getNumber("shapesMask", self.shapesMask)
    self.lightsMask = profile:getNumber("lightsMask", self.lightsMask)
end

---Copy the attributes to other element
-- @param table src
function CameraElement:copyAttributes(src)
    CameraElement:superClass().copyAttributes(self, src)

    self.superSamplingFactor = src.superSamplingFactor
    self.shapesMask = src.shapesMask
    self.lightsMask = src.lightsMask
end

---Create the overlay with given cam
-- @param integer cameraNodeId
-- @param integer sceneNodeId
function CameraElement:createOverlay(cameraNodeId, sceneNodeId)
    self.cameraId = cameraNodeId;
    self.scene = sceneNodeId;

    if self.overlay ~= nil then
        delete(self.overlay)
        self.overlay = nil
    end

    -- Use downsampling to imitate anti-aliasing, as the postFx for it is not available
    -- on render overlays
    local resolutionX = math.ceil(g_screenWidth * self.absSize[1]) * self.superSamplingFactor
    local resolutionY = math.ceil(g_screenHeight * self.absSize[2]) * self.superSamplingFactor

    local aspectRatio = resolutionX / resolutionY

--     local overlay = createRenderOverlay(self.cameraId, aspectRatio, resolutionX, resolutionY, true, self.shapesMask, self.lightsMask)
--     self.overlay = createRenderOverlay(self.cameraId, aspectRatio, resolutionX, resolutionY, true, self.shapesMask, self.lightsMask)
    local overlay = createRenderOverlay(self.scene, self.cameraId, aspectRatio, resolutionX, resolutionY, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation)
    MapObjectsHider.DebugText("CameraElement overlay - %s", overlay);
    if overlay == 0 then
        Logging.error("Could not create render overlay for scene '%s'", self.filename)
        return
    end

    self.overlay = overlay

    self.isRenderDirty = true;
end

---Destroy the overlay
function CameraElement:destroyOverlay()
    if self.overlay ~= nil then
        delete(self.overlay);
        self.overlay = nil;
    end
end

---Redraws the scene to the overlay if set dirty
-- @param float dt
function CameraElement:update(dt)
    CameraElement:superClass().update(self, dt)

    if self.isRenderDirty and self.overlay ~= nil then
        updateRenderOverlay(self.overlay)
        self.isRenderDirty = false
    end
end

---Draws overlay with current content, to redraw/render the scene to the overlay it needs to be set dirty via setRenderDirty()
-- @param float? clipX1 [0..1]
-- @param float? clipY1 [0..1]
-- @param float? clipX2 [0..1]
-- @param float? clipY2 [0..1]
function CameraElement:draw(clipX1, clipY1, clipX2, clipY2)
    if self.overlay ~= nil then
        local u1, v1, u2, v2, u3, v3, u4, v4 = 0, 0, 0, 1, 1, 0, 1, 1;
        setOverlayUVs(self.overlay, u1, v1, u2, v2, u3, v3, u4, v4);
        renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]);
    end
    CameraElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2);
end

---A render element can't get UI focus
-- @return boolean canReceiveFocus
function CameraElement:canReceiveFocus()
    return false
end

---Set overlay dirty causing it to be updated / redrawn from current scene in the update loop
function CameraElement:setRenderDirty()
    self.isRenderDirty = true
end
