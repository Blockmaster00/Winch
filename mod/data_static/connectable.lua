local HELPERS = tm.os.DoFile("data_static/helpers")

local CONNECTION_MAPS_PATH = "connectionMaps.json"

local function parseConnectionMaps()
    local success, data = pcall(function()
        local fileText = tm.os.ReadAllText_Static(CONNECTION_MAPS_PATH)
        if fileText == nil or fileText == "" then
            return {}
        end

        local parsed = json.parse(fileText)
        if parsed == nil then
            return {}
        end

        for key, value in pairs(parsed) do
            for i, point in ipairs(value) do
                value[i] = tm.vector3.Create("(" .. point .. ")")
            end
        end

        return parsed
    end)
    if success and data then
        return data
    else
        return {}
    end
end

---@class Connectable
---@field object ModGameObject
---@field name string
---@field connectionPoints table<ModVector3>
local Connectable = {}
Connectable.CONNECTION_POINTS = parseConnectionMaps()

local connectableObjects = {}

-- Connectable represents an object that can be connected to by a winch.
-- every connectable has a atleast one connection point as defined in connectionMaps.json
-- a connectable can be a static object like an anchor or a dynamic object like a box or other movable item.
-- Connectables are used in the game to define points where winches can attach and interact with objects.
-- the connectionPoints table defines the offset of the connection points relative to the object's position.


---@param objectReference ModGameObject
---@param name string
function Connectable.new(objectReference, name)
    local self = setmetatable({}, { __index = Connectable })
    self.object = objectReference
    self.name = name
    self.connectionPoints = Connectable.CONNECTION_POINTS[name] or
        { tm.vector3.Create(0, 0, 0) }
    table.insert(connectableObjects, self)
    return self
end

function Connectable:getConnectionPoints()
    -- returns the world coordinates of the connection points relative to the object's position and orientation.
    local worldConnectionPoints = {}
    local objectTransform = self.object.GetTransform()
    for _, localPoint in ipairs(self.connectionPoints) do
        local worldPoint = objectTransform.TransformPoint(localPoint)
        table.insert(worldConnectionPoints, worldPoint)
    end
    return worldConnectionPoints
end

function Connectable:remove()
    HELPERS.RemoveByValue(connectableObjects, self)
    self.object.Despawn()
    self = nil
end

function Connectable.GetAll()
    return connectableObjects
end

return Connectable
