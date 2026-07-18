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
    local sizes = {
        glow = diameter + 10,
        ring = diameter,
        fill = math.max(diameter - 6, 4),
        point = 4,
    }
    for id, size in pairs(sizes) do
        local style = widget.style[id]
        if style and style.size then
            style.size[1], style.size[2] = size, size
        end
    end
    local alpha = math.floor(255 * opacity / 100 + 0.5)
    local ring = widget.style.ring.color
    local glow = widget.style.glow.color
    ring[1], ring[2], ring[3], ring[4] = alpha, red, green, blue
    glow[1], glow[2], glow[3], glow[4] = math.floor(alpha * 0.2), red, green, blue
    widget.style.fill.color[1] = math.floor(alpha * 0.25)
    widget.style.point.color[1] = alpha
end

return template
