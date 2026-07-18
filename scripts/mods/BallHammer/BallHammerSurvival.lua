local Survival = {}

local THREAT_PRIORITY = { disabling = 3, lethal = 2, other = 1 }
local DODGE_THREATS = {
    hound = true,
    trapper = true,
    mutant = true,
    rager = true,
    sniper = true,
    flamer = true,
    grenade = true,
    overhead = true,
}
local DODGE_WINDOWS = {
    mutant = { 0.18, 0.35 },
    hound = { 0.18, 0.38 },
    trapper = { 0.12, 0.28 },
    rager = { 0.14, 0.28 },
    sniper = { 0.12, 0.28 },
    flamer = { 0.12, 0.28 },
    grenade = { 0.15, 0.35 },
    overhead = { 0.18, 0.55 },
}

function Survival.safe_timing(start_t, end_t, timing)
    if not start_t or not end_t or end_t < start_t then return nil end
    return start_t + (end_t - start_t) * math.max(0, math.min(100, timing or 50)) / 100
end

function Survival.reaction_time(kind, start_t, impact_t, timing)
    local preferred = Survival.safe_timing(start_t, impact_t, timing)
    local window = DODGE_WINDOWS[kind]
    if not preferred or not window then return preferred end
    return math.max(impact_t - window[2], math.min(impact_t - window[1], preferred))
end

function Survival.charge_impact_time(dx, dy, vx, vy, min_speed, max_time, miss_radius)
    min_speed = min_speed or 7
    max_time = max_time or 1.25
    miss_radius = miss_radius or 1.5
    local speed_squared = vx * vx + vy * vy
    if speed_squared < min_speed * min_speed then return nil end
    local impact_t = (dx * vx + dy * vy) / speed_squared
    if impact_t < 0 or impact_t > max_time then return nil end
    local miss_x, miss_y = dx - vx * impact_t, dy - vy * impact_t
    return miss_x * miss_x + miss_y * miss_y <= miss_radius * miss_radius
        and impact_t or nil
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
