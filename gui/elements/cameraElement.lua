--- Map Objects Hider

---@author Duke of Modding
---@version 1.2.0.0
---@date 09/04/2021

---@class CameraElement : Class
---@field addCallback function
---@field raiseCallback function
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
    self.isRenderDirty = false;
    self.overlay = 0;
    self.superSamplingFactor = 1;
    self.shapesMask = 255;
    self.lightsMask = 16711680;

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

    self:addCallback(xmlFile, key .. "#onCameraLoad", "onCameraLoadCallback")
end

--- load profile data
-- @param table profile
-- @param boolean applyProfile
function CameraElement:loadProfile(profile, applyProfile)
    CameraElement:superClass().loadProfile(self, profile, applyProfile)

    self.superSamplingFactor = profile:getNumber("superSamplingFactor", self.superSamplingFactor)
    self.shapesMask = profile:getNumber("shapesMask", self.shapesMask)
    self.lightsMask = profile:getNumber("lightsMask", self.lightsMask)

    if applyProfile then
        self:setScene(self.filename)
    end
end

---Copy the attributes to other element
-- @param table src
function CameraElement:copyAttributes(src)
    CameraElement:superClass().copyAttributes(self, src)

    self.superSamplingFactor = src.superSamplingFactor
    self.shapesMask = src.shapesMask
    self.lightsMask = src.lightsMask
end

---@param cameraNode integer
function CameraElement:createOverlay(cameraNode)
    self.cameraId = cameraNode

    if self.overlay ~= nil then
        delete(self.overlay)
        self.overlay = nil
    end

    -- Use downsampling to imitate anti-aliasing, as the postFx for it is not available
    -- on render overlays
    local resolutionX = math.ceil(g_screenWidth * self.absSize[1]) * self.superSamplingFactor
    local resolutionY = math.ceil(g_screenHeight * self.absSize[2]) * self.superSamplingFactor

    local aspectRatio = resolutionX / resolutionY

    local overlay = createRenderOverlay(self.cameraId, aspectRatio, resolutionX, resolutionY, true, self.shapesMask, self.lightsMask)
--     self.overlay = createRenderOverlay(self.cameraId, aspectRatio, resolutionX, resolutionY, true, self.shapesMask, self.lightsMask)
--     local overlay = createRenderOverlay(self.scene, self.cameraId, aspectRatio, resolutionX, resolutionY, self.useAlpha, self.shapesMask, self.lightMask, self.renderShadows, self.bloomQuality, self.enableDof, self.ssaoQuality, self.asyncShaderCompilation)

    if overlay == 0 then
        Logging.error("Could not create render overlay for scene '%s'", self.filename)
        return
    end

    self.overlay = overlay

    self.isRenderDirty = true

    self:raiseCallback("onCameraLoadCallback", self.cameraId, self.overlay)
end

function CameraElement:destroyOverlay()
    if self.overlay ~= 0 then
        delete(self.overlay)
        self.overlay = 0
    end
end

---Redraws the scene to the overlay if set dirty
-- @param float dt
function CameraElement:update(dt)
    CameraElement:superClass().update(self, dt)

    if self.isRenderDirty and self.overlay ~= 0 then
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
    if self.overlay ~= 0 then
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
