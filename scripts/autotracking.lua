-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_ITEM_TRACKING = true
AUTOTRACKER_ENABLE_LOCATION_TRACKING = true and not IS_ITEMS_ONLY
AUTOTRACKER_ENABLE_DEBUG_LOGGING = true and ENABLE_DEBUG_LOG
AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP = true and AUTOTRACKER_ENABLE_DEBUG_LOGGING
-------------------------------------------------------
print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
print("Enable Location Tracking:    ", AUTOTRACKER_ENABLE_LOCATION_TRACKING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
    print("Enable Debug Logging:        ", AUTOTRACKER_ENABLE_DEBUG_LOGGING)
    print("Enable AP Debug Logging:        ", AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP)
end
print("---------------------------------------------------------------------")
print("")

-- loads the AP autotracking code
ScriptHost:LoadScript("scripts/autotracking/archipelago.lua")

local GetIndexOfLocation = function(locName)
    res = {
        ["id"] = -1,
        ["menu"] = nil
    }

    for idx, loc in pairs(LOCATION_MAPPING) do
        for j, name in pairs(loc) do
            if name == "@"..locName then
                res["id"] = idx
                res["menu"] = j == 1
                break
            end
        end
    end
    return res
end

LOCK_SYNC = false

ScriptHost:AddOnLocationSectionChangedHandler("Location handler", function(srcLocation)
    if not LOCK_SYNC then
        LOCK_SYNC = true
        res = GetIndexOfLocation(srcLocation.FullID)
        
        -- sync both items
        if res["id"] ~= -1 then
            local src = srcLocation.FullID
            local dst = LOCATION_MAPPING[res["id"]][res["menu"] and 2 or 1]
            local dstLocation = Tracker:FindObjectForCode(dst)

            if src and dst then
                if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                    print("Using "..src.." to set "..dst:sub(2).."...")
                end
                dstLocation.AvailableChestCount = srcLocation.AvailableChestCount
            end
        end
        LOCK_SYNC = false
    end
end)

