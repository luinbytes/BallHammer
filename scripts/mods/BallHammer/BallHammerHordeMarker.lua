local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")
local Horde = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerHorde")
local Bounds = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerBounds")

local template = {}
local cached_time = nil
local cached_boxes = {}
local OFFSCREEN_BUFFER = 48

template.name = "ballhammer_horde_marker"
template.unit_node = "root_point"
template.size = { 1, 1 }
template.check_line_of_sight = false
template.max_distance = 999
template.screen_clamp = false

local function box_visible(content)
    return content.draw_box
end

local function line_style(color)
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        offset = { 0, 0, 1 },
        size = { 1, 1 },
        color = color,
    }
end

template.create_widget_defintion = function(_, scenegraph_id)
    local color = { 255, 255, 158, 181 }

    return UIWidget.create_definition({
        { pass_type = "rect", style_id = "top", style = line_style(table.clone(color)), visibility_function = box_visible },
        { pass_type = "rect", style_id = "bottom", style = line_style(table.clone(color)), visibility_function = box_visible },
        { pass_type = "rect", style_id = "left", style = line_style(table.clone(color)), visibility_function = box_visible },
        { pass_type = "rect", style_id = "right", style = line_style(table.clone(color)), visibility_function = box_visible },
        {
            pass_type = "rect",
            style_id = "dot",
            style = {
                horizontal_alignment = "center",
                vertical_alignment = "center",
                offset = { 0, 0, 2 },
                size = { 3, 3 },
                color = table.clone(color),
            },
            visibility_function = function(content) return content.draw_dot end,
        },
        {
            pass_type = "text",
            style_id = "label",
            value_id = "label",
            value = "",
            style = {
                horizontal_alignment = "center",
                vertical_alignment = "center",
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
                font_type = "mono_tide_regular",
                font_size = 11,
                text_color = table.clone(color),
                offset = { -80, -20, 2 },
                size = { 160, 20 },
            },
        },
    }, scenegraph_id)
end

local function project_box(parent, ui_renderer, marker)
    local data = marker.data or mod.horde_unit_data[marker.unit]
    local widget = marker.widget
    local distance = widget.content.distance
    if not data then return nil end
    local body = Unit.world_position(marker.unit, 1)
    if not body then return nil end

    local box = {
        id = marker.id,
        marker = marker,
        unit = marker.unit,
        name = data.name or "Enemy",
        clusterable = data.clusterable == true,
        force_horde_merge = data.force_horde_merge == true,
        world = { x = body.x, y = body.y, z = body.z },
    }
    if not distance or distance > mod.get_horde_distance() then return box end

    local camera = parent:_get_camera()
    if not camera then return box end
    local inverse_scale = ui_renderer.inverse_scale
    local aim_node = mod.get_aim_location() == "torso" and "j_spine" or "j_head"
    local bounds = Bounds.project(parent, ui_renderer, camera, marker.unit, body, data.base_height, aim_node)
    if not bounds then return box end
    local screen_width = RESOLUTION_LOOKUP.width * inverse_scale
    local screen_height = RESOLUTION_LOOKUP.height * inverse_scale

    box.in_buffer = Bounds.in_screen_buffer(bounds, screen_width, screen_height, OFFSCREEN_BUFFER)
    box.projected = box.in_buffer
    box.anchor_x = widget.offset[1]
    box.anchor_y = widget.offset[2]
    box.left, box.right, box.top, box.bottom = bounds.left, bounds.right, bounds.top, bounds.bottom
    box.dot_x, box.dot_y = bounds.aim_x, bounds.aim_y
    return box
end

local function rebuild_cache(parent, ui_renderer, t)
    if cached_time == t then return end
    cached_time = t
    table.clear(cached_boxes)

    local boxes = {}
    for unit, marker in pairs(mod.horde_marker_refs) do
        if HEALTH_ALIVE[unit] then
            local box = project_box(parent, ui_renderer, marker)
            if box then
                if box.clusterable then
                    boxes[#boxes + 1] = box
                elseif box.projected then
                    cached_boxes[unit] = {
                        draw_box = true,
                        draw_dot = false,
                        count = 1,
                        label = box.name,
                        anchor_x = box.anchor_x,
                        anchor_y = box.anchor_y,
                        left = box.left,
                        right = box.right,
                        top = box.top,
                        bottom = box.bottom,
                    }
                end
            end
        end
    end

    local clusters = Horde.build_clusters(boxes)
    for i = 1, #clusters do
        local cluster = clusters[i]
        local projected = {}
        for j = 1, #cluster.members do
            if cluster.members[j].projected then projected[#projected + 1] = cluster.members[j] end
        end
        if cluster.count >= 3 then
            for j = 1, #projected do
                cached_boxes[projected[j].unit] = {
                    draw_box = false,
                    draw_dot = true,
                    count = cluster.count,
                    dot_x = projected[j].dot_x,
                    dot_y = projected[j].dot_y,
                    anchor_x = projected[j].anchor_x,
                    anchor_y = projected[j].anchor_y,
                }
            end
            local leader = projected[1]
            if leader then cached_boxes[leader.unit] = {
                draw_box = true,
                draw_dot = true,
                count = cluster.count,
                anchor_x = leader.anchor_x,
                anchor_y = leader.anchor_y,
                left = cluster.left - 4,
                right = cluster.right + 4,
                top = cluster.top - 4,
                bottom = cluster.bottom + 4,
                dot_x = leader.dot_x,
                dot_y = leader.dot_y,
            } end
        else
            for j = 1, #projected do
                local member = projected[j]
                cached_boxes[member.unit] = {
                    draw_box = true,
                    draw_dot = false,
                    count = 1,
                    label = member.name,
                    anchor_x = member.anchor_x,
                    anchor_y = member.anchor_y,
                    left = member.left,
                    right = member.right,
                    top = member.top,
                    bottom = member.bottom,
                }
            end
        end
    end
end

local function set_line(style, x, y, width, height)
    style.offset[1] = x
    style.offset[2] = y
    style.size[1] = width
    style.size[2] = height
end

local function apply_distance_alpha(widget, data, distance)
    local max_distance = mod.get_horde_distance()
    local fade_start = max_distance * 0.6
    local fade = distance <= fade_start and 1 or math.max(0, (max_distance - distance) / (max_distance - fade_start))
    local alpha = math.floor(data.color[1] * fade + 0.5)
    for _, style_id in ipairs({ "top", "bottom", "left", "right" }) do
        widget.style[style_id].color[1] = alpha
    end
    widget.style.dot.color[1] = alpha
    widget.style.label.text_color[1] = alpha
end

template.on_enter = function(widget, marker)
    mod.horde_marker_refs[marker.unit] = marker
    local data = marker.data or mod.horde_unit_data[marker.unit]
    if data and data.color then
        for _, style_id in ipairs({ "top", "bottom", "left", "right" }) do
            widget.style[style_id].color = table.clone(data.color)
        end
        widget.style.dot.color = table.clone(data.color)
        widget.style.label.text_color = table.clone(data.color)
    end
end

template.on_exit = function(_, marker)
    mod.horde_marker_refs[marker.unit] = nil
    mod.horde_active_markers[marker.unit] = nil
end

template.update_function = function(parent, ui_renderer, widget, marker, _, _, t)
    if not HEALTH_ALIVE[marker.unit] then
        marker.remove = true
        return
    end
    if not mod.enabled or not mod.get_enable_horde_esp() then
        widget.visible = false
        return
    end

    rebuild_cache(parent, ui_renderer, t)
    local box = cached_boxes[marker.unit]
    if not box then
        widget.visible = false
        return
    end
    local data = marker.data or mod.horde_unit_data[marker.unit]
    if data then apply_distance_alpha(widget, data, widget.content.distance) end

    widget.content.draw_box = box.draw_box
    widget.content.draw_dot = box.draw_dot
    if box.draw_dot then
        widget.style.dot.offset[1] = box.dot_x - box.anchor_x
        widget.style.dot.offset[2] = box.dot_y - box.anchor_y
    end
    if box.draw_box then
        local width = box.right - box.left
        local height = box.bottom - box.top
        local left = box.left - box.anchor_x
        local right = box.right - box.anchor_x
        local top = box.top - box.anchor_y
        local bottom = box.bottom - box.anchor_y
        local center_x = (left + right) * 0.5
        local center_y = (top + bottom) * 0.5

        set_line(widget.style.top, center_x, top, width, 1)
        set_line(widget.style.bottom, center_x, bottom, width, 1)
        set_line(widget.style.left, left, center_y, 1, height)
        set_line(widget.style.right, right, center_y, 1, height)

        widget.content.label = box.count >= 3 and "Horde x" .. box.count or box.label
        widget.style.label.offset[1] = center_x
        widget.style.label.offset[2] = top - 12
    else
        widget.content.label = ""
    end
    widget.visible = true
end

return template
