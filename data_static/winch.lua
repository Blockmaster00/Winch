
---@class Winch
---@field origin ModBlock
---@field target ModBlock|ModGameObject
---@field length number
---@field strength number
---@field elasticity number
---@field ropeObject ModGameObject
---@field connectionMode string "'BLOCK' | 'GAME_OBJECT'"
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
    local targetType = target.ToString()
    if targetType == "Trailmakers.Mods.Api.Proxies.ModBlock" then
        self.connectionMode = "BLOCK"
    elseif targetType == "PFB_ModGameObject [Server] (ModGameObject_Server)" then
        self.connectionMode = "GAME_OBJECT"
    else
        return
    end

    local targetPos
    if self.connectionMode == "BLOCK" then
        targetPos = self.target.GetPosition()
    elseif self.connectionMode == "GAME_OBJECT" then
        targetPos = self.target.GetTransform().GetPositionWorld()
    end
    local originPos = origin.GetPosition()
    self.length = tm.vector3.Distance(originPos, targetPos)
    return self
end

function Winch:_getTargetPos()
    if self.connectionMode == "BLOCK" then
        return self.target.GetPosition()
    elseif self.connectionMode == "GAME_OBJECT" then
        return self.target.GetTransform().GetPositionWorld()
    end
end

function Winch:update()
    --visualize
    local originPos = self.origin.GetPosition()
    local targetPos = self:_getTargetPos()

    local ropePos = (originPos + targetPos) / 2
    local ropeLength = tm.vector3.Distance(originPos, targetPos)
    local ropeRotation = TargetRot(originPos, targetPos)

    if self.ropeObject == nil then
        self.ropeObject = tm.physics.SpawnCustomObjectRigidbody(ropePos, Winch.MODEL, Winch.TEXTURE, true, 1, "Asphalt")
        self.ropeObject.SetIsTrigger(true)
    end
    self.ropeObject.GetTransform().SetPosition(ropePos)
    self.ropeObject.GetTransform().SetScale(0.1, 0.1, ropeLength)
    self.ropeObject.GetTransform().SetRotation(ropeRotation)

    --calculate and apply forces
    local ropeDirection = targetPos - originPos
    local stretchedDistance = math.max(ropeLength - self.length, 0)

    if stretchedDistance > self.length *  (1 + (self.elasticity / 100)) then
        self:remove()
        return
    end

    local force = self.strength * stretchedDistance

    if self.connectionMode == "GAME_OBJECT" then
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
    self.length = self.length - (Winch.SPEED * tm.os.GetModDeltaTime())
    tm.os.Log("pulling")
end

function Winch:extend()
    self.length = self.length + (Winch.SPEED * tm.os.GetModDeltaTime())
    tm.os.Log("extending")
end

function Winch:remove()
    self.ropeObject.Despawn()
end

return Winch