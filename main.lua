tm.os.SetModTargetDeltaTime(1 / 60)

local Winch = tm.os.DoFile("winch")
local Anchor = tm.os.DoFile("anchor")

local playerData = {}
local spawnedObjects = {}

function PlayerUpdate(player)
    local playerDataTable = playerData[player.playerId]

    if playerDataTable.playersWinch ~= nil then
        playerDataTable.playersWinch:update()
        if playerDataTable.isPulling then
            playerDataTable.playersWinch:pull()
            tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, playerDataTable.infoBox,
                "Pulling Winch" .. string.rep(".", (math.floor(tm.os.GetRealtimeSinceStartup()) % 4)))
        elseif playerDataTable.isExtending then
            playerDataTable.playersWinch:extend()
            tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, playerDataTable.infoBox,
                "Extending Winch" .. string.rep(".", (math.floor(tm.os.GetRealtimeSinceStartup()) % 4)))
        else
            tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, playerDataTable.infoBox, "Winch connected.")
        end
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(player.playerId, playerDataTable.infoBox,
            "length: " .. string.format("%.2f", playerDataTable.playersWinch.length) .. "m")
    elseif playerDataTable.connectingWinch then
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, playerDataTable.infoBox,
            "Select a connection point.")
        for point, visualizer in pairs(playerDataTable.connectionPoints) do
            local pointPos = GetConnectionPointPosition(point)
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
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].playersWinch:remove()
        playerData[playerId].playersWinch = nil
        return
    end

    if not playerData[playerId].connectingWinch then
        playerData[playerId].connectingWinch = true
        playerData[playerId].connectionPoints = {}
        local playerStructure = tm.players.OccupiedStructure(playerId)
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
    for point, visualizer in pairs(playerData[playerId].connectionPoints) do
        local pointPos = GetConnectionPointPosition(point)
        local distanceToPoint = tm.vector3.Distance(pointPos, position)
        if distanceToPoint <= 10 and distanceToPoint < closest.distance then
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

        local playerStructure = tm.players.OccupiedStructure(playerId)
        local connectionPoints = GetAllConnectionPointsInRange(
        GetConnectionPointPosition(playerData[playerId.selectedConnectionPoint]), 50, { playerStructure })

        for key, connectionPoint in ipairs(connectionPoints) do
            local pos = GetConnectionPointPosition(connectionPoint)
            local visualizer = tm.physics.SpawnObject(pos, Winch.CONNECTION_POINT.PREFAB)
            visualizer.GetTransform().SetScale(Winch.CONNECTION_POINT.SCALE)
            visualizer.SetIsStatic(true)
            visualizer.SetIsTrigger(true)
            playerData[playerId].connectionPoints[connectionPoint] = visualizer
        end
    else
        playerData[playerId].playersWinch = Winch.new(playerData[playerId].selectedConnectionPoint, closest.point)
        playerData[playerId].playersWinch.AddOnSnapCallback(playerId, OnWinchSnap)
        playerData[playerId].connectingWinch = false
        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

function PlaceAnchor(playerId, hitPosition)
    local playerPos = tm.players.GetPlayerTransform(playerId).GetPositionWorld()
    local hitDirection = Normalize(playerPos - hitPosition)
    -- start raycast just infront of hit position to get hit normal
    local raycastStartPos = hitPosition - (hitDirection * 0.1)
    local raycastHit = tm.physics.RaycastData(raycastStartPos, hitDirection, 1, true)
    if not raycastHit.DidHit() then return end
    local hitNormal = raycastHit.GetHitNormal()
    local rotation = QuaternionFromToRotation(tm.vector3.Forward(), hitNormal)

    local anchor = Anchor.new(hitPosition, rotation)
    table.insert(spawnedObjects, anchor.object)
end

function OnPlayerJoined(player)
    local playerId = player.playerId
    local spawnPosition = tm.players.GetPlayerTransform(playerId).GetPositionWorld() + tm.vector3.Create(0, 4, 0)
    table.insert(spawnedObjects,
        tm.physics.SpawnCustomObjectRigidbody(spawnPosition, "ropeModel", "ropeTexture", false, 0.7, "Asphalt"))
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
        infoBox = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Winch Mod is enabled.", "press 'V' to start winching.",
            math.huge)
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

---@param point ModBlock|ModGameObject
function GetConnectionPointPosition(point)
    local point_type = point.ToString()
    if point_type == "Trailmakers.Mods.Api.Proxies.ModBlock" then
        return point.GetPosition()
    elseif point_type == "PFB_ModGameObject [Server] (ModGameObject_Server)" then
        return point.GetTransform().GetPositionWorld()
    end
end

-- AI Function to turn direction vector into rotation quaternion
function QuaternionFromToRotation(from, to)
    from = Normalize(from)
    to = Normalize(to)
    local d = from.Dot(to)
    -- Handle opposite vectors (180 degrees)
    if d < -1 + 1e-6 then
        local axis = tm.vector3.Right().Cross(from)
        if axis.Magnitude() < 1e-6 then
            axis = tm.vector3.Forward().Cross(from)
        end
        axis = Normalize(axis)
        return tm.quaternion.Create(axis.x, axis.y, axis.z, 0)
    end
    -- Standard rotation calculation
    local s = math.sqrt((1 + d) * 2)
    local invs = 1 / s
    local c = from.Cross(to)
    return tm.quaternion.Create(c.x * invs, c.y * invs, c.z * invs, s * 0.5)
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

--#region PlayerCallback
function OnWinchSnap(callback)
    local playerId = callback.playerId
    local stretchedDistance = callback.stretchedDistance
    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Winch snapped!.", "stretched distance: " .. stretchedDistance, 5)
    playerData[playerId].playersWinch = nil
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
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    playerData[playerId].placingAnchor = not playerData[playerId].placingAnchor
end

function OnPlayerPullWinchStart(playerId)
    if playerData[playerId].chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isPulling = true
    end
end

function OnPlayerExtendWinchStart(playerId)
    if playerData[playerId].chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isExtending = true
    end
end

function OnPlayerPullWinchStop(playerId)
    if playerData[playerId].chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isPulling = false
    end
end

function OnPlayerExtendWinchStop(playerId)
    if playerData[playerId].chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].isExtending = false
    end
end

function OnOpenCloseChat(playerId)
    playerData[playerId].chatOpen = not playerData[playerId].chatOpen
end

--#endregion
