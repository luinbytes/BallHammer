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
local widget = { content = { distance = 80 }, style = styles }
local marker = { unit = unit, data = data, draw = true }
template.on_enter(widget, marker)
assert(widget.content.label == "Plasteel" and mod.pickup_marker_refs[unit] == marker,
    "pickup marker should register and display its classified name")
local replacement = { unit = unit, data = data, draw = true }
mod.pickup_active_markers[unit] = true
template.on_enter(widget, replacement)
template.on_exit(nil, marker)
assert(mod.pickup_marker_refs[unit] == replacement and mod.pickup_active_markers[unit],
    "an old marker exit must not clear a newer replacement")
marker = replacement
template.update_function(nil, nil, widget, marker)
assert(widget.visible and widget.content.label == "Plasteel 80m"
    and widget.style.label.text_color[1] < 255,
    "pickup labels should include distance and fade near their range limit")
enabled = false
template.update_function(nil, nil, widget, marker)
assert(not widget.visible, "pickup labels should respect their independent setting")
ALIVE[unit] = false
template.update_function(nil, nil, widget, marker)
assert(marker.remove, "despawned pickups should remove their marker")
print("BallHammer pickup marker smoke: ok")
