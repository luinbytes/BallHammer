local mod = {
    get_unit_data = function() return nil end,
    get_enable_nameplates = function() return true end,
    get_max_distance = function() return 100 end,
    marker_refs = {},
    active_markers = {},
    enabled = true,
    io_dofile = function() return dofile("scripts/mods/BallHammer/BallHammerBounds.lua") end,
}
table.clone = table.clone or function(value)
    local copy = {}
    for key, item in pairs(value) do copy[key] = item end
    return copy
end

get_mod = function() return mod end
package.preload["scripts/managers/ui/ui_widget"] = function()
    return { create_definition = function(passes) return passes end }
end
package.preload["scripts/managers/ui/ui_font_settings"] = function()
    return { nameplates = { font_type = "unused" } }
end

local template = dofile("scripts/mods/BallHammer/BallHammerMarker.lua")
local definition = template.create_widget_defintion(template, "pivot")
local styles = {}
for _, pass in ipairs(definition) do styles[pass.style_id] = pass.style end
assert(styles.top and styles.bottom and styles.left and styles.right, "Perkaholic style needs a four-line box")
assert(styles.name.font_type == "mono_tide_regular", "Perkaholic style needs a compact monospace label")
assert(styles.name.font_size == 13 and styles.flag.font_size == 11,
    "names and flags should remain readable over the game")
assert(styles.name_shadow and styles.flag_shadow,
    "ESP text should use the Perkaholic one-pixel shadow")
assert(styles.top.color[2] == 255 and styles.top.color[3] == 158 and styles.top.color[4] == 181,
    "Perkaholic accent should be #ff9eb5")

local unit = {}
local marker = {
    unit = unit,
    data = { name = "Ritualist", flag = "SPECIAL", color = { 255, 255, 80, 80 } },
    draw = true,
    base_height = 1.8,
}
local widget = {
    content = { name = "ESP", flag = "", distance = 90 },
    style = styles,
    offset = { 100, 200 },
}

template.on_enter(widget, marker, template)

assert(widget.content.name == "Ritualist" and widget.content.flag == "SPECIAL",
    "name and category flag should render separately")
assert(widget.style.top.color[3] == 80 and widget.style.name.text_color[3] == 80,
    "priority markers should use their breed category color")
assert(mod.marker_refs[unit] == marker, "marker should register its unit reference")

local vector = {}
vector.__index = vector
vector.__add = function(a, b)
    return setmetatable({ x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }, vector)
end
Vector3 = function(x, y, z) return setmetatable({ x = x, y = y, z = z }, vector) end
HEALTH_ALIVE = { [unit] = true }
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
    world_position = function(_, node) return node == 1 and Vector3(0, 0, 0) or nodes[node] end,
}
local projected_top_y = 200
local parent = {
    _get_camera = function() return {} end,
    _convert_world_to_screen_position = function(_, _, position)
        return 100 + position.x * 10, projected_top_y - position.z * 50
    end,
    _get_screen_offset = function() return 0, 0 end,
}
template.update_function(parent, { scale = 1, inverse_scale = 1 }, widget, marker)
assert(widget.content.name == "Ritualist 90m", "distance should stay with the name above the box")
assert(widget.style.top.size[1] == 46,
    "priority boxes should use projected bone extents instead of inferred humanoid width")
local flag_left = widget.style.flag.offset[1] - widget.style.flag.size[1] * 0.5
assert(widget.style.name.offset[1] == 0 and widget.style.name.offset[2] < widget.style.top.offset[2],
    "name should stay centered above the box")
assert(math.abs(flag_left - widget.style.right.offset[1] - 4) < 0.001 and
    math.abs(widget.style.flag.offset[2] - widget.style.top.offset[2] - 10) < 0.001,
    "flag should stay beside the box's upper-right edge")
assert(widget.style.name_shadow.offset[1] == widget.style.name.offset[1] + 1 and
    widget.style.name_shadow.offset[2] == widget.style.name.offset[2] + 1,
    "text shadow should remain one pixel behind the label")
projected_top_y = 220
template.update_function(parent, { scale = 1, inverse_scale = 1 }, widget, marker)
flag_left = widget.style.flag.offset[1] - widget.style.flag.size[1] * 0.5
assert(math.abs(flag_left - widget.style.right.offset[1] - 4) < 0.001 and
    widget.style.name.offset[1] == 0,
    "walking around an enemy should not move labels away from their box anchors")
assert(widget.style.top.color[1] == 64 and widget.style.name.text_color[1] == 64
    and widget.style.flag.text_color[1] == 64 and widget.style.name_shadow.text_color[1] < 64,
    "all marker elements should fade with distance")
print("BallHammer marker smoke: ok")
