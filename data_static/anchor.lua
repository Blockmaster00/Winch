---@class Anchor
---@field object ModGameObject
local Anchor = {}
Anchor.MODEL = "AnchorModel"
Anchor.TEXTURE = "AnchorTexture"
tm.physics.AddMesh("assets/Anchor.obj", Anchor.MODEL)
tm.physics.AddTexture("assets/Anchor.png", Anchor.TEXTURE)


---@param pos ModVector3
---@param rotation ModVector3
function Anchor.new(pos, rotation)
    local self = setmetatable({}, { __index = Anchor })
    self.position =
        pos --offset position up relative to surface normal. (since Anchor mesh has its pivot point at the top of the model)
    self.rotation = rotation or nil

    self.object = tm.physics.SpawnCustomObject(pos, Anchor.MODEL, Anchor.TEXTURE)
    self.object.GetTransform().SetRotation(self.rotation)
    return self
end

function Anchor:remove()
    self.object.Despawn()
end

return Anchor
