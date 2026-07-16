local UI = {}

local playerData
local sessionSettings
local KEYBINDS
local Winch
local ITEM_TYPES

local COLORS = {
    GREEN = "<color=" .. "#C7D66D" .. ">",
    RED = "<color=" .. "#F78764" .. ">",
    BLUE = "<color=" .. "#69d9d8" .. ">",
    PURPLE = "<color=" .. "#6A5B6E" .. ">",
}

local btnReturn = "<b><color=#69d9d8>↩️ Return </color></b>"

local function IsValidKeybind(value)
    return value ~= nil and KEYBINDS[value]
end

function UI.Setup(config)
    playerData = config.playerData
    sessionSettings = config.sessionSettings
    KEYBINDS = config.KEYBINDS
    Winch = config.Winch
    ITEM_TYPES = config.ITEM_TYPES
end

local function DrawMainMenu(playerId)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Main Menu -~")
    tm.playerUI.AddUIButton(playerId, "btnSettings", COLORS.BLUE .. "Settings" .. "</color>",
        function() UI.UpdateUi(playerId, "settings") end)
    tm.playerUI.AddUIButton(playerId, "btnLoadout", COLORS.GREEN .. "Loadout" .. "</color>",
        function() UI.UpdateUi(playerId, "loadout") end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")

    tm.playerUI.AddUILabel(playerId, "lblCredit1", "Made with ❤️")
    tm.playerUI.AddUILabel(playerId, "lblCredit2", "<color=#BEAED5>by Blockhampter</color>")
end

local function DrawSettings(playerId)
    local settings = playerData[playerId].settings
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "main") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Settings -~")

    tm.playerUI.AddUIButton(playerId, "btnKeybinds", COLORS.BLUE .. "Keybinds" .. "</color>",
        function() UI.UpdateUi(playerId, "keybinds") end)

    tm.playerUI.AddUILabel(playerId, "lblWinchHeading", "- default winch settings -")
    tm.playerUI.AddUILabel(playerId, "lblWinchStrength", "Strength:")
    tm.playerUI.AddUIText(playerId, "txtWinchStrength", settings.defaultWinch.strength, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) <= 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5)
            return
        end
        settings.defaultWinch.strength = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchElasticity", "Elasticity:")
    tm.playerUI.AddUIText(playerId, "txtWinchElasticity", settings.defaultWinch.elasticity, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) <= 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5)
            return
        end
        settings.defaultWinch.elasticity = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchSpeed", "Speed:")
    tm.playerUI.AddUIText(playerId, "txtWinchSpeed", settings.defaultWinch.speed, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number >= 0", 5)
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
        UI.UpdateUi(playerId, "settings")
    end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")
    if not tm.players.IsPlayerAdministrator(playerId) then
        return
    end
    tm.playerUI.AddUILabel(playerId, "lblSessionSettingsHeading", "- session settings -")
    tm.playerUI.AddUILabel(playerId, "lblMaxInventorySlots", "max inventory slots:")
    tm.playerUI.AddUIText(playerId, "txtMaxInventorySlots", sessionSettings.maxInventorySlots, function(UICallbackData)
        local value = tonumber(UICallbackData.value)
        if value == nil or value <= 0 or value > 9 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number between 1 and 9", 5)
            return
        end
        sessionSettings.maxInventorySlots = value
    end)
end

local function DrawKeybindSettings(playerId)
    local keybinds = playerData[playerId].settings.keybinds
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "settings") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Keybinds -~")

    tm.playerUI.AddUILabel(playerId, "lblWinchHeading", "- winch -")
    tm.playerUI.AddUILabel(playerId, "lblWinchExtend", "Extend:")
    tm.playerUI.AddUIText(playerId, "txtWinchExtend", keybinds.winch.extend, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.winch.extend = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchPull", "Pull:")
    tm.playerUI.AddUIText(playerId, "txtWinchPull", keybinds.winch.pull, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.winch.pull = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryHeading", "- inventory -")
    tm.playerUI.AddUILabel(playerId, "lblInventoryLeft", "Left:")
    tm.playerUI.AddUIText(playerId, "txtInventoryLeft", keybinds.inventory.left, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.left = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryRight", "Right:")
    tm.playerUI.AddUIText(playerId, "txtInventoryRight", keybinds.inventory.right, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.right = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryUseItem", "Use Item:")
    tm.playerUI.AddUIText(playerId, "txtInventoryUseItem", keybinds.inventory.useItem, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.useItem = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryOpenClose", "Open/Close:")
    tm.playerUI.AddUIText(playerId, "txtInventoryOpenClose", keybinds.inventory.openClose, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5)
            return
        end
        keybinds.inventory.openClose = UICallbackData.value
    end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")
end

local function DrawLoadout(playerId)
    local inventory = playerData[playerId].inventory
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "main") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Loadout -~")

    for key, slot in pairs(inventory.slots) do
        local isFocused = playerData[playerId].ui.focusedLoadoutSlot == key
        tm.playerUI.AddUIButton(playerId, "btnInventorySlot" .. key,
            (isFocused and COLORS.PURPLE or "") .. slot.type.name .. " " .. key .. (isFocused and "</color>" or ""),
            function()
                if playerData[playerId].ui.focusedLoadoutSlot == key then
                    playerData[playerId].ui.focusedLoadoutSlot = nil
                else
                    playerData[playerId].ui.focusedLoadoutSlot = key
                end
                UI.UpdateUi(playerId, "loadout")
            end)
        if isFocused then
            if slot.type == ITEM_TYPES.winch then
                tm.playerUI.AddUIButton(playerId, "btnConfigureWinch", "Configure", function()
                end)
            end
            tm.playerUI.AddUIButton(playerId, "btnChangeLoadoutSlot", "Change", function()
            end)
            tm.playerUI.AddUIButton(playerId, "btnRemoveLoadoutSlot", "Remove", function()
            end)
        end
    end
    if #inventory.slots < sessionSettings.maxInventorySlots then
        tm.playerUI.AddUIButton(playerId, "btnAddLoadoutSlot", "Add", function()
        end)
    end
end

function UI.UpdateUi(playerId, uiPage)
    local uiPages = {
        ["main"] = DrawMainMenu,
        ["settings"] = DrawSettings,
        ["keybinds"] = DrawKeybindSettings,
        ["loadout"] = DrawLoadout,
    }
    if uiPages[uiPage] then
        playerData[playerId].ui.page = uiPage
        playerData[playerId].inventory.isOpen = false
        playerData[playerId].ui.inventoryBoxId = nil
        tm.playerUI.ClearUI(playerId)
        uiPages[uiPage](playerId)
    else
        tm.os.Log("Invalid uiPage: " .. uiPage)
    end
end

function UI.UpdateInventoryMessage(playerId)
    local inventory = playerData[playerId].inventory
    local selectedSlot = inventory.slots[inventory.selectedSlot]
    local header = inventory.selectedSlot .. " - " .. selectedSlot.type.name
    local action = selectedSlot.isUsed and "Retrieve" or "Use"
    if playerData[playerId].action == "connectingWinch" then
        action = "Connecting"
    elseif playerData[playerId].action == "placingAnchor" then
        action = "Placing"
    end
    local message =
        "<-" ..
        string.rep(" ", math.floor((28 - #action) / 2)) ..
        action ..
        string.rep(" ", math.floor((28 - #action) / 2)) ..
        "->"
    tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData[playerId].ui.inventoryBoxId, header)
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData[playerId].ui.inventoryBoxId, message)
end

function UI.UpdateItemBoxMessage(playerId, itemInUse)
    local inputs = playerData[playerId].input
    if inputs.isExtending then
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData[playerId].ui.useItemBoxId,
            "Extending Winch" .. string.rep(".", (math.floor(tm.os.GetRealtimeSinceStartup() * 2) % 4)))
    elseif inputs.isPulling then
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData[playerId].ui.useItemBoxId,
            "Pulling Winch" .. string.rep(".", (math.floor(tm.os.GetRealtimeSinceStartup() * 2) % 4)))
    else
        tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData[playerId].ui.useItemBoxId, "")
    end
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData[playerId].ui.useItemBoxId,
        "Length: " .. string.format("%.2f", itemInUse.objectReference.length) .. "m")
end

return UI
