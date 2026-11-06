--
local helpers = {}

function helpers.Normalize(v)
    local length = v.Magnitude()
    if length == 0 then
        return tm.vector3.Create(0, 0, 0)
    else
        return tm.vector3.Create(v.x / length, v.y / length, v.z / length)
    end
end

---@param point ModBlock|AttachmentTarget
function helpers.GetConnectionPointPosition(point)
    return point.GetPosition()
end

---@class AttachmentTarget
---@field handle ModBlock|ModGameObject
---@field GetPosition fun(): ModVector3
---@field GetOffset fun(): ModVector3 world-space vector from handle origin to the attach point
---@field GetIsStatic fun(): boolean

---Wraps a structure connection block into the uniform AttachmentTarget shape.
---@param block ModBlock
---@return AttachmentTarget
function helpers.WrapBlockTarget(block)
    return {
        handle = block,
        GetPosition = function() return block.GetPosition() end,
        GetOffset = function() return tm.vector3.Create(0, 0, 0) end,
        GetIsStatic = function() return false end, -- blocks have no GetIsStatic; never treated as static today
    }
end

---Wraps one of a Connectable's connection points into the uniform AttachmentTarget shape.
---@param connectable Connectable
---@param index integer
---@return AttachmentTarget
function helpers.WrapConnectableTarget(connectable, index)
    return {
        handle = connectable.object,
        GetPosition = function() return connectable:getConnectionPoints()[index] end,
        GetOffset = function()
            return connectable.object.GetTransform().TransformDirection(connectable.connectionPoints[index])
        end,
        GetIsStatic = function() return connectable.object.GetIsStatic() end,
    }
end

-- AI Function to turn direction vector into rotation quaternion
function helpers.QuaternionFromToRotation(from, to)
    from = helpers.Normalize(from)
    to = helpers.Normalize(to)
    local d = from.Dot(to)
    -- Handle opposite vectors (180 degrees)
    if d < -1 + 1e-6 then
        local axis = tm.vector3.Right().Cross(from)
        if axis.Magnitude() < 1e-6 then
            axis = tm.vector3.Forward().Cross(from)
        end
        axis = helpers.Normalize(axis)
        return tm.quaternion.Create(axis.x, axis.y, axis.z, 0)
    end
    -- Standard rotation calculation
    local s = math.sqrt((1 + d) * 2)
    local invs = 1 / s
    local c = from.Cross(to)
    return tm.quaternion.Create(c.x * invs, c.y * invs, c.z * invs, s * 0.5)
end

function helpers.TargetRot(PosHun, PosTar)
    local relativeX = PosTar.x - PosHun.x
    local relativeY = -PosTar.y + PosHun.y
    local relativeZ = PosTar.z - PosHun.z
    local angleradY = math.atan2(relativeX, relativeZ)
    local relativeangY = math.deg(angleradY)
    local relativehori = math.sqrt(relativeX * relativeX + relativeZ * relativeZ)
    local angleradX = math.atan2(relativeY, relativehori)
    local relativeangX = math.deg(angleradX)
    local relativetot = tm.vector3.Create(relativeangX, relativeangY, 0)
    return relativetot
end

function helpers.TableContains(table, value)
    if #table == 0 then
        return false
    end
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function helpers.RemoveByValue(t, value)
    for i = 1, #t do
        if t[i] == value then
            table.remove(t, i)
            return true
        end
    end
    return false
end

function helpers.RegionFixStrToVec3(value) -- "value" must be a string of 3 numbers separated by commas eg "(4.5, 6, 10.8)"
    local newValue = string.gsub(value, "%(", "[")
    newValue = string.gsub(newValue, "%)", "]")
    local vTable = {}
    vTable = json.parse(newValue)                                        -- parse string into an array table
    local vec3value = tm.vector3.Create(vTable[1], vTable[2], vTable[3]) -- create a new vector3 with individual axis data to avoid decimal separators being stripped out
    return vec3value
end

return helpers
