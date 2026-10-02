local SAVING = {}

local PLAYERDATA_PATH = "PlayerData.json"
local SESSIONDATA_PATH = "SessionData.json"

SAVING.lastPlayerDataSave = tm.os.GetTime()


function SAVING.Setup(config)
    ITEM_TYPES = config.ITEM_TYPES
    UI = config.UI
end


local function loadPlayerSaves()
    local success, data = pcall(function()
        local fileText = tm.os.ReadAllText_Dynamic(PLAYERDATA_PATH)
        if fileText == nil or fileText == "" then
            return {}
        end

        local parsed = json.parse(fileText)
        if parsed == nil then
            return {}
        end

        return parsed
    end)

    if not success then
        tm.os.Log("Player data file unreadable or missing -> Creating new file")
        return {}
    end

    if type(data) ~= "table" then
        tm.os.Log("Player data file did not contain a table -> Resetting")
        return {}
    end

    return data
end

local function serializeItemType(itemType)
    if itemType == nil or itemType.name == nil then
        return nil
    end

    return { name = itemType.name }
end

local function deserializeItemType(itemData)
    if type(itemData) ~= "table" or type(itemData.name) ~= "string" then
        return nil
    end

    local itemType = ITEM_TYPES[string.lower(itemData.name)]
    if itemType then
        return itemType
    else
        tm.os.Log("Unknown item type: " .. itemData.name)
        return nil
    end
end

local function deserializePlayerLoadout(loadoutData)
    local loadout = {}

    if type(loadoutData) ~= "table" then
        return loadout
    end

    for _, itemData in ipairs(loadoutData) do
        local itemType = deserializeItemType(itemData)
        if itemType ~= nil then
            table.insert(loadout, itemType)
        end
    end

    return loadout
end

function SAVING.savePlayerData(playerDataTable)
    local playerSaves = loadPlayerSaves()
    local playerList = tm.players.CurrentPlayers()

    for key, player in ipairs(playerList) do
        local playerData = playerDataTable[player.playerId]
        if playerData and playerData.inventory and playerData.inventory.loadout then
            local profileId = tm.players.GetPlayerProfileId(player.playerId)
            local loadout = {}

            for _, item in ipairs(playerData.inventory.loadout) do
                local serializedItem = serializeItemType(item)
                if serializedItem ~= nil then
                    table.insert(loadout, serializedItem)
                end
            end

            playerSaves[profileId] = {
                loadout = loadout,
                settings = playerData.settings
            }
        end
    end

    tm.os.WriteAllText_Dynamic(PLAYERDATA_PATH, json.serialize(playerSaves))
    SAVING.lastPlayerDataSave = tm.os.GetTime()
    tm.playerUI.AddSubtleMessageForAllPlayers("", "Player data saved", 1, UI.SAVE_ICON)
    tm.os.Log("Player data saved")
end

function SAVING.loadPlayerData(playerId)
    local profileId = tm.players.GetPlayerProfileId(playerId)
    local playerSaves = loadPlayerSaves()

    local playerSaveData = playerSaves[profileId]
    if playerSaveData == nil then
        return nil
    end

    local loadedSave = {
        loadout = deserializePlayerLoadout(playerSaveData.loadout),
        settings = playerSaveData.settings
    }

    return loadedSave
end

function SAVING.saveSessionSettings(sessionData)
    tm.os.WriteAllText_Dynamic(SESSIONDATA_PATH, json.serialize(sessionData))
    tm.os.Log("Session data saved")
end

function SAVING.loadSessionSettings()
    local success, sessionDataText = pcall(tm.os.ReadAllText_Dynamic, SESSIONDATA_PATH)
    if not success or sessionDataText == "" then
        tm.os.Log("Failed to read session data")
        return nil
    end

    local sessionData = json.parse(sessionDataText)
    return sessionData
end

return SAVING
