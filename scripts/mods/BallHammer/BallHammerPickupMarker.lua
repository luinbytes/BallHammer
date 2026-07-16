local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")
local template = {}

template.name = "ballhammer_pickup_marker"
template.unit_node = 1
template.size = { 220, 28 }
template.check_line_of_sight = false
template.max_distance = 999
template.screen_clamp = false

local function text_style(color, offset)
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        text_horizontal_alignment = "center",
        text_vertical_alignment = "center",
        font_type = "mono_tide_regular",
        font_size = 14,
        text_color = table.clone(color),
        offset = offset,
        size = { 220, 28 },
    }
end

template.create_widget_defintion = function(_, scenegraph_id)
    return UIWidget.create_definition({
        {
            pass_type = "text",
            style_id = "label_shadow",
            value_id = "label",
            value = "",
            style = text_style({ 180, 0, 0, 0 }, { 1, -1, 1 }),
        },
        {
            pass_type = "text",
            style_id = "label",
            value_id = "label",
            value = "",
            style = text_style({ 255, 255, 255, 255 }, { 0, 0, 2 }),
        },
    }, scenegraph_id)
end

template.on_enter = function(widget, marker)
    local data = marker.data or mod.get_pickup_data(marker.unit)
    if data then
        widget.content.label = data.name
        widget.style.label.text_color = table.clone(data.color)
    end
    mod.pickup_marker_refs[marker.unit] = marker
end

template.on_exit = function(_, marker)
    if mod.pickup_marker_refs[marker.unit] == marker then
        mod.pickup_marker_refs[marker.unit] = nil
        mod.pickup_active_markers[marker.unit] = nil
    end
end

template.update_function = function(_, _, widget, marker)
    if not ALIVE[marker.unit] then
        marker.remove = true
        return
    end
    local distance = widget.content.distance
    if not mod.enabled or not mod.get_enable_pickup_esp() or not marker.draw or not distance
        or distance > mod.get_pickup_distance() then
        widget.visible = false
        return
    end

    local data = marker.data or mod.get_pickup_data(marker.unit)
    if not data then
        marker.remove = true
        return
    end
    local max_distance = mod.get_pickup_distance()
    local fade_start = max_distance * 0.6
    local fade = distance <= fade_start and 1
        or math.max(0, (max_distance - distance) / (max_distance - fade_start))
    local alpha = math.floor(data.color[1] * fade + 0.5)
    local color = widget.style.label.text_color
    color[1], color[2], color[3], color[4] = alpha, data.color[2], data.color[3], data.color[4]
    widget.style.label_shadow.text_color[1] = math.floor(alpha * 180 / 255 + 0.5)
    local floor_distance = math.floor(distance)
    if floor_distance ~= marker.last_dist then
        marker.last_dist = floor_distance
        widget.content.label = data.name .. " " .. floor_distance .. "m"
    end
    widget.visible = true
end

return template
