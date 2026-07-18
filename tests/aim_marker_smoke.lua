local preview = {}
local preview_radius = 42
local marker_enabled = true
local mod = {
    get_aim_preview = function() return preview, {}, preview_radius end,
    get_aim_marker_style = function() return marker_enabled, 40, 12, 34, 56 end,
}

get_mod = function() return mod end
package.preload["scripts/managers/ui/ui_widget"] = function()
    return { create_definition = function(passes) return passes end }
end

local template = dofile("scripts/mods/BallHammer/BallHammerAimMarker.lua")
local definition = template.create_widget_defintion(template, "pivot")
assert(#definition == 4, "aim preview should draw a glow, ring, fill, and center point")
for i = 1, #definition do
    assert(definition[i].pass_type == "circle", "aim preview should use native circle passes")
end

local marker = { draw = true }
local widget = { style = {} }
for i = 1, #definition do
    widget.style[definition[i].style_id] = definition[i].style
end
template.on_enter(widget, marker)
template.update_function(nil, nil, widget, marker)
assert(widget.visible and mod.aim_marker_ref == marker,
    "aim preview should render while a candidate exists")
assert(widget.style.ring.size[1] == preview_radius * 2,
    "the visible ring diameter should exactly match the acquisition radius")
assert(widget.style.ring.color[1] == 102 and widget.style.ring.color[2] == 12
    and widget.style.ring.color[3] == 34 and widget.style.ring.color[4] == 56,
    "the FOV circle should apply its configured opacity and RGB color")
marker_enabled = false
template.update_function(nil, nil, widget, marker)
assert(not widget.visible, "the FOV display master switch should hide only the marker")
marker_enabled = true
preview = nil
template.update_function(nil, nil, widget, marker)
assert(not widget.visible, "aim preview should hide when no candidate exists")
template.on_exit(widget, marker)
assert(mod.aim_marker_ref == nil, "aim preview should release stale HUD marker references")

print("BallHammer aim marker smoke: ok")
