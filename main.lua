tm.os.SetModTargetDeltaTime(1/60)
tm.physics.AddMesh("", "ropeModel")
tm.physics.AddTexture("", "ropeTexture")

local playerData = {}
local spawnedObjects = {}


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
    table.insert(spawnedObjects, self.object)
    -- self.object.GetTransform().SetScale()
    return self
end


function PlayerUpdate(player)
    local playerDataTable = playerData[player.playerId]
    if playerDataTable.playersWinch ~= nil then
        playerDataTable.playersWinch:update()
        if playerDataTable.isPulling then
            playerDataTable.playersWinch:pull()
        elseif playerDataTable.isExtending then
            playerDataTable.playersWinch:extend()
        end
    elseif playerDataTable.connectingWinch then
        for point, visualizer in pairs(playerDataTable.connectionPoints) do
            local pointPos
            if point.ToString() == "Trailmakers.Mods.Api.Proxies.ModBlock"then
                pointPos = point.GetPosition()
            else
                pointPos = point.GetTransform().GetPositionWorld()
            end
            visualizer.GetTransform().SetPosition(pointPos)
        end
    end
end

function update()
    local playerList = tm.players.CurrentPlayers()
    for key, player in ipairs(playerList) do
        PlayerUpdate(player)
    end
end

function OnPlayerAttachDetachWinch(playerId)
    if playerData[playerId].chatOpen then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].playersWinch:remove()
        playerData[playerId].playersWinch = nil
        return
    end

    if not playerData[playerId].connectingWinch then
        playerData[playerId].connectingWinch = true
        playerData[playerId].connectionPoints = {}
        local playerStructure = tm.players.GetPlayerSeatBlock(playerId).GetStructure()
        local blockList = GetAllConnectionPointsOnStructure(playerStructure)

        for key, block in ipairs(blockList) do
            local visualizer = tm.physics.SpawnObject(block.GetPosition(), Winch.CONNECTION_POINT.PREFAB)
            visualizer.GetTransform().SetScale(Winch.CONNECTION_POINT.SCALE)
            visualizer.SetIsStatic(true)
            visualizer.SetIsTrigger(true)
            playerData[playerId].connectionPoints[block] = visualizer
        end
        return
    else
        playerData[playerId].connectingWinch = false
        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

function SelectConnectionPoint(playerId, position)
    if not playerData[playerId].connectingWinch then
        return
    end
    local closest = {
        point = nil,
        distance = math.huge
    }
    tm.os.Log("Starting")
    for point, visualizer in pairs(playerData[playerId].connectionPoints) do
        local pointPos
        tm.os.Log("hmm")
        if point.ToString() == "Trailmakers.Mods.Api.Proxies.ModBlock"then
            pointPos = point.GetPosition()
        else
            pointPos = point.GetTransform().GetPositionWorld()
        end

        local distanceToPoint = tm.vector3.Distance(pointPos, position)
        if distanceToPoint <= 10 and distanceToPoint < closest.distance then
            tm.os.Log("found".. point.ToString())
            closest = {
                point = point,
                distance = distanceToPoint
            }
        end
    end
    if closest.point == nil then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Try again.", "can't find closest point.", 5)
        return
    end
    if playerData[playerId].selectedConnectionPoint == nil then
        playerData[playerId].selectedConnectionPoint = closest.point

        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].connectionPoints = {}

        local playerStructure = tm.players.GetPlayerSeatBlock(playerId).GetStructure()
        local connectionPoints = GetAllConnectionPointsInRange(playerStructure.GetPosition(), 50, {playerStructure})

        for key, connectionPoint in ipairs(connectionPoints) do
            local pos
            if connectionPoint.ToString() == "Trailmakers.Mods.Api.Proxies.ModBlock"then
                pos = connectionPoint.GetPosition()
            else
                pos = connectionPoint.GetTransform().GetPositionWorld()
            end
            local visualizer = tm.physics.SpawnObject(pos , Winch.CONNECTION_POINT.PREFAB)
            visualizer.GetTransform().SetScale(Winch.CONNECTION_POINT.SCALE)
            visualizer.SetIsStatic(true)
            visualizer.SetIsTrigger(true)
            playerData[playerId].connectionPoints[connectionPoint] = visualizer
        end
    else
        playerData[playerId].playersWinch = Winch.new(playerData[playerId].selectedConnectionPoint, closest.point)
        playerData[playerId].connectingWinch = false
        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

function PlaceAnchor(playerId, position)
    local anchor = Anchor.new(position)
end


function OnPlayerClick(callback)
    local playerId = callback.playerId
    local position = tm.vector3.Create(callback.value)
    if playerData[playerId].connectingWinch then
        SelectConnectionPoint(playerId, position)
    elseif playerData[playerId].placingAnchor then
        PlaceAnchor(playerId, position)
    end
end

function OnPlayerPlaceRemoveAnchor(playerId)
    if playerData[playerId].chatOpen then return end
    playerData[playerId].placingAnchor = not playerData[playerId].placingAnchor
end

function OnPlayerPullWinchStart(playerId)
    if playerData[playerId].chatOpen then return end
    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isPulling = true
    end
end

function OnPlayerExtendWinchStart(playerId)
    if playerData[playerId].chatOpen then return end
    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isExtending = true
    end
end

function OnPlayerPullWinchStop(playerId)
    if playerData[playerId].chatOpen then return end
    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isPulling = false
    end
end

function OnPlayerExtendWinchStop(playerId)
    if playerData[playerId].chatOpen then return end
    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isExtending = false
    end
end

function OnOpenCloseChat(playerId)
    playerData[playerId].chatOpen = not playerData[playerId].chatOpen
end

function OnPlayerJoined(player)
    local playerId = player.playerId
    local spawnPosition = tm.players.GetPlayerTransform(playerId).GetPositionWorld() + tm.vector3.Create(0, 4, 0)
    table.insert(spawnedObjects, tm.physics.SpawnCustomObjectRigidbody(spawnPosition, "ropeModel", "ropeTexture", false, 1, "Asphalt"))
    playerData[playerId] = {
        playersWinch = nil,
        isExtending = false,
        isPulling = false,
        placingAnchor = false,
        anchors = {},
        connectingWinch = false,
        connectionPoints = {},
        selectedConnectionPoint = nil,
        chatOpen = false,
        infoBox = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Press <sprite=123> for Winch", "Press <sprite=> for Anchors"),
    }
    tm.playerUI.RegisterMouseDownPositionCallback(playerId, OnPlayerClick)

    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnOpenCloseChat", "enter")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnPlayerAttachDetachWinch", "v")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnPlayerPlaceRemoveAnchor", "t")

    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnPlayerPullWinchStart", "q")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnPlayerExtendWinchStart", "e")
    tm.input.RegisterFunctionToKeyUpCallback(playerId, "OnPlayerPullWinchStop", "q")
    tm.input.RegisterFunctionToKeyUpCallback(playerId, "OnPlayerExtendWinchStop", "e")

end
tm.players.OnPlayerJoined.add(OnPlayerJoined)

function GetAllConnectionPointsInRange(pos, range, excludedStructures)
    range = range or 50
    excludedStructures = excludedStructures or {}
    local playerList = tm.players.CurrentPlayers()
    local connectionPoints = {}
    for i, player in ipairs(playerList) do
        for j, structure in ipairs(tm.players.GetPlayerStructures(player.playerId)) do
            if (not TableContains(excludedStructures, structure)) and tm.vector3.Distance(structure.GetPosition(), pos) < range then
                local connectionPointsOnStructure = GetAllConnectionPointsOnStructure(structure)
                for k, point in ipairs(connectionPointsOnStructure) do
                    table.insert(connectionPoints, point)
                end
            end
        end
    end
    for i, object in ipairs(spawnedObjects) do
        if tm.vector3.Distance(object.GetTransform().GetPositionWorld(), pos) < range then
            table.insert(connectionPoints, object)
        end
    end
    return connectionPoints
end

function GetAllConnectionPointsOnStructure(structure)
    local blockList = structure.GetBlocks()
    local connectionPoints = {}
    for key, block in ipairs(blockList) do
        if TableContains(Winch.CONNECTION_POINT.ATTACHABLE_BlOCKS, block.GetName()) then
            table.insert(connectionPoints, block)
        end
    end
    return connectionPoints
end

function Normalize(v)
    local length = v.Magnitude()
    if length == 0 then
        return tm.vector3.Create(0, 0, 0)
    else
        return tm.vector3.Create(v.x / length, v.y / length, v.z / length)
    end
end

function TargetRot(PosHun, PosTar)
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

function TableContains(table, value)
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