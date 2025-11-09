function has(item)
    local obj = Tracker:FindObjectForCode(item)
    if obj then
        return obj.Active
    end

    return false
end

function has_all(...)
    for i = 1, select("#", ...) do
        item = select(i, ...)
        if not has(item) then
            return false
        end
    end

    return true
end

function has_any(...)
    for i = 1, select("#", ...) do
        item = select(i, ...)
        if has(item) then
            return true
        end
    end

    return false
end

function can_reach_stage(stage_idx)
    return has("stage_"..stage_idx.."_key")
end

function can_reach_final_boss()
    -- you need to have stage 8 access to reach final boss
    if not has("stage_8_key") then
        return false
    end

    -- TODO: check cleared stages against goal
    return false
end