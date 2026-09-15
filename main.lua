tm.os.SetModTargetDeltaTime(1 / 60)

tm.physics.AddTexture("assets/icons/Winch_Icon.png", "Winch_Icon")

local Winch = tm.os.DoFile("winch")
local Anchor = tm.os.DoFile("anchor")
local UI = tm.os.DoFile("ui")

local SAVING = tm.os.DoFile("saving")

local KEYBINDS = {
    ["`"] = true,
    ["1"] = true,
    ["2"] = true,
    ["3"] = true,
    ["4"] = true,
    ["5"] = true,
    ["6"] = true,
    ["7"] = true,
    ["8"] = true,
    ["9"] = true,
    ["0"] = true,
    ["-"] = true,
    ["="] = true,
    ["a"] = true,
    ["b"] = true,
    ["c"] = true,
    ["d"] = true,
    ["e"] = true,
    ["f"] = true,
    ["g"] = true,
    ["h"] = true,
    ["i"] = true,
    ["j"] = true,
    ["k"] = true,
    ["l"] = true,
    ["m"] = true,
    ["n"] = true,
    ["o"] = true,
    ["p"] = true,
    ["q"] = true,
    ["r"] = true,
    ["s"] = true,
    ["t"] = true,
    ["u"] = true,
    ["v"] = true,
    ["w"] = true,
    ["x"] = true,
    ["y"] = true,
    ["z"] = true,
    ["A"] = true,
    ["B"] = true,
    ["C"] = true,
    ["D"] = true,
    ["E"] = true,
    ["F"] = true,
    ["G"] = true,
    ["H"] = true,
    ["I"] = true,
    ["J"] = true,
    ["K"] = true,
    ["L"] = true,
    ["M"] = true,
    ["N"] = true,
    ["O"] = true,
    ["P"] = true,
    ["Q"] = true,
    ["R"] = true,
    ["S"] = true,
    ["T"] = true,
    ["U"] = true,
    ["V"] = true,
    ["W"] = true,
    ["X"] = true,
    ["Y"] = true,
    ["Z"] = true,
    ["["] = true,
    ["]"] = true,
    [";"] = true,
    ["'"] = true,
    ["\\"] = true,
    [","] = true,
    ["."] = true,
    ["/"] = true,
    ["backspace"] = true,
    ["tab"] = true,
    ["enter"] = true,
    ["left shift"] = true,
    ["right shift"] = true,
    ["left control"] = true,
    ["left alt"] = true,
    ["space"] = true,
    ["right alt"] = true,
    ["right control"] = true,
    ["insert"] = true,
    ["home"] = true,
    ["page up"] = true,
    ["delete"] = true,
    ["end"] = true,
    ["page down"] = true,
    ["up"] = true,
    ["down"] = true,
    ["left"] = true,
    ["right"] = true,
    ["numlock"] = true,
    ["[/]"] = true,
    ["[*]"] = true,
    ["[-]"] = true,
    ["[+]"] = true,
    ["[enter]"] = true,
    ["[,]"] = true,
    ["[1]"] = true,
    ["[2]"] = true,
    ["[3]"] = true,
    ["[4]"] = true,
    ["[5]"] = true,
    ["[6]"] = true,
    ["[7]"] = true,
    ["[8]"] = true,
    ["[9]"] = true,
    ["[0]"] = true,
}

local sessionSettings = {
    maxInventorySlots = 4,
    connectionRange = 50
}

local playerData = {}

local spawnedObjects = {}



function UseAnchor(playerId, anchorItem)
    if anchorItem.isUsed then
        RemoveByValue(spawnedObjects, anchorItem.objectReference.object)
        anchorItem.objectReference:remove()
        anchorItem.objectReference = nil
        anchorItem.isUsed = false
        -- give player visual feedback, that the anchor got retrieved
        return
    end
    if playerData[playerId].action == "none" then
        tm.playerUI.RegisterMouseDownPositionCallback(playerId, OnPlayerClick)
        playerData[playerId].action = "placingAnchor"
    elseif playerData[playerId].action == "placingAnchor" then
        tm.playerUI.DeregisterMouseDownPositionCallback(playerId, OnPlayerClick)
        playerData[playerId].action = "none"
    end
end

function UseWinch(playerId, winchItem)
    if winchItem.isUsed then
        winchItem.objectReference:remove()
        winchItem.objectReference = nil
        winchItem.isUsed = false
        EnsureUseItemBox(playerId)
        -- give player visual feedback, that the winch got detached
        return
    end
    if playerData[playerId].action == "none" then -- initiate connection process
        local playerStructure = tm.players.OccupiedStructure(playerId)
        if playerStructure == nil then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Enter a structure first!", "", 5)
            return
        end
        tm.playerUI.RegisterMouseDownPositionCallback(playerId, OnPlayerClick)
        playerData[playerId].action = "connectingWinch"
        playerData[playerId].connectionPoints = {}
        local blockList = GetAllConnectionPointsOnStructure(playerStructure)
        for key, block in ipairs(blockList) do
            local visualizer = tm.physics.SpawnObject(block.GetPosition(), Winch.CONNECTION_POINT.PREFAB)
            visualizer.GetTransform().SetScale(Winch.CONNECTION_POINT.SCALE)
            visualizer.SetIsStatic(true)
            visualizer.SetIsTrigger(true)
            playerData[playerId].connectionPoints[block] = visualizer
        end
    elseif playerData[playerId].action == "connectingWinch" then -- cancel connection process
        tm.playerUI.DeregisterMouseDownPositionCallback(playerId, OnPlayerClick)
        playerData[playerId].action = "none"
        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

local ITEM_TYPES = {
    anchor = {
        name = "Anchor",
        onUseCallback = UseAnchor, -- function that puts the player into anchor place mode or gets player out of this place mode
        -- price = 20, -- could use this to make an economy system
    },
    winch = {
        name = "Winch",
        onUseCallback = UseWinch, -- function that puts the player into winch connect mode or removes the winch
        -- price = 50,
    }
}

UI.Setup({
    playerData = playerData,
    sessionSettings = sessionSettings,
    KEYBINDS = KEYBINDS,
    Winch = Winch,
    ITEM_TYPES = ITEM_TYPES
})
SAVING.Setup({
    ITEM_TYPES = ITEM_TYPES
})

function PlayerUpdate(player)
    local playerId = player.playerId
    local inventory = playerData[playerId].inventory
    local selectedInventorySlot = playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot]

    for key, item in ipairs(inventory.slots) do
        if inventory.loadout[key] == ITEM_TYPES.winch and item.isUsed then
            item.objectReference:update()
        end
    end

    if inventory.loadout[playerData[playerId].inventory.selectedSlot] == ITEM_TYPES.winch and selectedInventorySlot.isUsed then
        local inputs = playerData[playerId].input
        if inputs.isExtending then
            selectedInventorySlot.objectReference:extend()
        end
        if inputs.isPulling then
            selectedInventorySlot.objectReference:pull()
        end
    end

    -- ensure the use-item subtle box is shown/hidden and updated
    EnsureUseItemBox(playerId)

    if playerData[playerId].action == "connectingWinch" then
        for point, visualizer in pairs(playerData[playerId].connectionPoints) do
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

function SelectConnectionPoint(playerId, position)
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
            GetConnectionPointPosition(playerData[playerId].selectedConnectionPoint), { playerStructure })

        for key, connectionPoint in ipairs(connectionPoints) do
            local pos = GetConnectionPointPosition(connectionPoint)
            local visualizer = tm.physics.SpawnObject(pos, Winch.CONNECTION_POINT.PREFAB)
            visualizer.GetTransform().SetScale(Winch.CONNECTION_POINT.SCALE)
            visualizer.SetIsStatic(true)
            visualizer.SetIsTrigger(true)
            playerData[playerId].connectionPoints[connectionPoint] = visualizer
        end
    else
        local selectedInventorySlot = playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot]
        local defaultWinchSettings = playerData[playerId].settings.defaultWinch
        selectedInventorySlot.objectReference = Winch.new(playerId, playerData[playerId].selectedConnectionPoint,
            closest.point,
            defaultWinchSettings.stiffness,
            defaultWinchSettings.maxStretch,
            defaultWinchSettings.speed
        )

        playerData[playerId].action = "none"
        selectedInventorySlot.objectReference:AddOnSnapCallback(playerId, OnWinchSnap,
            { inventorySlot = playerData[playerId].inventory.selectedSlot })
        selectedInventorySlot.objectReference:update()
        selectedInventorySlot.isUsed = true
        -- Highlight the newly created winch
        if selectedInventorySlot.objectReference.ropeObject then
            selectedInventorySlot.objectReference:Highlight()
        end

        UI.UpdateInventoryMessage(playerId)
        EnsureUseItemBox(playerId)

        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

function PlaceAnchor(playerId, hitPosition)
    local playerPos = tm.players.GetPlayerTransform(playerId).GetPositionWorld()
    local hitDirection = Normalize(hitPosition - playerPos)
    -- start raycast just infront of hit position to get hit normal
    local raycastStartPos = hitPosition - (hitDirection * 0.1)
    local raycastHit = tm.physics.RaycastData(raycastStartPos, hitDirection, 1, true)
    if not raycastHit.DidHit() then return end
    local hitNormal = raycastHit.GetHitNormal()

    local selectedInventorySlot = playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot]
    selectedInventorySlot.objectReference = Anchor.new(hitPosition, hitNormal)
    table.insert(spawnedObjects, selectedInventorySlot.objectReference.object)

    playerData[playerId].action = "none"
    selectedInventorySlot.isUsed = true

    UI.UpdateInventoryMessage(playerId)
end

function OnPlayerJoined(player)
    local playerId = player.playerId

    playerData[playerId] = {
        connectionPoints = {},
        selectedConnectionPoint = nil,
        action = "none", -- "placingAnchor" | "connectingWinch"
        inventory = {
            loadout ={
                ITEM_TYPES.winch,
                ITEM_TYPES.winch,
                ITEM_TYPES.anchor,
                ITEM_TYPES.anchor
            },
            isOpen = false,
            selectedSlot = 1,
            slots = {
                {
                    objectReference = nil,
                    isUsed = false,
                },
                {
                    objectReference = nil,
                    isUsed = false,
                },
                {
                    objectReference = nil,
                    isUsed = false,
                },
                {
                    objectReference = nil,
                    isUsed = false,
                },
            }
        },
        input = {
            isExtending = false,
            isPulling = false,
            chatOpen = false
        },
        ui = {
            page = "main", -- "settings"|"help"|"loadout"|"keybinds"|"configureWinch"
            focusedLoadoutSlot = nil,
            inventoryBoxId = nil,
            useItemBoxId = nil
        },
        settings = {
            keybinds = {
                winch = {
                    extend = "up",
                    pull = "down",
                },
                inventory = {
                    left = "left",
                    right = "right",
                    useItem = "v",
                    openClose = "i"
                }
            },
            defaultWinch = {
                stiffness = Winch.stiffness,
                maxStretch = Winch.maxStretch,
                speed = Winch.speed
            }
        },
        lastPlayerDataSave = tm.os.GetTime()
    }
    local playerDataSave = SAVING.loadPlayerData(playerId)
    playerData[playerId].settings = playerDataSave and playerDataSave.settings or playerData[playerId].settings
    playerData[playerId].inventory.loadout = playerDataSave and playerDataSave.loadout or playerData[playerId].inventory.loadout
    SAVING.savePlayerData(playerData)
    UI.UpdateUi(playerId, "main")

    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnOpenCloseChat", "enter")
end

tm.players.OnPlayerJoined.add(OnPlayerJoined)

function OnPlayerLeft(player)
    local playerId = player.playerId
    for block, visualizer in pairs(playerData[playerId].connectionPoints) do
        visualizer.Despawn()
    end
    for key, item in ipairs(playerData[playerId].inventory.slots) do
        if playerData[playerId].inventory.loadout[key] == ITEM_TYPES.winch and item.isUsed then
            item.objectReference:remove()
            item.objectReference = nil
            item.isUsed = false
        elseif playerData[playerId].inventory.loadout[key] == ITEM_TYPES.anchor and item.isUsed then
            RemoveByValue(spawnedObjects, item.objectReference.object)
            item.objectReference:remove()
            item.objectReference = nil
            item.isUsed = false
        end
    end
    playerData[playerId].connectionPoints = {}
    playerData[playerId].selectedConnectionPoint = nil
    playerData[playerId] = nil
end

tm.players.OnPlayerLeft.add(OnPlayerLeft)

function PlayerKeyDown(player, keyName)
    local keyBinds = playerData[player.playerId].settings.keybinds
    local keyBindFunctions = {
        [keyBinds.winch.extend] = OnPlayerExtendWinchStart,
        [keyBinds.winch.pull] = OnPlayerPullWinchStart,
        [keyBinds.inventory.left] = OnPlayerInventoryLeft,
        [keyBinds.inventory.right] = OnPlayerInventoryRight,
        [keyBinds.inventory.useItem] = OnPlayerUseItem,
        [keyBinds.inventory.openClose] = OnPlayerOpenCloseInventory
    }
    local func = keyBindFunctions[keyName]
    if func then
        func(player.playerId)
    end
end

function PlayerKeyUp(player, keyName)
    local keyBinds = playerData[player.playerId].settings.keybinds
    local keyBindFunctions = {
        [keyBinds.winch.extend] = function(playerId)
            OnPlayerExtendWinchStop(playerId)
        end,
        [keyBinds.winch.pull] = function(playerId)
            OnPlayerPullWinchStop(playerId)
        end
    }
    if keyBindFunctions[keyName] then
        keyBindFunctions[keyName](player.playerId)
    end
end

tm.input.OnPlayerKeyDown.add(PlayerKeyDown)
tm.input.OnPlayerKeyUp.add(PlayerKeyUp)

function GetAllConnectionPointsInRange(pos, excludedStructures)
    local range = sessionSettings.connectionRange
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

function RemoveByValue(t, value)
    for i = 1, #t do
        if t[i] == value then
            table.remove(t, i)
            return true
        end
    end
    return false
end

-- Update highlighting when selected item changes
function UpdateSelectionHighlight(playerId, oldSlotIndex, newSlotIndex)
    local inventory = playerData[playerId].inventory
    local oldSlot = inventory.slots[oldSlotIndex]
    local newSlot = inventory.slots[newSlotIndex]

    -- Remove highlight from old item
    if oldSlot and inventory.loadout[oldSlotIndex] == ITEM_TYPES.winch and oldSlot.isUsed and oldSlot.objectReference then
        if oldSlot.objectReference.ropeObject then
            oldSlot.objectReference:RemoveHighlight()
        end
    end

    -- Add highlight to new item
    if newSlot and inventory.loadout[newSlotIndex] == ITEM_TYPES.winch and newSlot.isUsed and newSlot.objectReference then
        if newSlot.objectReference.ropeObject then
            newSlot.objectReference:Highlight()
        end
    end
end

-- Ensure the "use item" subtle message is shown/hidden and updated
function EnsureUseItemBox(playerId)
    local ui = playerData[playerId].ui
    local inventory = playerData[playerId].inventory
    -- if inventory closed, remove box
    if not inventory.isOpen then
        if ui.useItemBoxId then
            tm.playerUI.RemoveSubtleMessageForPlayer(playerId, ui.useItemBoxId)
            ui.useItemBoxId = nil
        end
        return
    end

    local selectedSlot = inventory.slots[inventory.selectedSlot]
    if selectedSlot and inventory.loadout[inventory.selectedSlot] == ITEM_TYPES.winch and selectedSlot.isUsed and selectedSlot.objectReference then
        if not ui.useItemBoxId then
            ui.useItemBoxId = tm.playerUI.AddSubtleMessageForPlayer(playerId, "", "", math.huge)
        end
        UI.UpdateItemBoxMessage(playerId, selectedSlot)
    else
        if ui.useItemBoxId then
            tm.playerUI.RemoveSubtleMessageForPlayer(playerId, ui.useItemBoxId)
            ui.useItemBoxId = nil
        end
    end
end

--#region PlayerCallback

function OnPlayerBusy(player)
    local playerId = player.playerId
    if playerData[playerId].inventory.isOpen then
        playerData[playerId].inventory.isOpen = false
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData[playerId].ui.inventoryBoxId)
        playerData[playerId].ui.inventoryBoxId = nil
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData[playerId].ui.useItemBoxId)
        playerData[playerId].ui.useItemBoxId = nil
        UI.UpdateInventoryMessage(playerId)
        -- show/hide use-item box depending on selected slot
        EnsureUseItemBox(playerId)
        playerData[playerId].action = "none"
        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

tm.players.OnPlayerDied.add(OnPlayerBusy)
tm.players.OnPlayerEnterBuilder.add(OnPlayerBusy)

function OnWinchSnap(callback)
    local playerId = callback.playerId

    if callback.info then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Winch " .. callback.inventorySlot .. " snapped!",
            callback.info, 5)
    else
        local stretchedDistance = callback.stretchedDistance
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Winch " .. callback.inventorySlot .. " snapped!",
            "stretched distance: " .. string.format("%.2f", stretchedDistance), 5)
    end

    -- remove use-item box if visible for this player
    if playerData[playerId].ui.useItemBoxId then
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData[playerId].ui.useItemBoxId)
        playerData[playerId].ui.useItemBoxId = nil
    end

    playerData[playerId].inventory.slots[callback.inventorySlot].objectReference = nil
    playerData[playerId].inventory.slots[callback.inventorySlot].isUsed = false
    playerData[playerId].input.isPulling = false
    playerData[playerId].input.isExtending = false
    UI.UpdateInventoryMessage(playerId)
end

function OnPlayerClick(callback)
    local playerId = callback.playerId
    local position = tm.vector3.Create(callback.value)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    local callAction = {
        ["placingAnchor"] = PlaceAnchor,
        ["connectingWinch"] = SelectConnectionPoint
    }
    if callAction[playerData[playerId].action] then
        callAction[playerData[playerId].action](playerId, position)
    end
end

function OnPlayerPullWinchStart(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end
    local selectedItem = playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot]
    if playerData[playerId].inventory.loadout[playerData[playerId].inventory.selectedSlot] == ITEM_TYPES.winch and selectedItem.isUsed then
        playerData[playerId].input.isPulling = true
    end
end

function OnPlayerExtendWinchStart(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end
    local selectedItem = playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot]
    if playerData[playerId].inventory.loadout[playerData[playerId].inventory.selectedSlot] == ITEM_TYPES.winch and selectedItem.isUsed then
        playerData[playerId].input.isExtending = true
    end
end

function OnPlayerPullWinchStop(playerId)
    if playerData[playerId].input.chatOpen then return end

    playerData[playerId].input.isPulling = false
end

function OnPlayerExtendWinchStop(playerId)
    if playerData[playerId].input.chatOpen then return end

    playerData[playerId].input.isExtending = false
end

function OnOpenCloseChat(playerId)
    playerData[playerId].input.chatOpen = not playerData[playerId].input.chatOpen
    if playerData[playerId].ui.page == "settings" then
        UI.UpdateUi(playerId, "settings")
    end
end

function OnPlayerInventoryLeft(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    local inventory = playerData[playerId].inventory
    local oldSlotIndex = inventory.selectedSlot
    inventory.selectedSlot = inventory.selectedSlot - 1
    if inventory.selectedSlot < 1 then
        inventory.selectedSlot = #inventory.slots
    end
    playerData[playerId].action = "none"
    UpdateSelectionHighlight(playerId, oldSlotIndex, inventory.selectedSlot)
    UI.UpdateInventoryMessage(playerId)
    EnsureUseItemBox(playerId)
    for block, visualizer in pairs(playerData[playerId].connectionPoints) do
        visualizer.Despawn()
    end
    playerData[playerId].selectedConnectionPoint = nil
    playerData[playerId].connectionPoints = {}
end

function OnPlayerInventoryRight(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    local inventory = playerData[playerId].inventory
    local oldSlotIndex = inventory.selectedSlot
    inventory.selectedSlot = inventory.selectedSlot + 1
    if inventory.selectedSlot > #inventory.slots then
        inventory.selectedSlot = 1
    end
    playerData[playerId].action = "none"
    UpdateSelectionHighlight(playerId, oldSlotIndex, inventory.selectedSlot)
    UI.UpdateInventoryMessage(playerId)
    EnsureUseItemBox(playerId)
    for block, visualizer in pairs(playerData[playerId].connectionPoints) do
        visualizer.Despawn()
    end
    playerData[playerId].selectedConnectionPoint = nil
    playerData[playerId].connectionPoints = {}
end

function OnPlayerOpenCloseInventory(playerId)
    if playerData[playerId].input.chatOpen then return end
    local inventory = playerData[playerId].inventory
    inventory.isOpen = not inventory.isOpen
    if inventory.isOpen then
        playerData[playerId].ui.inventoryBoxId = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Inventory", "",
            math.huge)
    else
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData[playerId].ui.inventoryBoxId)
        playerData[playerId].ui.inventoryBoxId = nil
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData[playerId].ui.useItemBoxId)
        playerData[playerId].ui.useItemBoxId = nil
    end
    UI.UpdateInventoryMessage(playerId)
    -- show/hide use-item box depending on selected slot
    EnsureUseItemBox(playerId)
    playerData[playerId].action = "none"
    for block, visualizer in pairs(playerData[playerId].connectionPoints) do
        visualizer.Despawn()
    end
    playerData[playerId].selectedConnectionPoint = nil
    playerData[playerId].connectionPoints = {}
end

function OnPlayerUseItem(playerId)
    if playerData[playerId].input.chatOpen then return end
    if not playerData[playerId].inventory.isOpen then return end

    playerData[playerId].inventory.loadout[playerData[playerId].inventory.selectedSlot].onUseCallback(playerId,
        playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot])
    UI.UpdateInventoryMessage(playerId)
end

--#endregion
