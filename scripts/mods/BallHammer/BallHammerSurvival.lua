local Survival = {}

local THREAT_PRIORITY = { disabling = 3, lethal = 2, other = 1 }
local DODGE_THREATS = {
    hound = true,
    trapper = true,
    mutant = true,
    sniper = true,
    flamer = true,
    grenade = true,
}

function Survival.safe_timing(start_t, end_t, timing)
    if not start_t or not end_t or end_t < start_t then return nil end
    return start_t + (end_t - start_t) * math.max(0, math.min(100, timing or 50)) / 100
end

function Survival.prefer_threat(current, candidate)
    if not current then return candidate end
    if not candidate then return current end
    local current_priority = THREAT_PRIORITY[current.category] or 0
    local candidate_priority = THREAT_PRIORITY[candidate.category] or 0
    if candidate_priority ~= current_priority then
        return candidate_priority > current_priority and candidate or current
    end
    return (candidate.impact_t or math.huge) < (current.impact_t or math.huge) and candidate or current
end

function Survival.reaction(threat, context)
    context = context or {}
    if DODGE_THREATS[threat and threat.kind] then return "dodge" end
    if threat and threat.kind == "overhead" then
        if context.can_block then return "block" end
        if context.can_switch and (threat.time_left or 0) >= (context.switch_lead or math.huge) then
            return "switch_block"
        end
        return "dodge"
    end
    return "marker"
end

function Survival.should_push(distances, stamina, reserve, safe_retreat)
    if safe_retreat or (stamina or 0) <= (reserve or 0) then return false end
    local nearby = 0
    for i = 1, #distances do
        if distances[i] <= 4 then nearby = nearby + 1 end
    end
    return nearby >= 3
end

function Survival.govern(current, target, increment, suppressed, resume_margin)
    local resume_at = target - (resume_margin or 0.1)
    if suppressed and current <= resume_at then return false, true end
    return current + math.max(increment or 0, 0) > target, false
end

return Survival
