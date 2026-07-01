
---@class Anchor
---@field object ModGameObject
Anchor = {}
Anchor.MODEL = "AnchorModel"
Anchor.TEXTURE = "AnchorTexture"
tm.physics.AddMesh("assets/Anchor.obj", Anchor.MODEL)
tm.physics.AddTexture("assets/Anchor.png", Anchor.TEXTURE)


---@param pos ModVector3
---@param rotation ModVector3 | nil
function Anchor.new(pos, rotation)
    local self = setmetatable({}, {__index = Anchor})
    self.position = pos
    self.rotation = rotation or nil

    if self.rotation == nil then
        local raycastHit = tm.physics.RaycastData(pos + tm.vector3.Create(0, 0.5, 0), tm.vector3.Down(), 1, true)
        if not raycastHit.DidHit() then return end
        self.rotation = raycastHit.GetHitNormal()
    end
    self.object = tm.physics.SpawnCustomObject(pos, Anchor.MODEL, Anchor.TEXTURE)
    self.object.GetTransform().SetRotation(self.rotation)
    return self
end

function Anchor:remove()
    self.object.Despawn()
    self = nil
end

return Anchor