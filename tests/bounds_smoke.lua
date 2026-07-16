local vector = {}
vector.__index = vector
Vector3 = setmetatable({
    to_elements = function(value) return value.x, value.y, value.z end,
}, {
    __call = function(_, x, y, z) return setmetatable({ x = x, y = y, z = z }, vector) end,
})

local unit = {}
local nodes = {
    j_head = Vector3(3, 0, 1),
    j_hips = Vector3(0, 0, 0.7),
    j_spine = Vector3(1, 0, 0.8),
    j_leftfoot = Vector3(-1, 0, 0),
    j_rightfoot = Vector3(1, 0, 0),
}
Unit = {
    has_node = function(_, name) return nodes[name] ~= nil end,
    node = function(_, name) return name end,
    world_position = function(_, node) return nodes[node] end,
}

local parent = {
    _convert_world_to_screen_position = function(_, _, position)
        return 100 + position.x * 10, 200 - position.z * 50
    end,
    _get_screen_offset = function() return 0, 0 end,
}
local Bounds = dofile("scripts/mods/BallHammer/BallHammerBounds.lua")
local box = Bounds.project(parent, { scale = 1, inverse_scale = 1 }, {}, unit, Vector3(0, 0, 0), 1.8, "j_head")

assert(box.left == 87 and box.right == 133 and box.top == 147 and box.bottom == 203,
    "bone bounds should contain the hound's head and feet with three-pixel padding")
assert(box.aim_x == 130 and box.aim_y == 150,
    "the configured aim bone should provide the horde dot position")
assert(Bounds.in_screen_buffer({ left = -30, right = -1, top = 100, bottom = 150 }, 1000, 600, 48),
    "targets just outside the screen should remain inside the horde buffer")
assert(not Bounds.in_screen_buffer({ left = -100, right = -60, top = 100, bottom = 150 }, 1000, 600, 48),
    "targets beyond the horde buffer should be excluded")
print("BallHammer bounds smoke: ok")
