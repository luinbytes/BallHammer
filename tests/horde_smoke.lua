local horde = dofile("scripts/mods/BallHammer/BallHammerHorde.lua")

local function box(id, left, top, world_x, force_horde_merge, in_buffer)
    return {
        id = id,
        left = left,
        top = top,
        right = left + 20,
        bottom = top + 60,
        world = { x = world_x, y = 0, z = 0 },
        force_horde_merge = force_horde_merge,
        in_buffer = in_buffer,
    }
end

local nearby = {
    box(1, 100, 100, 0),
    box(2, 125, 104, 2),
    box(3, 148, 108, 4),
}

local clusters = horde.build_clusters(nearby)
assert(#clusters == 1, "nearby horde boxes should merge")
assert(clusters[1].count == 3, "merged horde should report its member count")
assert(clusters[1].left == 100 and clusters[1].right == 168, "merged box should use the dynamic union")

local rotated_view = {
    box(1, 20, 100, 0),
    box(2, 140, 104, 2),
    box(3, 260, 108, 4),
}

clusters = horde.build_clusters(rotated_view)
assert(#clusters == 1 and clusters[1].count == 3,
    "camera angle must not change grouping for the same world-space horde")

local buffered_offscreen = {
    box(1, 100, 100, 0),
    box(2, 125, 104, 2),
    box(3, -30, 108, 4, false, true),
}

clusters = horde.build_clusters(buffered_offscreen)
assert(#clusters == 1 and clusters[1].count == 3,
    "members inside the off-screen buffer should remain in their world-space horde")

local far_offscreen = {
    box(1, 100, 100, 0),
    box(2, 125, 104, 2),
    box(3, -100, 108, 4, false, false),
}

clusters = horde.build_clusters(far_offscreen)
assert(#clusters == 1 and clusters[1].count == 2,
    "horde count should drop when a member leaves the off-screen buffer")

local stretched = {
    box(1, 100, 100, 0),
    box(2, 125, 104, 3.5),
    box(3, 148, 108, 7),
    box(4, 171, 112, 10.5),
}

clusters = horde.build_clusters(stretched)
assert(#clusters == 2, "long chained hordes should split into compact groups")
assert(clusters[1].count == 2 and clusters[2].count == 2, "split groups should stay compact")

local sparse = {
    box(1, 100, 100, 0),
    box(2, 125, 104, 8),
}

clusters = horde.build_clusters(sparse)
assert(#clusters == 2, "screen overlap alone must not merge distant enemies")

local infected_edge = {
    box(1, 100, 100, 0),
    box(2, 125, 104, 2),
    box(3, 148, 108, 4),
    box(4, 171, 112, 6),
    box(5, 194, 116, 8, true),
    box(6, 217, 120, 10, true),
}

clusters = horde.build_clusters(infected_edge)
assert(#clusters == 1 and clusters[1].count == 6,
    "newly infected and armored infected should merge into an adjacent horde")

print("BallHammer horde smoke: ok")
