
---@class Winch
---@field origin ModBlock
---@field target ModBlock|ModGameObject
---@field length number
---@field strength number value by which the magnitude of the force will be calculated
---@field elasticity number percentage at which the connection will snap
---@field ropeObject ModGameObject
local Winch = {}
Winch.CONNECTION_POINT = {
    ATTACHABLE_BlOCKS = {"PFB_TubeThing [Server]"},
    PREFAB = "PFB_MovePuzzleBall",
    SCALE = tm.vector3.Create(0.3, 0.3, 0.3)
    }
Winch.MODEL = "ropeModel"
Winch.TEXTURE = "ropeTexture"
Winch.DEFAULT_STRENGTH = 20
Winch.DEFAULT_ELASTICITY = 30
Winch.SPEED = 1
tm.physics.AddMesh("assets/Winch.obj", Winch.MODEL)
tm.physics.AddTexture("assets/Winch.png", Winch.TEXTURE)


---@param origin ModBlock
---@param target ModBlock|ModGameObject
---@param strength number|nil
---@param elasticity number|nil
function Winch.new(origin, target, strength, elasticity)
    local self = setmetatable({}, {__index = Winch})
    self.origin = origin
    self.target = target
    self.strength = strength or Winch.DEFAULT_STRENGTH
    self.elasticity = elasticity or Winch.DEFAULT_ELASTICITY

    local originPos = origin.GetPosition()
    local targetPos = self._getTargetPos(target)
    self.length = tm.vector3.Distance(originPos, targetPos)
    return self
end

function Winch:update()
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
    self.ropeObject.GetTransform().SetScale(0.1, 0.1, ropeLength)
    self.ropeObject.GetTransform().SetRotation(ropeRotation)
end

function Winch:_applyForces(originPos, targetPos, stretchedDistance)
    local ropeDirection = targetPos - originPos
    local force = self.strength * stretchedDistance
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
    self.length = self.length - (self.SPEED * tm.os.GetModDeltaTime())
    tm.os.Log("pulling")
end

function Winch:extend()
    self.length = self.length + (self.SPEED * tm.os.GetModDeltaTime())
    tm.os.Log("extending")
end

---@param stretchedDistance number
---@return boolean
function Winch:hasSnapped(stretchedDistance)
    if stretchedDistance > self.length *  (1 + (self.elasticity / 100)) then
        -- implement Callback functions for OnSnap?
        self:remove()
        return true
    end
    return false
end

function Winch:remove()
    self.ropeObject.Despawn()
    self = nil
end

---@param target ModGameObject|ModBlock|nil
function Winch:_getTargetPos(target)
    target = target or self.target
    local targetType = target.ToString()
    if targetType == "Trailmakers.Mods.Api.Proxies.ModBlock" then
        return target.GetPosition()
    elseif targetType == "PFB_ModGameObject [Server] (ModGameObject_Server)" then
        return target.GetTransform().GetPositionWorld()
    end
end

return Winch