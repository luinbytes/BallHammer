table.clone = table.clone or function(value)
    local copy = {}
    for key, item in pairs(value) do copy[key] = item end
    return copy
end

local enabled = true
local unit = {}
local data = { name = "Plasteel", color = { 255, 70, 220, 255 } }
local mod = {
    enabled = true,
    pickup_marker_refs = {},
    pickup_active_markers = {},
    get_pickup_data = function() return data end,
    get_enable_pickup_esp = function() return enabled end,
    get_pickup_distance = function() return 100 end,
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
    and nearby_widget.offset[2] - third_widget.offset[2] >= template.size[2]
    and third_widget.offset[2] - widget.offset[2] >= template.size[2],
    "pickup stacks should be alphabetically sorted without card overlap")
local extra_names = { "Celerity Stimm", "Combat Stimm", "Grenade", "Medkit" }
for i = 1, #extra_names do
    local extra_unit = {}
    ALIVE[extra_unit] = true
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
for i = 1, #markers do
    if markers[i].widget.visible then visible_count = visible_count + 1 end
    if markers[i].widget.content.name:find("+2", 1, true) then overflow_label = true end
end
assert(visible_count == 5 and overflow_label,
    "large pickup stacks should cap at five rows and show the folded pickup count")
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
enabled = false
template.update_function(nil, nil, widget, marker)
assert(not widget.visible, "pickup labels should respect their independent setting")
ALIVE[unit] = false
template.update_function(nil, nil, widget, marker)
assert(marker.remove, "despawned pickups should remove their marker")
print("BallHammer pickup marker smoke: ok")
