math.clamp = math.clamp or function(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
table.clear = table.clear or function(value) for key in pairs(value) do value[key] = nil end end
table.clone = table.clone or function(value)
    local copy = {}
    for key, item in pairs(value) do copy[key] = item end
    return copy
end

local vector = {}
vector.__index = vector
Vector3 = setmetatable({
    to_elements = function(value) return value.x, value.y, value.z end,
}, {
    __call = function(_, x, y, z) return setmetatable({ x = x, y = y, z = z }, vector) end,
})
RESOLUTION_LOOKUP = { width = 1000, height = 600 }

local mod = {
    enabled = true,
    horde_marker_refs = {},
    horde_active_markers = {},
    horde_unit_data = {},
    get_enable_horde_esp = function() return true end,
    get_horde_distance = function() return 100 end,
    get_aim_location = function() return "head" end,
    io_dofile = function(_, path)
        local file = path:match("([^/]+)$")
        return dofile("scripts/mods/BallHammer/" .. file .. ".lua")
    end,
}
get_mod = function() return mod end
package.preload["scripts/managers/ui/ui_widget"] = function()
    return { create_definition = function(passes) return passes end }
end

local units = {}
local position_reads = 0
Unit = {
    has_node = function(unit, name) return units[unit].nodes[name] ~= nil end,
    node = function(_, name) return name end,
    world_position = function(unit, node)
        position_reads = position_reads + 1
        return node == 1 and units[unit].body or units[unit].nodes[node]
    end,
}
local parent = {
    _get_camera = function() return {} end,
    _get_screen_offset = function() return 0, 0 end,
    _convert_world_to_screen_position = function(_, _, position)
        return position.screen_x, 300 - position.z * 50
    end,
}

local template = dofile("scripts/mods/BallHammer/BallHammerHordeMarker.lua")
assert(not template.check_line_of_sight,
    "horde ESP should not spend one native visibility raycast per grunt")
local function widget_at(x)
    local definition = template.create_widget_defintion(template, "pivot")
    local styles = {}
    for _, pass in ipairs(definition) do styles[pass.style_id] = pass.style end
    assert(not styles.health_bg and not styles.health_fill,
        "grunt horde ESP should not draw per-enemy health bars")
    return { content = { distance = 20 }, style = styles, offset = { x, 300 } }
end

local markers = {}
HEALTH_ALIVE = {}
for i = 1, 4 do
    local unit = {}
    local screen_x = i == 4 and -20 or 100 + i * 30
    units[unit] = {
        body = { x = i - 1, y = 0, z = 0, screen_x = screen_x },
        nodes = {
            j_head = { x = i - 1, y = 0, z = 1.8, screen_x = screen_x },
            j_spine = { x = i - 1, y = 0, z = 1, screen_x = screen_x },
            j_leftfoot = { x = i - 1, y = 0, z = 0, screen_x = screen_x - 8 },
            j_rightfoot = { x = i - 1, y = 0, z = 0, screen_x = screen_x + 8 },
            j_leftarm = { x = i - 1, y = 0, z = 1.4, screen_x = screen_x - 4 },
            j_leftforearm = { x = i - 1, y = 0, z = 1.2, screen_x = screen_x - 6 },
            j_rightarm = { x = i - 1, y = 0, z = 1.4, screen_x = screen_x + 4 },
            j_rightforearm = { x = i - 1, y = 0, z = 1.2, screen_x = screen_x + 6 },
        },
    }
    mod.horde_unit_data[unit] = {
        name = "Enemy",
        color = { 255, 255, 158, 181 },
        base_height = 1.8,
        clusterable = true,
    }
    HEALTH_ALIVE[unit] = true
    local marker = { id = i, unit = unit, widget = widget_at(screen_x), draw = i ~= 4 }
    markers[i] = marker
    template.on_enter(marker.widget, marker)
end

local replacement = {
    id = markers[1].id,
    unit = markers[1].unit,
    widget = markers[1].widget,
    draw = true,
}
mod.horde_active_markers[replacement.unit] = true
template.on_enter(replacement.widget, replacement)
template.on_exit(nil, markers[1])
assert(mod.horde_marker_refs[replacement.unit] == replacement
    and mod.horde_active_markers[replacement.unit],
    "an old horde marker exit must not clear a newer replacement")
markers[1] = replacement

template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 0.7)
assert(position_reads <= 24,
    "horde projection should inspect only the body-extents bones needed by the grouped ESP")
assert(markers[1].widget.content.draw_box and not markers[1].widget.content.draw_dot,
    "a first-time horde join should begin from the member box")
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[2].widget, markers[2], nil, nil, 0.7)
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[4].widget, markers[4], nil, nil, 0.7)
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 1)
assert(markers[1].widget.content.label == "Horde x4",
    "a member just outside the screen should remain in the buffered horde count")
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[2].widget, markers[2], nil, nil, 1)
assert(markers[2].widget.style.dot.offset[2] == -90,
    "horde dots should use the configured head bone instead of the root below the feet")
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[4].widget, markers[4], nil, nil, 1)
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 1.5)
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[4].widget, markers[4], nil, nil, 1.5)

units[markers[4].unit].body.x = 20
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 1.516)
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[4].widget, markers[4], nil, nil, 1.516)
assert(markers[1].widget.content.label == "Horde x3",
    "horde count should decrease after a member leaves the world-space group")
assert(markers[4].widget.content.draw_box and markers[4].widget.content.draw_dot,
    "a splitting member should expand its box while its horde dot fades")
local splitting_alpha = markers[4].widget.style.top.color[1]

units[markers[4].unit].body.x = 3
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 1.532)
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[4].widget, markers[4], nil, nil, 1.532)
assert(markers[4].widget.style.top.color[1] < splitting_alpha,
    "a mid-animation rejoin should reverse the existing transition without racing it")
assert(markers[1].widget.content.label == "Horde x4",
    "rejoining the world-space group should restore the horde count")

for _, position in pairs(units[markers[4].unit].nodes) do position.screen_x = -100 end
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 2)
assert(markers[1].widget.content.label == "Horde x4",
    "horde members should remain counted inside the expanded edge buffer")
for _, position in pairs(units[markers[4].unit].nodes) do position.screen_x = -180 end
template.update_function(parent, { scale = 1, inverse_scale = 1 }, markers[1].widget, markers[1], nil, nil, 2.1)
assert(markers[1].widget.content.label == "Horde x3",
    "horde count should still decrease after a member leaves the edge buffer")
print("BallHammer horde marker smoke: ok")
