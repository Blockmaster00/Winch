
---@class Anchor
---@field object ModGameObject
Anchor = {}
Anchor.MODEL = ""
Anchor.TEXTURE = ""

---@param pos ModVector3
---@param rotation ModVector3 | nil
function Anchor.new(pos, rotation)
    local self = setmetatable({}, {__index = Anchor})
    self.position = pos
    self.rotation = rotation or tm.vector3.Up()

    self.object = tm.physics.SpawnCustomObject(pos, Anchor.MODEL, Anchor.TEXTURE)
    -- self.object.GetTransform().SetScale()
    return self
end

return Anchor