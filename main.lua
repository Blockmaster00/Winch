tm.os.SetModTargetDeltaTime(1 / 60)

tm.physics.AddTexture("assets/Winch_Icon.png", "Winch_Icon")

local Winch = tm.os.DoFile("winch")
local Anchor = tm.os.DoFile("anchor")

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
    maxInventorySlots = 4
}

local playerData = {}

local spawnedObjects = {}

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

function UseAnchor(playerId, anchorItem)
    if anchorItem.isUsed then
        RemoveByValue(spawnedObjects, anchorItem.objectReference.object)
        anchorItem.objectReference:remove()
        anchorItem.objectReference = nil
        anchorItem.isUsed = false
        -- give player visual feedback, that the anchor got retrieved
        return
    end
    if not playerData[playerId].action == "placingAnchor" then
        playerData[playerId].action = "placingAnchor"
    elseif playerData[playerId].action == "placingAnchor" then
        playerData[playerId].action = "none"
    end
end

function UseWinch(playerId, winchItem)
    if winchItem.isUsed then
        winchItem.objectReference:remove()
        winchItem.objectReference = nil
        winchItem.isUsed = false
        -- give player visual feedback, that the winch got detached
        return
    end
    if not playerData[playerId].action == "connectingWinch" then -- initiate connection process
        playerData[playerId].action = "connectingWinch"
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
    elseif playerData[playerId].action == "connectingWinch" then -- cancel connection process
        playerData[playerId].action = "none"
        for block, visualizer in pairs(playerData[playerId].connectionPoints) do
            visualizer.Despawn()
        end
        playerData[playerId].selectedConnectionPoint = nil
        playerData[playerId].connectionPoints = {}
    end
end

function PlayerUpdate(player)
    local playerId = player.playerId
    local inventory = playerData[playerId].invenotry
    local selectedInventorySlot = playerData[playerId].inventory.slots[playerData[playerId].inventory.selectedSlot]

    for key, item in ipairs(inventory) do
        if item.type == ITEM_TYPES.winch and item.isUsed then
            item.objectReference:update()
        end
    end
    local inputs = playerData[playerId].input
    if inputs.isExtending then
        selectedInventorySlot.objectReference:extend()
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, "i",
            "Extending Winch" .. string.rep(".", (math.floor(tm.os.GetRealtimeSinceStartup() * 2) % 4)))
    end
    if inputs.isPulling then
        selectedInventorySlot.objectReference:pull()
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, "i",
            "Pulling Winch" .. string.rep(".", (math.floor(tm.os.GetRealtimeSinceStartup() * 2) % 4)))
    end

    if playerData[playerId].action == "connectingWinch" then
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(player.playerId, playerData[playerId].infoBox,
            "Select a connection point.")
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
            GetConnectionPointPosition(playerData[playerId].selectedConnectionPoint), 50, { playerStructure })

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
        selectedInventorySlot.objectReference = Winch.new(playerData[playerId].selectedConnectionPoint, closest.point,
            defaultWinchSettings.strength,
            defaultWinchSettings.elasticity,
            defaultWinchSettings.speed
        )
        selectedInventorySlot.objectReference:AddOnSnapCallback(playerId, OnWinchSnap)
        selectedInventorySlot.isUsed = true

        playerData[playerId].action = "none"
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
end

function UpdateUi(playerId, uiPage)
    local uiPages = {
        ["main"] = function(playerId)
            DrawMainMenu(playerId)
        end,
        ["settings"] = function(playerId)
            DrawSettings(playerId)
        end,
        ["keybinds"] = function(playerId)
            DrawKeybindSettings(playerId)
        end,
        ["loadout"] = function(playerId)
            DrawLoadout(playerId)
        end
    }
    if uiPages[uiPage] then
        playerData[playerId].ui.page = uiPage
        tm.playerUI.ClearUI(playerId)
        uiPages[uiPage](playerId)
    else
        tm.os.Log("Invalid uiPage: " .. uiPage)
    end
end

function OnPlayerJoined(player)
    local playerId = player.playerId

    playerData[playerId] = {
        connectionPoints = {},
        selectedConnectionPoint = nil,
        action = "none", -- "placingAnchor" | "connectingWinch"
        inventory = {
            isOpen = false,
            selectedSlot = 1,
            slots = {
                {
                    type = ITEM_TYPES.winch,
                    objectReference = nil,
                    isUsed = false,
                },
                {
                    type = ITEM_TYPES.winch,
                    objectReference = nil,
                    isUsed = false,
                },
                {
                    type = ITEM_TYPES.anchor,
                    objectReference = nil,
                    isUsed = false,
                },
                {
                    type = ITEM_TYPES.anchor,
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
            page = "main", -- "settings"|"help"|"loadout"|"keybinds"
            focusesLoadoutSlot = nil,
            inventoryBoxId = nil
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
                strength = Winch.strength,
                elasticity = Winch.elasticity,
                speed = Winch.speed
            }
        }
    }
    UpdateUi(playerId, "main")
    tm.playerUI.ShowCursorWorldPosition()
    tm.playerUI.RegisterMouseDownPositionCallback(playerId, OnPlayerClick)

    tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnOpenCloseChat", "enter")
    -- tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnPlayerAttachDetachWinch", "v")
    -- tm.input.RegisterFunctionToKeyDownCallback(playerId, "OnPlayerPlaceRemoveAnchor", "t")
end

tm.players.OnPlayerJoined.add(OnPlayerJoined)
tm.input.OnPlayerKeyDown.add(PlayerKeyDown)
tm.input.OnPlayerKeyUp.add(PlayerKeyUp)

function PlayerKeyDown(player, keyName)
    local keyBinds = playerData[player.playerId].settings.keybinds
    local keyBindFunctions = {
        [keyBinds.winch.extend] = function(playerId)
            OnPlayerExtendWinchStart(playerId)
        end,
        [keyBinds.winch.pull] = function(playerId)
            OnPlayerPullWinchStart(playerId)
        end,
        [keyBinds.inventory.left] = function(playerId)
            OnPlayerInventoryLeft(playerId)
        end,
        [keyBinds.inventory.right] = function(playerId)
            OnPlayerInventoryRight(playerId)
        end,
        [keyBinds.inventory.useItem] = function(playerId)
            OnPlayerUseItem(playerId)
        end,
        [keyBinds.inventory.openClose] = function(playerId)
            OnPlayerOpenCloseInventory(playerId)
        end
    }
    if keyBindFunctions[keyName] then
        keyBindFunctions[keyName](player.playerId)
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

function RemoveByValue(table, value)
    for i = 1, #table do
        if table[i] == value then
            table.remove(table, i)
            return true
        end
    end
    return false
end

--#region UI

local COLORS = {
    GREEN = "<color=" .. "#C7D66D" .. ">",
    RED = "<color=" .. "#F78764" .. ">",
    BLUE = "<color=" .. "#69d9d8" .. ">",
    PURPLE = "<color=" .. "#6A5B6E" .. ">",
}

local btnReturn = "<b><color=#69d9d8>↩️ Return </color></b>"

function DrawMainMenu(playerId)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Main Menu -~")
    tm.playerUI.AddUIButton(playerId, "btnSettings", COLORS.BLUE .. "Settings" .. "</color>",
        function() UpdateUi(playerId, "settings") end)
    tm.playerUI.AddUIButton(playerId, "btnLoadout", COLORS.GREEN .. "Loadout" .. "</color>",
        function() UpdateUi(playerId, "loadout") end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")

    tm.playerUI.AddUILabel(playerId, "lblCredit1", "Made with ❤️")
    tm.playerUI.AddUILabel(playerId, "lblCredit2", "<color=#BEAED5>by Blockhampter</color>")
end

function DrawSettings(playerId)
    local settings = playerData[playerId].settings
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UpdateUi(playerId, "main") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Settings -~")

    tm.playerUI.AddUIButton(playerId, "btnKeybinds", COLORS.BLUE .. "Keybinds" .. "</color>",
        function() UpdateUi(playerId, "keybinds") end)

    tm.playerUI.AddUILabel(playerId, "lblWinchHeading", "- default winch settings -")
    tm.playerUI.AddUILabel(playerId, "lblWinchStrength", "Strength:")
    tm.playerUI.AddUIText(playerId, "txtWinchStrength", settings.defaultWinch.strength, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5)
            return
        end
        settings.defaultWinch.strength = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchElasticity", "Elasticity:")
    tm.playerUI.AddUIText(playerId, "txtWinchElasticity", settings.defaultWinch.elasticity, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5)
            return
        end
        settings.defaultWinch.elasticity = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchSpeed", "Speed:")
    tm.playerUI.AddUIText(playerId, "txtWinchSpeed", settings.defaultWinch.speed, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5)
            return
        end
        settings.defaultWinch.speed = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUIButton(playerId, "btnResetWinchToDefault", "Reset to default", function()
        settings.defaultWinch = {
            strength = Winch.strength,
            elasticity = Winch.elasticity,
            speed = Winch.speed
        }
        UpdateUi(playerId, "settings")
    end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")
    if not tm.players.IsPlayerAdministrator(playerId) then
        return
    end
    tm.playerUI.AddUILabel(playerId, "lblSessionSettingsHeading", "- session settings -")
    tm.playerUI.AddUILabel(playerId, "lblMaxInventorySlots", "max inventory slots:")
    tm.playerUI.AddUIText(playerId, "txtWinchStrength", settings.defaultWinch.strength, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or 9 >= tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be number: 10 < x > 0", 5)
            return
        end
        sessionSettings.maxInventorySlots = tonumber(UICallbackData.value)
    end)
end

function DrawKeybindSettings(playerId)
    local keybinds = playerData[playerId].settings.keybinds
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UpdateUi(playerId, "settings") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Keybinds -~")


    tm.playerUI.AddUILabel(playerId, "lblWinchHeading", "- winch -")
    tm.playerUI.AddUILabel(playerId, "lblWinchExtend", "Extend:")
    tm.playerUI.AddUIText(playerId, "txtWinchExtend", keybinds.winch.extend, function(UICallbackData)
        if UICallbackData.value == nil or not KEYBINDS[UICallbackData.value] then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.winch.extend = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchPull", "Pull:")
    tm.playerUI.AddUIText(playerId, "txtWinchPull", keybinds.winch.pull, function(UICallbackData)
        if UICallbackData.value == nil or not KEYBINDS[UICallbackData.value] then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.winch.pull = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryHeading", "- inventory -")
    tm.playerUI.AddUILabel(playerId, "lblInventoryLeft", "Left:")
    tm.playerUI.AddUIText(playerId, "txtInventoryLeft", keybinds.inventory.left, function(UICallbackData)
        if UICallbackData.value == nil or not KEYBINDS[UICallbackData.value] then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.left = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryRight", "Right:")
    tm.playerUI.AddUIText(playerId, "txtInventoryRight", keybinds.inventory.right, function(UICallbackData)
        if UICallbackData.value == nil or not KEYBINDS[UICallbackData.value] then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.right = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryUseItem", "Use Item:")
    tm.playerUI.AddUIText(playerId, "txtInventoryUseItem", keybinds.inventory.useItem, function(UICallbackData)
        if UICallbackData.value == nil or not KEYBINDS[UICallbackData.value] then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.useItem = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryOpenClose", "Open/Close:")
    tm.playerUI.AddUIText(playerId, "txtInventoryOpenClose", keybinds.inventory.openClose, function(UICallbackData)
        if UICallbackData.value == nil or not KEYBINDS[UICallbackData.value] then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.openClose = UICallbackData.value
    end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")
end

function DrawLoadout(playerId)
    local inventory = playerData[playerId].inventory
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UpdateUi(playerId, "main") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Loadout -~")

    for key, slot in pairs(inventory.slots) do
        tm.playerUI.AddUIButton(playerId, "btnInventorySlot" .. key, slot.name, function()

        end)
    end
end

--#endregion

--#region PlayerCallback
function OnWinchSnap(callback)
    local playerId = callback.playerId
    local stretchedDistance = callback.stretchedDistance
    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Winch snapped!.",
        "stretched distance: " .. string.format("%.2f", stretchedDistance), 5)
    playerData[playerId].playersWinch = nil
end

function OnPlayerClick(callback)
    local playerId = callback.playerId
    local position = tm.vector3.Create(callback.value)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    local callAction = {
        ["placingAnchor"] = function(playerId, position)
            PlaceAnchor(playerId, position)
        end,
        ["connectingWinch"] = function(playerId, position)
            SelectConnectionPoint(playerId, position)
        end
    }
    if callAction[playerData[playerId].action] then
        callAction[playerData[playerId].action](playerId, position)
    end
end

function OnPlayerPullWinchStart(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
        playerData[playerId].input.isPulling = true
    end
end

function OnPlayerExtendWinchStart(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    if playerData[playerId].playersWinch ~= nil then
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
end

function OnPlayerInventoryLeft(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    local inventory = playerData[playerId].inventory
    inventory.selectedSlot = (inventory.selectedSlot - 1) % #inventory.slots
    playerData[playerId].action = "none" -- maybe requires cleanup if a action gets stopped prematurely
end

function OnPlayerInventoryRight(playerId)
    if playerData[playerId].input.chatOpen then return end
    if tm.players.GetPlayerIsInBuildMode(playerId) then return end

    local inventory = playerData[playerId].inventory
    inventory.selectedSlot = (inventory.selectedSlot + 1) % #inventory.slots
    playerData[playerId].action = "none" -- maybe requires cleanup if a action gets stopped prematurely
end

function OnPlayerOpenCloseInventory(playerId)
    if playerData[playerId].input.chatOpen then return end
end

function OnPlayerUseItem(playerId)
    if playerData[playerId].input.chatOpen then return end
    local inventory = playerData[playerId].inventory
    if not inventory.isOpen then return end

    inventory[inventory.selectedSlot].type.onUseCallback(playerId, inventory[inventory.selectedSlot])
end

--#endregion
