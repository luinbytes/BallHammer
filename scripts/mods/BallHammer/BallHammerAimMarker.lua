local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")
local template = {}

template.name = "ballhammer_aim_marker"
template.size = { 1, 1 }
template.max_distance = 200
template.screen_clamp = false

local function circle(size, color, layer)
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        size = { size, size },
        offset = { 0, 0, layer },
        color = color,
    }
end

template.create_widget_defintion = function(_, scenegraph_id)
    return UIWidget.create_definition({
        { pass_type = "circle", style_id = "glow", style = circle(68, { 30, 255, 158, 181 }, 1) },
        { pass_type = "circle", style_id = "ring", style = circle(58, { 150, 255, 158, 181 }, 2) },
        { pass_type = "circle", style_id = "fill", style = circle(52, { 65, 8, 10, 12 }, 3) },
        { pass_type = "circle", style_id = "point", style = circle(4, { 235, 255, 255, 255 }, 4) },
    }, scenegraph_id)
end

template.on_enter = function(_, marker)
    mod.aim_marker_ref = marker
end

template.on_exit = function(_, marker)
    if mod.aim_marker_ref == marker then mod.aim_marker_ref = nil end
end

template.update_function = function(_, ui_renderer, widget, marker)
    local target, _, radius = mod.get_aim_preview()
    local enabled, opacity, red, green, blue = mod.get_aim_marker_style()
    widget.visible = enabled and marker.draw and target ~= nil and radius ~= nil
    if not widget.visible or not widget.style then return end
    local renderer_scale = ui_renderer and ui_renderer.scale or 1
    local diameter = math.max(radius * 2 / renderer_scale, 8)
    local glow = widget.style.glow
    local ring = widget.style.ring
    local fill = widget.style.fill
    local point = widget.style.point
    glow.size[1], glow.size[2] = diameter + 10, diameter + 10
    ring.size[1], ring.size[2] = diameter, diameter
    local fill_size = math.max(diameter - 6, 4)
    fill.size[1], fill.size[2] = fill_size, fill_size
    point.size[1], point.size[2] = 4, 4
    local alpha = math.floor(255 * opacity / 100 + 0.5)
    local ring_color = ring.color
    local glow_color = glow.color
    ring_color[1], ring_color[2], ring_color[3], ring_color[4] = alpha, red, green, blue
    glow_color[1], glow_color[2], glow_color[3], glow_color[4] = math.floor(alpha * 0.2), red, green, blue
    widget.style.fill.color[1] = math.floor(alpha * 0.25)
    widget.style.point.color[1] = alpha
end

return template
