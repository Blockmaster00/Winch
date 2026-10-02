local UI = {}

local playerData
local sessionSettings
local KEYBINDS
local Winch
local ITEM_TYPES
local SAVING

local COLORS = {
    GREEN = "<color=" .. "#C7D66D" .. ">",
    RED = "<color=" .. "#F78764" .. ">",
    BLUE = "<color=" .. "#69d9d8" .. ">",
    PURPLE = "<color=" .. "#6A5B6E" .. ">",
    RESET = "</color>"
}

local btnReturn = "<b><color=#69d9d8>↩️ Return </color></b>"

local TUTORIAL_STEP_NAMES = {
    [1] = "Welcome",
    [2] = "Add conn. block",
    [3] = "Open inventory",
    [4] = "Select anchor",
    [5] = "Enter place mode",
    [6] = "Place anchor",
    [7] = "Select winch",
    [8] = "Connect mode",
    [9] = "Connect to build",
    [10] = "To anchor",
    [11] = "Use the winch",
    [12] = "Complete"
}

UI.BLOCK_ICONS = {
    ["PFB_TubeThing [Server]"] = "Rounded_Metal_Tube"
}
tm.physics.AddTexture("assets/icons/Rounded_Metal_Tube.png", UI.BLOCK_ICONS["PFB_TubeThing [Server]"])

UI.WINCH_ICON = "winchIcon"
tm.physics.AddTexture("assets/icons/Winch_Icon.png", UI.WINCH_ICON)

function UI.Setup(config)
    playerData = config.playerData
    sessionSettings = config.sessionSettings
    KEYBINDS = config.KEYBINDS
    Winch = config.Winch
    ITEM_TYPES = config.ITEM_TYPES
    SAVING = config.SAVING
end

local function IsValidKeybind(value)
    return value ~= nil and KEYBINDS[value]
end


local function DrawMainMenu(playerId, data)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Main Menu -~")
    tm.playerUI.AddUIButton(playerId, "btnSettings", COLORS.BLUE .. "Settings" .. COLORS.RESET,
        function() UI.UpdateUi(playerId, "settings") end)
    tm.playerUI.AddUIButton(playerId, "btnLoadout", COLORS.GREEN .. "Loadout" .. COLORS.RESET,
        function() UI.UpdateUi(playerId, "loadout") end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall1", "-+-")

    tm.playerUI.AddUIButton(playerId, "btnTutorial", COLORS.PURPLE .. "Tutorial" .. COLORS.RESET,
        function() UI.StartTutorial(playerId) end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall2", "-+-")

    tm.playerUI.AddUILabel(playerId, "lblCredit1", "Made with ❤️")
    tm.playerUI.AddUILabel(playerId, "lblCredit2", "<color=#BEAED5>by Blockhampter</color>")
end

local function DrawSettings(playerId, data)
    local settings = playerData[playerId].settings
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "main") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Settings -~")

    tm.playerUI.AddUIButton(playerId, "btnKeybinds", COLORS.BLUE .. "Keybinds" .. COLORS.RESET,
        function() UI.UpdateUi(playerId, "keybinds") end)

    tm.playerUI.AddUILabel(playerId, "lblWinchHeading", "- default winch settings -")
    tm.playerUI.AddUILabel(playerId, "lblWinchStiffness", "Stiffness:")
    tm.playerUI.AddUIText(playerId, "txtWinchStiffness", settings.defaultWinch.stiffness, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) <= 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5, UI.WINCH_ICON)
            return
        end
        settings.defaultWinch.stiffness = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchMaxStretch", "Max Stretch:")
    tm.playerUI.AddUIText(playerId, "txtWinchMaxStretch", settings.defaultWinch.maxStretch, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 100 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 100", 5, UI.WINCH_ICON)
            return
        end
        settings.defaultWinch.maxStretch = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchSpeed", "Speed:")
    tm.playerUI.AddUIText(playerId, "txtWinchSpeed", settings.defaultWinch.speed, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number >= 0", 5, UI.WINCH_ICON)
            return
        end
        settings.defaultWinch.speed = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUIButton(playerId, "btnResetWinchToDefault", "Reset to default", function()
        settings.defaultWinch = {
            stiffness = Winch.stiffness,
            maxStretch = Winch.maxStretch,
            speed = Winch.speed
        }
        UI.UpdateUi(playerId, "settings")
    end)
    if not tm.os.IsSingleplayer then
        tm.playerUI.AddUILabel(playerId, "lblTroubleshooting", "- Troubleshooting -")

        local input = playerData[playerId].input
        tm.playerUI.AddUILabel(playerId, "lblChatOpenState", "Chat is " .. (input.chatOpen and "open" or "closed") .. ".")
        tm.playerUI.AddUIButton(playerId, "btnResetChatOpenState", "reset internal chat-state", function()
            input.chatOpen = false
            UI.UpdateUi(playerId, "settings")
        end)
    end
    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")

    tm.playerUI.AddUILabel(playerId, "lblSessionSettingsHeading", "- Session Settings -")

    local isAdmin = tm.players.IsPlayerAdministrator(playerId)

    tm.playerUI.AddUILabel(playerId, "lblMaxInventorySlots", "max inventory slots:")
    if isAdmin then
        tm.playerUI.AddUIText(playerId, "txtMaxInventorySlots", sessionSettings.maxInventorySlots,
            function(UICallbackData)
                local value = tonumber(UICallbackData.value)
                if value == nil or value <= 0 or value > 9 then
                    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value",
                        "Value must be a number between 1 and 9", 5, UI.WINCH_ICON)
                    return
                end
                sessionSettings.maxInventorySlots = value
                SAVING.saveSessionSettings(sessionSettings)
            end)
    else
        tm.playerUI.AddUILabel(playerId, "txtMaxInventorySlots", tostring(sessionSettings.maxInventorySlots))
    end

    tm.playerUI.AddUILabel(playerId, "lblConnectionRange", "connection range:")
    if isAdmin then
        tm.playerUI.AddUIText(playerId, "txtConnectionRange", sessionSettings.connectionRange, function(UICallbackData)
            local value = tonumber(UICallbackData.value)
            if value == nil or value <= 0 then
                tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5, UI.WINCH_ICON)
                return
            end
            sessionSettings.connectionRange = value
            SAVING.saveSessionSettings(sessionSettings)
        end)
    else
        tm.playerUI.AddUILabel(playerId, "txtConnectionRange", tostring(sessionSettings.connectionRange))
    end

    tm.playerUI.AddUILabel(playerId, "lblSaveInterval", "save interval (seconds):")
    if isAdmin then
        tm.playerUI.AddUIText(playerId, "txtSaveInterval", sessionSettings.saveInterval, function(UICallbackData)
            local value = tonumber(UICallbackData.value)
            if value == nil or value <= 0 then
                tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5, UI.WINCH_ICON)
                return
            end
            sessionSettings.saveInterval = value
            SAVING.saveSessionSettings(sessionSettings)
        end)
    else
        tm.playerUI.AddUILabel(playerId, "txtSaveInterval", tostring(sessionSettings.saveInterval))
    end
end

local function DrawKeybindSettings(playerId, data)
    local keybinds = playerData[playerId].settings.keybinds
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "settings") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Keybinds -~")

    tm.playerUI.AddUILabel(playerId, "lblWinchHeading", "- winch -")
    tm.playerUI.AddUILabel(playerId, "lblWinchExtend", "Extend:")
    tm.playerUI.AddUIText(playerId, "txtWinchExtend", keybinds.winch.extend, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5, UI.WINCH_ICON)
            return
        end
        keybinds.winch.extend = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchPull", "Pull:")
    tm.playerUI.AddUIText(playerId, "txtWinchPull", keybinds.winch.pull, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5, UI.WINCH_ICON)
            return
        end
        keybinds.winch.pull = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryHeading", "- inventory -")
    tm.playerUI.AddUILabel(playerId, "lblInventoryLeft", "Left:")
    tm.playerUI.AddUIText(playerId, "txtInventoryLeft", keybinds.inventory.left, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5, UI.WINCH_ICON)
            return
        end
        keybinds.inventory.left = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryRight", "Right:")
    tm.playerUI.AddUIText(playerId, "txtInventoryRight", keybinds.inventory.right, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5, UI.WINCH_ICON)
            return
        end
        keybinds.inventory.right = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryUseItem", "Use Item:")
    tm.playerUI.AddUIText(playerId, "txtInventoryUseItem", keybinds.inventory.useItem, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5, UI.WINCH_ICON)
            return
        end
        keybinds.inventory.useItem = UICallbackData.value
    end)
    tm.playerUI.AddUILabel(playerId, "lblInventoryOpenClose", "Open/Close:")
    tm.playerUI.AddUIText(playerId, "txtInventoryOpenClose", keybinds.inventory.openClose, function(UICallbackData)
        if not IsValidKeybind(UICallbackData.value) then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a valid keybind", 5, UI.WINCH_ICON)
            return
        end
        keybinds.inventory.openClose = UICallbackData.value
    end)

    tm.playerUI.AddUILabel(playerId, "lbldividerSmall", "-+-")
end

local function DrawLoadout(playerId, data)
    local inventory = playerData[playerId].inventory
    local focusedLoadoutSlot = data.focusedLoadoutSlot or nil
    local switchingItemType = data.switchingItemType or false
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "main") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Loadout -~")

    for key, slot in pairs(inventory.slots) do
        local isFocused = focusedLoadoutSlot == key
        tm.playerUI.AddUIButton(playerId, "btnInventorySlot" .. key,
            (isFocused and COLORS.PURPLE or "") ..
            inventory.loadout[key].name .. " " .. key .. (isFocused and COLORS.RESET or ""),
            function()
                if focusedLoadoutSlot == key then
                    focusedLoadoutSlot = nil
                else
                    focusedLoadoutSlot = key
                end
                UI.UpdateUi(playerId, "loadout", { focusedLoadoutSlot = key })
            end)
        if isFocused then
            if inventory.loadout[key] == ITEM_TYPES.winch and slot.objectReference then
                tm.playerUI.AddUIButton(playerId, "btnConfigureWinch", "Configure", function()
                    UI.UpdateUi(playerId, "configureWinch", { inventorySlot = key })
                end)
            end
            tm.playerUI.AddUIButton(playerId, "btnChangeLoadoutSlot", COLORS.GREEN .. "Change Type" .. COLORS.RESET,
                function()
                    if switchingItemType then
                        UI.UpdateUi(playerId, "loadout", { focusedLoadoutSlot = key, switchingItemType = false })
                    else
                        UI.UpdateUi(playerId, "loadout", { focusedLoadoutSlot = key, switchingItemType = true })
                    end
                end)
            if switchingItemType then
                for itemTypeKey, itemType in pairs(ITEM_TYPES) do
                    tm.playerUI.AddUIButton(playerId, "btnChangeLoadoutSlotTo" .. itemTypeKey,
                        COLORS.BLUE .. itemType.name .. COLORS.RESET,
                        function()
                            inventory.loadout[key] = itemType
                            inventory.slots[key].isUsed = false
                            inventory.slots[key].objectReference = nil
                            UI.UpdateUi(playerId, "loadout", { focusedLoadoutSlot = key, switchingItemType = false })
                        end)
                end
            end
            tm.playerUI.AddUIButton(playerId, "btnRemoveLoadoutSlot", COLORS.RED .. "Remove" .. COLORS.RESET, function()
                table.remove(inventory.slots, key)
                UI.UpdateUi(playerId, "loadout")
            end)
        end
    end
    if #inventory.slots < sessionSettings.maxInventorySlots then
        tm.playerUI.AddUIButton(playerId, "btnAddLoadoutSlot", COLORS.GREEN .. "Add" .. COLORS.RESET, function()
            table.insert(inventory.slots, { isUsed = false, objectReference = nil })
            table.insert(inventory.loadout, ITEM_TYPES.winch)
            UI.UpdateUi(playerId, "loadout", { focusedLoadoutSlot = #inventory.slots, switchingItemType = true })
        end)
    end
end

-- Settings page for each Winch in the players Loadout. This page gets opened when the player clicks "Configure" on a Winch in the Loadout page.
local function DrawConfigureWinch(playerId, data)
    local inventorySlot = data.inventorySlot
    if inventorySlot == nil then
        tm.os.Log("DrawConfigureWinch: inventorySlot is nil")
        return
    end
    local inventory = playerData[playerId].inventory
    local winchItem = inventory.slots[inventorySlot]
    local winch = winchItem.objectReference
    tm.playerUI.AddUIButton(playerId, "btnReturn", btnReturn, function() UI.UpdateUi(playerId, "loadout") end)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Configure Winch " .. inventorySlot .. " -~")
    tm.playerUI.AddUILabel(playerId, "lblWinchStiffness", "Stiffness:")
    tm.playerUI.AddUIText(playerId, "txtWinchStiffness", winch.stiffness, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) <= 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 0", 5, UI.WINCH_ICON)
            return
        end
        winch.stiffness = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchMaxStretch", "Max Stretch:")
    tm.playerUI.AddUIText(playerId, "txtWinchMaxStretch", winch.maxStretch, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 100 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number > 100", 5, UI.WINCH_ICON)
            return
        end
        winch.maxStretch = tonumber(UICallbackData.value)
    end)
    tm.playerUI.AddUILabel(playerId, "lblWinchSpeed", "Speed:")
    tm.playerUI.AddUIText(playerId, "txtWinchSpeed", winch.speed, function(UICallbackData)
        if tonumber(UICallbackData.value) == nil or tonumber(UICallbackData.value) < 0 then
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Invalid Value", "Value must be a number >= 0", 5, UI.WINCH_ICON)
            return
        end
        winch.speed = tonumber(UICallbackData.value)
    end)
end

local function ShowTutorialStep(playerId)
    local tutorial = playerData[playerId].tutorial
    local settings = playerData[playerId].settings
    local inventoryKeybinds = settings.keybinds.inventory
    local winchKeybinds = settings.keybinds.winch


    tm.playerUI.SetUIValue(playerId, "lblTutorialStep",
        "Tutorial " .. tutorial.step .. "/12: " .. TUTORIAL_STEP_NAMES[tutorial.step])
    if tutorial.step == 1 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Welcome to the Tutorial",
            "In this brief tutorial you will learn how to connect winches and use them.", 5)
        tutorial.advanceAt = tm.os.GetTime() + 5
    elseif tutorial.step == 2 then
        local structure = tm.players.OccupiedStructure(playerId)
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "How to connect to a build?",
            "Your build needs at least one connection block.", 5)
        for _, item in ipairs(Winch.CONNECTION_POINT.ATTACHABLE_BLOCKS) do
            tutorial.validConnectionBlockInfos[#tutorial.validConnectionBlockInfos + 1] =
                tm.playerUI.AddSubtleMessageForPlayer(playerId, "Valid Connection Block", item,
                    100, UI.BLOCK_ICONS[item])
        end
        if structure == nil or #GetAllConnectionPointsOnStructure(structure) == 0 then
            tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "", "Please place one on your build.", 8)
        else
            tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "", "You already have one on your build. :)", 2)
        end
    elseif tutorial.step == 3 then
        for _, subtleMessage in ipairs(tutorial.validConnectionBlockInfos) do
            tm.playerUI.RemoveSubtleMessageForPlayer(playerId, subtleMessage)
            subtleMessage = nil
        end
        tutorial.validConnectionBlockInfos = {}
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Open the Inventory",
            "Open the inventory with '" .. inventoryKeybinds.openClose .. "'.", 8)
    elseif tutorial.step == 4 then
        local navigationText
        if inventoryKeybinds.left == "left" and inventoryKeybinds.right == "right" then
            navigationText = "the arrow keys"
        else
            navigationText = "'" .. inventoryKeybinds.left .. "' and '" .. inventoryKeybinds.right .. "'"
        end
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Select an Anchor",
            "Use " .. navigationText .. " to select an Anchor.", 8)
    elseif tutorial.step == 5 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Place the Anchor",
            "Press '" .. inventoryKeybinds.useItem .. "' to enter place mode.", 5)
    elseif tutorial.step == 6 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Place the Anchor",
            "Press F4 to release your cursor, then click a valid surface.", 5)
    elseif tutorial.step == 7 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Select a Winch",
            "Use the inventory navigation keys to select a Winch.", 5)
    elseif tutorial.step == 8 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Connect the Winch",
            "Press '" .. inventoryKeybinds.useItem .. "' to enter connect mode.", 8)
    elseif tutorial.step == 9 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Connect to Your Build",
            "Press F4, then click a connection point on your build.", 8)
    elseif tutorial.step == 10 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Connect to the Anchor",
            "Click the anchor you placed earlier.", 8)
    elseif tutorial.step == 11 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Using the Winch",
            "Extend and retract the winch with '" .. winchKeybinds.extend .. "' and '" ..
            winchKeybinds.pull .. "'.", 8)
    elseif tutorial.step == 12 then
        tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, "Tutorial Complete!",
            "Check the settings and loadout pages to customize your winch.", 8)
        tutorial.completeAt = tm.os.GetTime() + 8
    end
end

function UI.StartTutorial(playerId)
    local tutorial = playerData[playerId].tutorial
    tutorial.active = true
    tutorial.step = 1
    tutorial.advanceAt = nil
    tutorial.completeAt = nil
    UI.UpdateUi(playerId, "tutorial")
end

function UI.AdvanceTutorial(playerId, expectedStep, nextStep)
    local tutorial = playerData[playerId].tutorial
    if not tutorial.active or tutorial.step ~= expectedStep then
        return false
    end

    tutorial.step = nextStep
    ShowTutorialStep(playerId)
    return true
end

local function DrawTutorial(playerId, data)
    tm.playerUI.AddUILabel(playerId, "lblHeading", "~- Tutorial -~")
    tm.playerUI.AddUIButton(playerId, "btnCancel", COLORS.GREEN .. "Cancel" .. COLORS.RESET, function()
        playerData[playerId].tutorial.active = false
        UI.UpdateUi(playerId, "main")
    end)
    tm.playerUI.AddUILabel(playerId, "lblTutorialStep", "Tutorial " .. 1 .. "/12: ")
    ShowTutorialStep(playerId)
end

function UI.UpdateUi(playerId, uiPage, data)
    data = data or {}
    local uiPages = {
        ["main"] = DrawMainMenu,
        ["settings"] = DrawSettings,
        ["keybinds"] = DrawKeybindSettings,
        ["loadout"] = DrawLoadout,
        ["configureWinch"] = DrawConfigureWinch,
        ["tutorial"] = DrawTutorial,
    }
    if uiPages[uiPage] then
        playerData[playerId].ui.page = uiPage
        playerData[playerId].inventory.isOpen = false
        playerData[playerId].ui.inventoryBoxId = nil
        tm.playerUI.ClearUI(playerId)
        uiPages[uiPage](playerId, data)
    else
        tm.os.Log("Invalid uiPage: " .. uiPage)
    end
end

function UI.UpdateInventoryMessage(playerId)
    local inventory = playerData[playerId].inventory
    local selectedSlot = inventory.slots[inventory.selectedSlot]
    local header = inventory.selectedSlot .. " - " .. inventory.loadout[inventory.selectedSlot].name
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
