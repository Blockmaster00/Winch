---@class Anchor
---@field object ModGameObject
local Anchor = {}
Anchor.MODEL = "AnchorModel"
Anchor.TEXTURE = "AnchorTexture"
tm.physics.AddMesh("assets/anchor/Anchor.obj", Anchor.MODEL)
tm.physics.AddTexture("assets/anchor/Anchor.png", Anchor.TEXTURE)


---@param pos ModVector3
---@param surfaceNormal ModVector3
function Anchor.new(pos, surfaceNormal)
    local self = setmetatable({}, { __index = Anchor })
    self.position = pos
    self.rotation = QuaternionFromToRotation(tm.vector3.Up(), surfaceNormal)

    self.object = tm.physics.SpawnCustomObject(pos + surfaceNormal, Anchor.MODEL, Anchor.TEXTURE)
    self.object.GetTransform().SetRotation(self.rotation)
    return self
end

function Anchor:remove()
    self.object.Despawn()
end

return Anchor
