local horde = {}

local MAX_HORIZONTAL_DISTANCE = 3.5
local MAX_VERTICAL_DISTANCE = 1.5
local MAX_HORIZONTAL_DIAMETER = 5
local MAX_VERTICAL_DIAMETER = 2
local INFECTED_HORIZONTAL_DISTANCE = 4

local function close_in_world(a, b, horizontal_distance, vertical_distance)
    local x = a.x - b.x
    local y = a.y - b.y
    local z = a.z - b.z
    return x * x + y * y <= horizontal_distance * horizontal_distance
        and math.abs(z) <= vertical_distance
end

local function world_close_to_group(cluster, candidate)
    local horizontal_distance = candidate.force_horde_merge
        and INFECTED_HORIZONTAL_DISTANCE or MAX_HORIZONTAL_DISTANCE
    for i = 1, #cluster.members do
        if close_in_world(cluster.members[i].world, candidate.world,
            horizontal_distance, MAX_VERTICAL_DISTANCE) then
            return true
        end
    end
    return false
end

local function compact_after_add(cluster, candidate)
    for i = 1, #cluster.members do
        if not close_in_world(cluster.members[i].world, candidate.world,
            MAX_HORIZONTAL_DIAMETER, MAX_VERTICAL_DIAMETER) then
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
                        if world_close_to_group(cluster, candidate) and compact_after_add(cluster, candidate) then
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
