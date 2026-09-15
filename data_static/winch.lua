---@class Winch
---@field playerId number
---@field origin ModBlock
---@field target ModBlock|ModGameObject
---@field length number
---@field stiffness number value by which the magnitude of the force will be calculated
---@field maxStretch number percentage at which the connection will snap
---@field ropeObject ModGameObject
---@field targetType string
local Winch = {}
Winch.CONNECTION_POINT = {
    ATTACHABLE_BlOCKS = { "PFB_TubeThing [Server]" },
    PREFAB = "PFB_MovePuzzleBall",
    SCALE = tm.vector3.Create(0.3, 0.3, 0.3)
}
Winch.MODEL = "ropeModel"
Winch.TEXTURE = "ropeTexture"
Winch.COLORS_BY_PLAYER = {
    [0] = "cyan",
    [1] = "orange",
    [2] = "neon",
    [3] = "blue",
    [4] = "yellow",
    [5] = "purple",
    [6] = "pastel",
    [7] = "pink",
}
Winch.stiffness = 10
Winch.maxStretch = 150
Winch.speed = 1
tm.physics.AddMesh("assets/winch/winch.obj", Winch.MODEL)
tm.physics.AddTexture("assets/winch/winch.png", Winch.TEXTURE)
for k, color in pairs(Winch.COLORS_BY_PLAYER) do
    tm.physics.AddTexture("assets/winch/winch" .. "_" .. color .. ".png", Winch.TEXTURE .. "-" .. color)
end

---@param playerId number
---@param origin ModBlock
---@param target ModBlock|ModGameObject
---@param stiffness number|nil
---@param maxStretch number|nil
function Winch.new(playerId, origin, target, stiffness, maxStretch, speed)
    local self = setmetatable({
        playerId = playerId,
        origin = origin,
        target = target,
        stiffness = stiffness,
        maxStretch = maxStretch,
        speed = speed,
        targetType = target.ToString()
    }, { __index = Winch })

    local originPos = origin.GetPosition()
    local targetPos = self:_getTargetPos()
    self.length = tm.vector3.Distance(originPos, targetPos)
    return self
end

function Winch:update()
    if not self.origin.Exists() then
        self:remove()
        if self.OnSnapCallback ~= nil then
            self.callbackData = self.callbackData or {}
            self.callbackData.info = "Winch block no longer exists."
            self.OnSnapCallback(self.callbackData)
        end
        return
    end
    if not self.target.Exists() then
        self:remove()
        if self.OnSnapCallback ~= nil then
            self.callbackData = self.callbackData or {}
            self.callbackData.info = "Target object no longer exists."
            self.OnSnapCallback(self.callbackData)
        end
        return
    end
    local originPos = self.origin.GetPosition()
    local targetPos = self:_getTargetPos()
    local ropeLength = tm.vector3.Distance(originPos, targetPos)
    local stretchedDistance = math.max(ropeLength - self.length, 0)

    if self:hasSnapped(stretchedDistance) then return end

    self:_visualize(originPos, targetPos, ropeLength)
    self:_applyForces(originPos, targetPos, stretchedDistance)
end

function Winch:_visualize(originPos, targetPos, ropeLength)
    local ropeRotation = TargetRot(originPos, targetPos)
    local ropePos = (originPos + targetPos) / 2
    if self.ropeObject == nil then
        self.ropeObject = tm.physics.SpawnCustomObjectRigidbody(ropePos, Winch.MODEL, Winch.TEXTURE, true, 1, "Asphalt")
        self.ropeObject.SetIsTrigger(true)
    end
    self.ropeObject.GetTransform().SetPosition(ropePos)
    self.ropeObject.GetTransform().SetScale(0.3, 0.3, ropeLength)
    self.ropeObject.GetTransform().SetRotation(ropeRotation)
end

function Winch:_applyForces(originPos, targetPos, stretchedDistance)
    local ropeDirection = targetPos - originPos
    local force = self.stiffness * stretchedDistance
    local targetType = self.target.ToString()
    if targetType == "PFB_ModGameObject [Server] (ModGameObject_Server)" then
        if self.target.GetIsStatic() then
            local originForce = ropeDirection * force
            self.origin.AddForce(originForce.x, originForce.y, originForce.z)
            return -- skips force distribution
        end
    end
    force = force / 2
    local targetForce = ((ropeDirection * -1) * force)
    self.target.AddForce(targetForce.x, targetForce.y, targetForce.z)
    local originForce = ropeDirection * force
    self.origin.AddForce(originForce.x, originForce.y, originForce.z)
end

function Winch:pull()
    self.length = self.length - (self.speed * tm.os.GetModDeltaTime())
end

function Winch:extend()
    self.length = self.length + (self.speed * tm.os.GetModDeltaTime())
end

---@param stretchedDistance number
---@return boolean
function Winch:hasSnapped(stretchedDistance)
    if stretchedDistance > self.length * (self.maxStretch / 100) then
        if self.OnSnapCallback ~= nil then
            self.callbackData.stretchedDistance = stretchedDistance
            self.OnSnapCallback(self.callbackData)
        end
        self:remove()
        return true
    end
    return false
end

function Winch:remove()
    self.ropeObject.Despawn()
end

function Winch:_getTargetPos()
    if self.targetType == "Trailmakers.Mods.Api.Proxies.ModBlock" then
        return self.target.GetPosition()
    elseif self.targetType == "PFB_ModGameObject [Server] (ModGameObject_Server)" then
        return self.target.GetTransform().GetPositionWorld()
    end
end

function Winch:AddOnSnapCallback(playerId, callbackFunction, callbackData)
    self.OnSnapCallback = callbackFunction
    self.callbackData = callbackData
    self.callbackData.playerId = playerId
end

function Winch:Highlight()
    tm.os.Log(self.playerId)
    local color = Winch.COLORS_BY_PLAYER[self.playerId]
    tm.os.Log(color)
    self.ropeObject.SetTexture(Winch.TEXTURE .. "-" .. color)
end

function Winch:RemoveHighlight()
    self.ropeObject.SetTexture(Winch.TEXTURE)
end

return Winch
