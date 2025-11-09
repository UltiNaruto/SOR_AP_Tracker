ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/tab_mapping.lua")

CUR_INDEX = -1
SLOT_DATA = nil
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}
EASY_MODE = false
STAGES_TO_CLEAR = 8

function onClear(slot_data)
    local hasExtraToyHeadLocation = false
    local canReachCraterFromOverworld = false
    SLOT_DATA = slot_data
    CUR_INDEX = -1
    -- reset locations
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local obj = Tracker:FindObjectForCode(location)
                if obj then
                    if location:sub(1, 1) == "@" then
                        obj.AvailableChestCount = obj.ChestCount
                    else
                        obj.Active = false
                    end
                end
            end
        end
    end
    -- reset items
    for _, v in pairs(ITEM_MAPPING) do
        if v[1] and v[2] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing item %s of type %s", v[1], v[2]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[2] == "toggle" then
                    obj.Active = false
                elseif v[2] == "progressive" then
                    obj.CurrentStage = 0
                    obj.Active = false
                elseif v[2] == "consumable" then
                    obj.AcquiredCount = 0
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown item type %s for code %s", v[2], v[1]))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: could not find object for code %s", v[1]))
            end
        end
    end

    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    
    DATA_STORAGE_ID = PLAYER_ID.."_"..TEAM_NUMBER.."_streets_of_rage_area"

    EASY_MODE = slot_data["easy_mode"] == 1
    local obj = Tracker:FindObjectForCode("easy_mode")
    if obj then
        if EASY_MODE then
            obj.CurrentStage = 0
        else
            obj.CurrentStage = 1
        end
    end

    STAGES_TO_CLEAR = slot_data["stages_to_clear"]
    local obj = Tracker:FindObjectForCode("stages_to_clear_for_goal")
    if obj then
        obj.CurrentStage = STAGES_TO_CLEAR - 4
    end
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
    local function setItem(itemName, itemType)
        local obj = Tracker:FindObjectForCode(itemName)
        if obj then
            if itemType == "toggle" then
                obj.Active = true
            elseif itemType == "progressive" then
                if obj.Active then
                    obj.CurrentStage = obj.CurrentStage + 1
                else
                    obj.Active = true
                end
            elseif itemType == "consumable" then
                obj.AcquiredCount = obj.AcquiredCount + obj.Increment
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onItem: unknown item type %s for code %s", itemType, itemName))
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: could not find object for code %s", itemName))
        end
    end

    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
    end
    if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
        return
    end
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local v = ITEM_MAPPING[item_id-0xDEAFF00D]
    if not v then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: could not find item mapping for id %s", item_id))
        end
        return
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: code: %s, type %s", v[1], v[2]))
    end
    if not v[1] then
        return
    end

    if v[1] == "cassette_player" then
        setItem("cassette_1", "toggle")
    end

    setItem(v[1], v[2])
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
    local location_array = LOCATION_MAPPING[location_id-(0xDEAFF00D+50)]
    if not location_array or not location_array[1] then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
        return
    end

    for i, location in pairs(location_array) do
        if i == 1 then
            local obj = Tracker:FindObjectForCode(location)
            if obj then
                if location:sub(1, 1) == "@" then
                    obj.AvailableChestCount = obj.AvailableChestCount - 1
                else
                    obj.Active = true
                end
            else
                print(string.format("onLocation: could not find object for code %s", location))
            end
        end
    end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
            item_player))
    end
end

-- called when a bounce message is received
function onBounce(json)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onBounce: %s", dump_table(json)))
    end
end

function onNotify(key, value, old_value)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onNotify: %s, %s, %s",key,value,old_value))
    end

    if key == DATA_STORAGE_ID then
        updateTab(value)
    end
end

function onNotifyLaunch(key, value)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onNotifyLaunch: %s, %s",key,value))
    end

    if key == DATA_STORAGE_ID then
        updateTab(value)
    end
end

function updateTab(value)
    if value ~= nil then
        print("updateTab", value)
        local tabswitch = Tracker:FindObjectForCode("tab_switch")
        if tabswitch.Active then
            if TAB_MAPPING[value] then
                CURRENT_ROOM = TAB_MAPPING[value]
                 do
                    Tracker:UiHint("ActivateTab", CURRENT_ROOM)
                    print(string.format("Updating  Tab to %s",CURRENT_ROOM))
                end
            else
                CURRENT_ROOM = TAB_MAPPING[0x00]
                print(string.format("Failed to find ID %s",value))
                Tracker:UiHint("ActivateTab", CURRENT_ROOM)
            end
        end
    end
end

Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    Archipelago:AddLocationHandler("location handler", onLocation)
end
Archipelago:AddSetReplyHandler("notify handler", onNotify)
Archipelago:AddRetrievedHandler("notify launch handler", onNotifyLaunch)