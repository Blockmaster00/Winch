local HELPERS = tm.os.DoFile("data_static/helpers")
local CONNECTABLE = tm.os.DoFile("connectable")

---@class Anchor
---@field object ModGameObject
---@field connectable Connectable
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
    self.rotation = HELPERS.QuaternionFromToRotation(tm.vector3.Up(), surfaceNormal)

    self.object = tm.physics.SpawnCustomObject(pos + surfaceNormal, Anchor.MODEL, Anchor.TEXTURE)
    self.object.GetTransform().SetRotation(self.rotation)
    self.connectable = CONNECTABLE.new(self.object, "Anchor")
    return self
end

function Anchor:remove()
    self.connectable:remove()
end

return Anchor
