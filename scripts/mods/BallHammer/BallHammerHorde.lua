local horde = {}

local MAX_WORLD_DISTANCE = 4.5
local MAX_WORLD_DIAMETER = 6
local INFECTED_WORLD_DISTANCE = 7

local function distance_squared(a, b)
    local x = a.x - b.x
    local y = a.y - b.y
    local z = a.z - b.z
    return x * x + y * y + z * z
end

local function world_close_to_group(cluster, candidate)
    local max_distance = candidate.force_horde_merge and INFECTED_WORLD_DISTANCE or MAX_WORLD_DISTANCE
    local max_squared = max_distance * max_distance
    for i = 1, #cluster.members do
        if distance_squared(cluster.members[i].world, candidate.world) <= max_squared then
            return true
        end
    end
    return false
end

local function compact_after_add(cluster, candidate)
    local max_diameter_squared = MAX_WORLD_DIAMETER * MAX_WORLD_DIAMETER
    for i = 1, #cluster.members do
        if distance_squared(cluster.members[i].world, candidate.world) > max_diameter_squared then
            return false
        end
    end
    return true
end

local function include_box(cluster, box)
    if box.left then
        cluster.left = cluster.left and math.min(cluster.left, box.left) or box.left
        cluster.right = cluster.right and math.max(cluster.right, box.right) or box.right
        cluster.top = cluster.top and math.min(cluster.top, box.top) or box.top
        cluster.bottom = cluster.bottom and math.max(cluster.bottom, box.bottom) or box.bottom
    end
    cluster.count = cluster.count + 1
    cluster.members[#cluster.members + 1] = box
end

function horde.build_clusters(boxes)
    local ordered = {}
    for i = 1, #boxes do
        if boxes[i].in_buffer ~= false then ordered[#ordered + 1] = boxes[i] end
    end
    table.sort(ordered, function(a, b)
        if not a.force_horde_merge ~= not b.force_horde_merge then return not a.force_horde_merge end
        return a.id < b.id
    end)

    local assigned = {}
    local clusters = {}

    for seed = 1, #ordered do
        if not assigned[seed] then
            local first = ordered[seed]
            local cluster = {
                left = first.left,
                right = first.right,
                top = first.top,
                bottom = first.bottom,
                count = 1,
                members = { first },
            }
            assigned[seed] = true

            local changed = true
            while changed do
                changed = false
                for candidate_index = seed + 1, #ordered do
                    if not assigned[candidate_index] then
                        local candidate = ordered[candidate_index]
                        if world_close_to_group(cluster, candidate) and
                           (candidate.force_horde_merge or compact_after_add(cluster, candidate)) then
                            include_box(cluster, candidate)
                            assigned[candidate_index] = true
                            changed = true
                        end
                    end
                end
            end

            clusters[#clusters + 1] = cluster
        end
    end

    return clusters
end

return horde
