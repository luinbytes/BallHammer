local UIWidget = require("scripts/managers/ui/ui_widget")
local template = {}
local mod = get_mod("BallHammer")
local Bounds = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerBounds")

local ACCENT = { 255, 255, 158, 181 }
local TEXT = { 255, 224, 224, 229 }

template.name = "ballhammer_marker"
template.unit_node = "root_point"
template.size = { 1, 1 }
template.check_line_of_sight = false
template.max_distance = 999
template.screen_clamp = false

local function line_style()
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        offset = { 0, 0, 1 },
        size = { 1, 1 },
        color = table.clone(ACCENT),
    }
end

local function text_style(font_size, alignment, width, color)
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        text_horizontal_alignment = alignment,
        text_vertical_alignment = "center",
        font_type = "mono_tide_regular",
        font_size = font_size,
        text_color = table.clone(color),
        offset = { 0, 0, 2 },
        size = { width, 20 },
    }
end

template.create_widget_defintion = function(_, scenegraph_id)
    return UIWidget.create_definition({
        { pass_type = "rect", style_id = "top", style = line_style() },
        { pass_type = "rect", style_id = "bottom", style = line_style() },
        { pass_type = "rect", style_id = "left", style = line_style() },
        { pass_type = "rect", style_id = "right", style = line_style() },
        {
            pass_type = "text",
            style_id = "name_shadow",
            value_id = "name",
            value = "",
            style = text_style(13, "center", 180, { 180, 0, 0, 0 }),
        },
        {
            pass_type = "text",
            style_id = "name",
            value_id = "name",
            value = "",
            style = text_style(13, "center", 180, TEXT),
        },
        {
            pass_type = "text",
            style_id = "flag_shadow",
            value_id = "flag",
            value = "",
            style = text_style(11, "left", 80, { 180, 0, 0, 0 }),
        },
        {
            pass_type = "text",
            style_id = "flag",
            value_id = "flag",
            value = "",
            style = text_style(11, "left", 80, TEXT),
        },
    }, scenegraph_id)
end

local function set_line(style, x, y, width, height)
    style.offset[1] = x
    style.offset[2] = y
    style.size[1] = width
    style.size[2] = height
end

local function name_for(data, distance)
    return data.name .. (distance and " " .. distance .. "m" or "")
end

local function apply_distance_alpha(widget, data, distance)
    local max_distance = mod.get_max_distance()
    local fade_start = max_distance * 0.6
    local fade = distance <= fade_start and 1 or math.max(0, (max_distance - distance) / (max_distance - fade_start))
    local alpha = math.floor(data.color[1] * fade + 0.5)
    for _, style_id in ipairs({ "top", "bottom", "left", "right" }) do
        widget.style[style_id].color[1] = alpha
    end
    widget.style.name.text_color[1] = alpha
    widget.style.flag.text_color[1] = alpha
    local shadow_alpha = math.floor(alpha * 180 / 255 + 0.5)
    widget.style.name_shadow.text_color[1] = shadow_alpha
    widget.style.flag_shadow.text_color[1] = shadow_alpha
end

local function update_box(parent, ui_renderer, widget, marker, body)
    if not marker.base_height then
        local unit_data = ScriptUnit.has_extension(marker.unit, "unit_data_system")
        local breed = unit_data and unit_data:breed()
        marker.base_height = breed and breed.base_height or 1.8
    end

    local camera = parent:_get_camera()
    if not camera then return false end
    local bounds = Bounds.project(parent, ui_renderer, camera, marker.unit, body, marker.base_height)
    if not bounds then return false end
    local body_x = widget.offset[1]
    local body_y = widget.offset[2]
    local top = bounds.top - body_y
    local bottom = bounds.bottom - body_y
    local left = bounds.left - body_x
    local right = bounds.right - body_x

    local center_x = (left + right) * 0.5
    set_line(widget.style.top, center_x, top, right - left, 1)
    set_line(widget.style.bottom, center_x, bottom, right - left, 1)
    set_line(widget.style.left, left, (top + bottom) * 0.5, 1, bottom - top)
    set_line(widget.style.right, right, (top + bottom) * 0.5, 1, bottom - top)
    local name_x, name_y = center_x, top - 16
    local flag_x = right + 4 + widget.style.flag.size[1] * 0.5
    local flag_y = top + widget.style.flag.size[2] * 0.5
    widget.style.name.offset[1], widget.style.name.offset[2] = name_x, name_y
    widget.style.flag.offset[1], widget.style.flag.offset[2] = flag_x, flag_y
    widget.style.name_shadow.offset[1], widget.style.name_shadow.offset[2] = name_x + 1, name_y + 1
    widget.style.flag_shadow.offset[1], widget.style.flag_shadow.offset[2] = flag_x + 1, flag_y + 1
    return true
end

template.on_enter = function(widget, marker)
    local data = marker.data or mod.get_unit_data(marker.unit)
    if data then
        widget.content.name = name_for(data)
        widget.content.flag = data.flag or ""
        for _, style_id in ipairs({ "top", "bottom", "left", "right" }) do
            widget.style[style_id].color = table.clone(data.color)
        end
        widget.style.name.text_color = table.clone(data.color)
        widget.style.flag.text_color = table.clone(data.color)
    end
    mod.marker_refs[marker.unit] = marker
end

template.on_exit = function(_, marker)
    mod.marker_refs[marker.unit] = nil
    mod.active_markers[marker.unit] = nil
end

template.update_function = function(parent, ui_renderer, widget, marker)
    if not HEALTH_ALIVE[marker.unit] then
        marker.remove = true
        return
    end
    if not mod.enabled or not mod.get_enable_nameplates() then
        widget.visible = false
        return
    end

    local distance = widget.content.distance
    local body = Unit.world_position(marker.unit, 1)
    if not marker.draw or not distance or distance > mod.get_max_distance() or not body then
        widget.visible = false
        return
    end
    if not update_box(parent, ui_renderer, widget, marker, body) then
        widget.visible = false
        return
    end
    local data = marker.data or mod.get_unit_data(marker.unit)
    if data then apply_distance_alpha(widget, data, distance) end

    local floor_distance = math.floor(distance)
    if floor_distance ~= marker.last_dist then
        marker.last_dist = floor_distance
        if data then widget.content.name = name_for(data, floor_distance) end
    end
    widget.visible = true
end

return template
