table.clone = table.clone or function(value)
    local copy = {}
    for key, item in pairs(value) do copy[key] = item end
    return copy
end

local enabled = true
local pickup_filter = "all"
local unit = {}
local world_positions = { [unit] = { 0, 0, 0 } }
Unit = {
    world_position = function(value)
        assert(ALIVE[value] ~= false, "invalid UnitReference")
        return world_positions[value]
    end,
}
Vector3 = { to_elements = function(value) return value[1], value[2], value[3] end }
local data = { name = "Plasteel", category = "materials", color = { 255, 70, 220, 255 } }
local mod = {
    enabled = true,
    pickup_marker_refs = {},
    pickup_active_markers = {},
    get_pickup_data = function() return data end,
    get_enable_pickup_esp = function() return enabled end,
    get_pickup_distance = function() return 100 end,
    get_pickup_visible = function(value)
        return pickup_filter == "all" or value.category == pickup_filter
    end,
    io_dofile = function(_, path)
        local file = path:match("([^/]+)$")
        return dofile("scripts/mods/BallHammer/" .. file .. ".lua")
    end,
}
get_mod = function() return mod end
package.preload["scripts/managers/ui/ui_widget"] = function()
    return { create_definition = function(passes) return passes end }
end
ALIVE = { [unit] = true }

local template = dofile("scripts/mods/BallHammer/BallHammerPickupMarker.lua")
assert(template.unit_node == 1 and not template.check_line_of_sight,
    "pickup labels should anchor to the pickup and remain useful through clutter")
local definition = template.create_widget_defintion(template, "pivot")
local styles = {}
for _, pass in ipairs(definition) do styles[pass.style_id] = pass.style end
assert(styles.background and styles.accent and styles.name and styles.distance,
    "pickup markers should render a compact card with accent and distance hierarchy")
local background_left = styles.background.offset[1] - styles.background.size[1] * 0.5
local background_right = styles.background.offset[1] + styles.background.size[1] * 0.5
local name_left = styles.name.offset[1] - styles.name.size[1] * 0.5
local name_right = styles.name.offset[1] + styles.name.size[1] * 0.5
local distance_left = styles.distance.offset[1] - styles.distance.size[1] * 0.5
local distance_right = styles.distance.offset[1] + styles.distance.size[1] * 0.5
assert(name_left >= background_left and name_right < distance_left
    and distance_right <= background_right,
    "pickup name and distance must remain inside separate regions of the card")
assert(template.scale_settings == nil,
    "pickup cards should retain one readable screen size at every world distance")
local widget = { content = { distance = 80 }, style = styles }
local marker = { unit = unit, data = data, draw = true }
template.on_enter(widget, marker)
assert(widget.content.name == "Plasteel" and mod.pickup_marker_refs[unit] == marker,
    "pickup marker should register and display its classified name")
local replacement = { unit = unit, data = data, draw = true }
mod.pickup_active_markers[unit] = true
template.on_enter(widget, replacement)
template.on_exit(nil, marker)
assert(mod.pickup_marker_refs[unit] == replacement and mod.pickup_active_markers[unit],
    "an old marker exit must not clear a newer replacement")
marker = replacement
template.update_function(nil, nil, widget, marker)
assert(widget.visible and widget.content.distance_text == "80m"
    and widget.style.name.text_color[1] < 255,
    "pickup labels should include distance and fade near their range limit")
local nearby_unit = {}
local third_unit = {}
ALIVE[nearby_unit] = true
ALIVE[third_unit] = true
world_positions[nearby_unit] = { 0.2, 0, 0 }
world_positions[third_unit] = { 0.4, 0, 0 }
local function pickup_widget(distance, x, y)
    local passes = template.create_widget_defintion(template, "pivot")
    local widget_styles = {}
    for _, pass in ipairs(passes) do widget_styles[pass.style_id] = pass.style end
    return { content = { distance = distance }, style = widget_styles, offset = { x, y } }
end
local nearby_data = { name = "Ammo", color = { 255, 255, 210, 70 } }
local third_data = { name = "Med Stimm", color = { 255, 70, 220, 80 } }
local nearby_widget = pickup_widget(81, 120, 104)
local third_widget = pickup_widget(82, 90, 96)
widget.offset = { 100, 100 }
local nearby_marker = { unit = nearby_unit, data = nearby_data, draw = true, widget = nearby_widget }
local third_marker = { unit = third_unit, data = third_data, draw = true, widget = third_widget }
marker.widget = widget
template.on_enter(nearby_widget, nearby_marker)
template.on_enter(third_widget, third_marker)
local markers = { marker, nearby_marker, third_marker }
local anchors = { { 100, 100 }, { 120, 104 }, { 90, 96 } }
local function update_stack(t)
    for i = 1, #markers do
        markers[i].widget.offset[1], markers[i].widget.offset[2] = anchors[i][1], anchors[i][2]
    end
    for i = 1, #markers do
        template.update_function(nil, nil, markers[i].widget, markers[i], nil, nil, t)
    end
end
update_stack(1)
update_stack(1.05)
assert(nearby_widget.offset[1] < 120 and nearby_widget.offset[1] > 103,
    "overlapping pickup cards should animate toward their shared stack")
update_stack(1.3)
assert(math.abs(widget.offset[1] - nearby_widget.offset[1]) < 1
    and math.abs(widget.offset[1] - third_widget.offset[1]) < 1,
    "overlapping pickup cards should align into one list")
assert(nearby_widget.offset[2] > third_widget.offset[2]
    and third_widget.offset[2] > widget.offset[2]
    and nearby_widget.offset[2] - third_widget.offset[2] >= 24
    and third_widget.offset[2] - widget.offset[2] >= 24,
    "pickup stacks should be alphabetically sorted without card overlap")
local extra_names = { "Celerity Stimm", "Combat Stimm", "Concentration Stimm", "Grenade" }
for i = 1, #extra_names do
    local extra_unit = {}
    ALIVE[extra_unit] = true
    world_positions[extra_unit] = { i * 0.08, 0.1, 0 }
    local extra_widget = pickup_widget(82 + i, 96 + i * 3, 98 + i)
    local extra_marker = {
        unit = extra_unit,
        data = { name = extra_names[i], color = { 255, 255, 255, 255 } },
        draw = true,
        widget = extra_widget,
    }
    template.on_enter(extra_widget, extra_marker)
    markers[#markers + 1] = extra_marker
    anchors[#anchors + 1] = { 96 + i * 3, 98 + i }
end
update_stack(1.5)
update_stack(1.8)
local visible_count, overflow_label = 0, false
local uniform_width
for i = 1, #markers do
    if markers[i].widget.visible then visible_count = visible_count + 1 end
    if markers[i].widget.content.name:find("+", 1, true) then overflow_label = true end
    assert(markers[i].widget.style.background.size[1] <= 184
        and markers[i].widget.style.background.size[2] == 24,
        "grouped pickups should use the smaller card with room for wrapped text")
    assert(markers[i].widget.style.shadow.size[1] > markers[i].widget.style.background.size[1]
        and markers[i].widget.style.background.color[1] < 150,
        "compact pickup cards should use a soft translucent background")
    uniform_width = uniform_width or markers[i].widget.style.background.size[1]
    assert(markers[i].widget.style.background.size[1] == uniform_width,
        "compact pickup cards should be uniformly wide")
end
assert(visible_count == #markers and not overflow_label,
    "dense pickup stacks should preserve every pickup label")
for i = 2, #markers do
    assert(math.abs(markers[i].widget.offset[1] - markers[1].widget.offset[1]) < 1,
        "grouped pickups should form one vertical list")
end
update_stack(10)
local before_camera_move = {}
for i = 1, #markers do
    if markers[i].widget.visible then
        before_camera_move[i] = {
            markers[i].widget.offset[1], markers[i].widget.offset[2],
        }
    end
    anchors[i][1] = anchors[i][1] + 180
    anchors[i][2] = anchors[i][2] + 70
end
update_stack(10.01)
for i, before in pairs(before_camera_move) do
    assert(math.abs(markers[i].widget.offset[1] - before[1] - 180) < 0.001
        and math.abs(markers[i].widget.offset[2] - before[2] - 70) < 0.001,
        "camera projection changes should move pickup stacks immediately without smoothing")
end

local close_units = { {}, {} }
local close_markers = {}
for i = 1, 2 do
    local close_unit = close_units[i]
    ALIVE[close_unit] = true
    world_positions[close_unit] = { 5 + i * 0.2, 0, 0 }
    local close_x = 1000 + (i - 1) * 170
    local close_widget = pickup_widget(1, close_x, 100)
    local close_marker = {
        unit = close_unit,
        data = {
            name = i == 1 and "Med Stimm" or "Concentration Stimm",
            color = { 255, 255, 255, 255 },
        },
        draw = true,
        widget = close_widget,
    }
    template.on_enter(close_widget, close_marker)
    markers[#markers + 1] = close_marker
    anchors[#anchors + 1] = { close_x, 100 }
    close_markers[i] = close_marker
end
update_stack(11)
update_stack(11.3)
assert(math.abs(close_markers[1].widget.offset[1] - close_markers[2].widget.offset[1]) == 170
    and math.abs(close_markers[1].widget.offset[2] - close_markers[2].widget.offset[2]) < 1
    and close_markers[2].widget.style.background.size[2] == 24
    and close_markers[1].widget.style.background.size[1] == close_markers[2].widget.style.background.size[1]
    and close_markers[2].widget.style.name.size[1] >= #"Concentration Stimm" * 6,
    "nearby pickups should detach to text-sized cards on their own projected anchors")

local close_overlap_markers = {}
for i = 1, 2 do
    local close_unit = {}
    ALIVE[close_unit] = true
    world_positions[close_unit] = { 8 + i * 0.2, 0, 0 }
    local close_x = 2000 + (i - 1) * 150
    local close_widget = pickup_widget(3, close_x, 100)
    local close_marker = {
        unit = close_unit,
        data = { name = i == 1 and "Ammo" or "Grenade", color = { 255, 255, 255, 255 } },
        draw = true,
        widget = close_widget,
    }
    template.on_enter(close_widget, close_marker)
    markers[#markers + 1] = close_marker
    anchors[#anchors + 1] = { close_x, 100 }
    close_overlap_markers[i] = close_marker
end
update_stack(11.5)
update_stack(11.9)
assert(math.abs(close_overlap_markers[1].widget.offset[1]
        - close_overlap_markers[2].widget.offset[1]) < 1
    and math.abs(close_overlap_markers[1].widget.offset[2]
        - close_overlap_markers[2].widget.offset[2]) >= 24,
    "nearby pickups should stay grouped until their anchors have a clean non-overlapping gap")

local spread_units = { {}, {} }
local spread_markers = {}
for i = 1, 2 do
    local spread_unit = spread_units[i]
    ALIVE[spread_unit] = true
    world_positions[spread_unit] = { 10 + (i - 1) * 1.2, 0, 0 }
    local spread_widget = pickup_widget(20, 1200 + i * 10, 100)
    local spread_marker = {
        unit = spread_unit,
        data = { name = "Spread " .. i, color = { 255, 255, 255, 255 } },
        draw = true,
        widget = spread_widget,
    }
    template.on_enter(spread_widget, spread_marker)
    markers[#markers + 1] = spread_marker
    anchors[#anchors + 1] = { 1200 + i * 10, 100 }
    spread_markers[i] = spread_marker
end
update_stack(12)
update_stack(12.3)
assert(math.abs(spread_markers[1].widget.offset[1] - spread_markers[2].widget.offset[1]) < 1
    and math.abs(spread_markers[1].widget.offset[2] - spread_markers[2].widget.offset[2]) >= 24,
    "spread-out pickup collisions should use the same compact vertical list")

local threshold_unit = {}
ALIVE[threshold_unit] = true
world_positions[threshold_unit] = { 20, 0, 0 }
local threshold_widget = pickup_widget(4, 1600, 100)
local threshold_marker = {
    unit = threshold_unit,
    data = { name = "Ammo", color = { 255, 255, 255, 255 } },
    draw = true,
    widget = threshold_widget,
}
template.on_enter(threshold_widget, threshold_marker)
markers[#markers + 1] = threshold_marker
anchors[#anchors + 1] = { 1600, 100 }
update_stack(13)
assert(threshold_widget.style.background.size[1] <= 184
    and threshold_widget.style.background.size[2] == 24,
    "a standalone pickup at the 4m grouping threshold must keep the compact card")

RESOLUTION_LOOKUP = { width = 1000, height = 600 }
local buffered_unit = {}
ALIVE[buffered_unit] = true
world_positions[buffered_unit] = { 0, 0, 0, screen_x = -100, screen_y = 100 }
local buffered_widget = pickup_widget(10, -100, 100)
local buffered_marker = {
    unit = buffered_unit,
    data = { name = "Grenade", color = { 255, 255, 255, 255 } },
    draw = false,
    widget = buffered_widget,
}
local deleted_unit = {}
ALIVE[deleted_unit] = false
mod.pickup_marker_refs[deleted_unit] = {
    unit = deleted_unit,
    data = { name = "Deleted", category = "supplies", color = { 255, 255, 255, 255 } },
    draw = true,
    widget = pickup_widget(10, 0, 0),
}
local buffered_parent = {
    _get_camera = function() return {} end,
    _get_screen_offset = function() return 0, 0 end,
    _convert_world_to_screen_position = function(_, _, position)
        return position.screen_x, position.screen_y
    end,
}
template.on_enter(buffered_widget, buffered_marker)
template.update_function(buffered_parent, { scale = 1, inverse_scale = 1 },
    buffered_widget, buffered_marker, nil, nil, 14)
assert(buffered_widget.visible,
    "pickups should remain drawn while their anchor is inside the shared offscreen buffer")
world_positions[buffered_unit].screen_x = -180
template.update_function(buffered_parent, { scale = 1, inverse_scale = 1 },
    buffered_widget, buffered_marker, nil, nil, 14.1)
assert(not buffered_widget.visible,
    "pickups should stop drawing after their anchor leaves the shared offscreen buffer")
for i = 1, #markers do
    for j = i + 1, #markers do
        local left, right = markers[i].widget, markers[j].widget
        local required_width = (left.style.background.size[1] + right.style.background.size[1]) * 0.5
        if left.visible and right.visible
            and math.abs(left.offset[1] - right.offset[1]) < required_width then
            local required_gap = (left.style.background.size[2] + right.style.background.size[2]) * 0.5
            assert(math.abs(left.offset[2] - right.offset[2]) >= required_gap,
                string.format("pickup collision layout should leave no visible card overlap: %s/%s at %.1f,%.1f / %.1f,%.1f",
                    left.content.name, right.content.name,
                    left.offset[1], left.offset[2], right.offset[1], right.offset[2]))
        end
    end
end
pickup_filter = "stimms"
template.update_function(nil, nil, widget, marker, nil, nil, 15)
assert(not widget.visible, "pickup filter changes should hide existing non-matching markers live")
pickup_filter = "all"
template.update_function(nil, nil, widget, marker, nil, nil, 15.1)
assert(widget.visible, "pickup filter changes should restore matching existing markers live")
enabled = false
template.update_function(nil, nil, widget, marker)
assert(not widget.visible, "pickup labels should respect their independent setting")
ALIVE[unit] = false
template.update_function(nil, nil, widget, marker)
assert(marker.remove, "despawned pickups should remove their marker")
print("BallHammer pickup marker smoke: ok")
