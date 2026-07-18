local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")
local Horde = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerHorde")
local Bounds = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerBounds")

local template = {}
local cached_time = nil
local cached_boxes = {}
local transition_states = {}
local TRANSITION_DURATION = 0.28
local TRANSITION_SPEED = 14

template.name = "ballhammer_horde_marker"
template.unit_node = "j_head"
template.size = { 1, 1 }
template.check_line_of_sight = true
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
    local world_x, world_y, world_z = Vector3.to_elements(body)

    local box = {
        id = marker.id,
        marker = marker,
        unit = marker.unit,
        name = data.name or "Enemy",
        clusterable = data.clusterable == true,
        force_horde_merge = data.force_horde_merge == true,
        world = { x = world_x, y = world_y, z = world_z },
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

    box.in_buffer = Bounds.in_screen_buffer(bounds, screen_width, screen_height, Bounds.OFFSCREEN_BUFFER)
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
                        member_left = box.left,
                        member_right = box.right,
                        member_top = box.top,
                        member_bottom = box.bottom,
                        dot_x = box.dot_x,
                        dot_y = box.dot_y,
                        grouped = false,
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
                    label = projected[j].name,
                    dot_x = projected[j].dot_x,
                    dot_y = projected[j].dot_y,
                    member_left = projected[j].left,
                    member_right = projected[j].right,
                    member_top = projected[j].top,
                    member_bottom = projected[j].bottom,
                    anchor_x = projected[j].anchor_x,
                    anchor_y = projected[j].anchor_y,
                    grouped = true,
                    leader = false,
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
                member_left = leader.left,
                member_right = leader.right,
                member_top = leader.top,
                member_bottom = leader.bottom,
                grouped = true,
                leader = true,
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
                    member_left = member.left,
                    member_right = member.right,
                    member_top = member.top,
                    member_bottom = member.bottom,
                    dot_x = member.dot_x,
                    dot_y = member.dot_y,
                    grouped = false,
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

local function animate_membership(unit, box, t)
    local target = box.grouped and 1 or 0
    local state = transition_states[unit]
    if not state then
        state = { progress = box.grouped and 0 or target, last_t = t }
        transition_states[unit] = state
    end

    local dt = math.max(0, (t or state.last_t or 0) - (state.last_t or t or 0))
    state.last_t = t or state.last_t
    local step = dt / TRANSITION_DURATION
    if state.progress < target then
        state.progress = math.min(target, state.progress + step)
    elseif state.progress > target then
        state.progress = math.max(target, state.progress - step)
    end

    if box.grouped and box.leader then
        local target_left = box.left - box.member_left
        local target_right = box.right - box.member_right
        local target_top = box.top - box.member_top
        local target_bottom = box.bottom - box.member_bottom
        if state.left_offset == nil then
            state.left_offset, state.right_offset = target_left, target_right
            state.top_offset, state.bottom_offset = target_top, target_bottom
        else
            local alpha = 1 - math.exp(-TRANSITION_SPEED * dt)
            state.left_offset = state.left_offset + (target_left - state.left_offset) * alpha
            state.right_offset = state.right_offset + (target_right - state.right_offset) * alpha
            state.top_offset = state.top_offset + (target_top - state.top_offset) * alpha
            state.bottom_offset = state.bottom_offset + (target_bottom - state.bottom_offset) * alpha
        end
        state.leader = true
    elseif box.grouped then
        state.leader = false
    end

    local progress = state.progress
    local eased = progress * progress * (3 - 2 * progress)
    local leader = box.leader or not box.grouped and state.leader
    local target_left, target_right, target_top, target_bottom
    if leader and state.left_offset then
        target_left = box.member_left + state.left_offset
        target_right = box.member_right + state.right_offset
        target_top = box.member_top + state.top_offset
        target_bottom = box.member_bottom + state.bottom_offset
    else
        target_left, target_right = box.dot_x, box.dot_x
        target_top, target_bottom = box.dot_y, box.dot_y
    end

    local motion = {
        left = box.member_left + (target_left - box.member_left) * eased,
        right = box.member_right + (target_right - box.member_right) * eased,
        top = box.member_top + (target_top - box.member_top) * eased,
        bottom = box.member_bottom + (target_bottom - box.member_bottom) * eased,
        box_alpha = leader and 1 or 1 - eased,
        dot_alpha = eased,
    }
    if progress == 0 then state.leader = false end
    return motion
end

local function apply_distance_alpha(widget, data, distance, visible)
    local max_distance = mod.get_horde_distance()
    local fade_start = max_distance * 0.6
    local fade = distance <= fade_start and 1 or math.max(0, (max_distance - distance) / (max_distance - fade_start))
    local alpha = math.floor(data.color[1] * fade + 0.5)
    local red, green, blue = visible and 255 or data.color[2],
        visible and 255 or data.color[3], visible and 255 or data.color[4]
    for _, style_id in ipairs({ "top", "bottom", "left", "right" }) do
        local color = widget.style[style_id].color
        color[1], color[2], color[3], color[4] = alpha, red, green, blue
    end
    local dot_color = widget.style.dot.color
    local label_color = widget.style.label.text_color
    dot_color[1], dot_color[2], dot_color[3], dot_color[4] = alpha, red, green, blue
    label_color[1], label_color[2], label_color[3], label_color[4] = alpha, red, green, blue
end

local function apply_motion_alpha(widget, motion)
    for _, style_id in ipairs({ "top", "bottom", "left", "right" }) do
        local color = widget.style[style_id].color
        color[1] = math.floor(color[1] * motion.box_alpha + 0.5)
    end
    widget.style.label.text_color[1] = math.floor(
        widget.style.label.text_color[1] * motion.box_alpha + 0.5
    )
    widget.style.dot.color[1] = math.floor(widget.style.dot.color[1] * motion.dot_alpha + 0.5)
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
    transition_states[marker.unit] = nil
end

template.update_function = function(parent, ui_renderer, widget, marker, _, _, t)
    if not HEALTH_ALIVE[marker.unit] then
        marker.remove = true
        return
    end
    if not mod.enabled or mod.esp_enabled == false or not mod.get_enable_horde_esp() then
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
    if data then
        apply_distance_alpha(widget, data, widget.content.distance,
            marker.raycast_initialized and marker.raycast_result == false)
    end

    local motion = animate_membership(marker.unit, box, t)
    apply_motion_alpha(widget, motion)
    widget.content.draw_box = motion.box_alpha > 0.001
    widget.content.draw_dot = motion.dot_alpha > 0.001
    if widget.content.draw_dot then
        widget.style.dot.offset[1] = box.dot_x - box.anchor_x
        widget.style.dot.offset[2] = box.dot_y - box.anchor_y
    end
    if widget.content.draw_box then
        local width = motion.right - motion.left
        local height = motion.bottom - motion.top
        local left = motion.left - box.anchor_x
        local right = motion.right - box.anchor_x
        local top = motion.top - box.anchor_y
        local bottom = motion.bottom - box.anchor_y
        local center_x = (left + right) * 0.5
        local center_y = (top + bottom) * 0.5

        set_line(widget.style.top, center_x, top, width, 1)
        set_line(widget.style.bottom, center_x, bottom, width, 1)
        set_line(widget.style.left, left, center_y, 1, height)
        set_line(widget.style.right, right, center_y, 1, height)

        widget.content.label = box.grouped and box.leader and "Horde x" .. box.count or box.label
        widget.style.label.offset[1] = center_x
        widget.style.label.offset[2] = top - 12
    else
        widget.content.label = ""
    end
    widget.visible = true
end

return template
