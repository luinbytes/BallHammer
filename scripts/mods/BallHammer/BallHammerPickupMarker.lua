local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")
local Bounds = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerBounds")
local template = {}

template.name = "ballhammer_pickup_marker"
template.unit_node = 1
template.size = { 220, 30 }
template.check_line_of_sight = false
template.max_distance = 999
template.screen_clamp = false
local STACK_GAP = 3
local STACK_SPEED = 14
local COMPACT_CARD_WIDTH = 156
local DETACH_GAP = 6
local transition_states = {}

local function rect_style(color, offset, size)
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        color = table.clone(color),
        offset = offset,
        size = size,
    }
end

local function text_style(font_size, alignment, color, offset, size)
    return {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        text_horizontal_alignment = alignment,
        text_vertical_alignment = "center",
        font_type = "mono_tide_regular",
        font_size = font_size,
        text_color = table.clone(color),
        offset = offset,
        size = size,
    }
end

local function apply_stack_density(marker, compact)
    local style = marker.widget.style
    local width = compact and COMPACT_CARD_WIDTH or 216
    marker.stack_dense = compact
    style.shadow.size[1] = compact and width + 4 or width
    style.shadow.size[2] = compact and 28 or 28
    style.shadow.offset[2] = compact and -1 or -2
    style.background.size[1] = width
    style.background.size[2] = compact and 24 or 28
    style.glow.size[1] = width
    style.glow.offset[2] = compact and 11 or 13
    style.accent.offset[1] = -width * 0.5 + 2
    style.accent.size[2] = compact and 22 or 24
    local text_height = compact and 22 or 20
    local name_width = compact and width - 40 or 164
    style.name.font_size = compact and 10 or 11
    style.name.size[1] = name_width
    style.name.size[2] = text_height
    style.name.offset[1] = compact and -14 or -18
    style.name_shadow.font_size = compact and 10 or 11
    style.name_shadow.size[1] = name_width
    style.name_shadow.size[2] = text_height
    style.name_shadow.offset[1] = compact and -13 or -17
    style.distance.font_size = compact and 10 or 11
    style.distance.size[1] = compact and 26 or 34
    style.distance.size[2] = text_height
    style.distance.offset[1] = compact and width * 0.5 - 17 or 88
end

template.create_widget_defintion = function(_, scenegraph_id)
    return UIWidget.create_definition({
        {
            pass_type = "rect",
            style_id = "shadow",
            style = rect_style({ 120, 0, 0, 0 }, { 2, -2, 0 }, { 216, 28 }),
        },
        {
            pass_type = "rect",
            style_id = "background",
            style = rect_style({ 205, 8, 12, 16 }, { 0, 0, 1 }, { 216, 28 }),
        },
        {
            pass_type = "rect",
            style_id = "glow",
            style = rect_style({ 70, 255, 255, 255 }, { 0, 13, 2 }, { 216, 1 }),
        },
        {
            pass_type = "rect",
            style_id = "accent",
            style = rect_style({ 255, 255, 255, 255 }, { -106, 0, 3 }, { 3, 24 }),
        },
        {
            pass_type = "text",
            style_id = "name_shadow",
            value_id = "name",
            value = "",
            style = text_style(11, "left", { 180, 0, 0, 0 }, { -17, -1, 3 }, { 164, 20 }),
        },
        {
            pass_type = "text",
            style_id = "name",
            value_id = "name",
            value = "",
            style = text_style(11, "left", { 255, 255, 255, 255 }, { -18, 0, 4 }, { 164, 20 }),
        },
        {
            pass_type = "text",
            style_id = "distance",
            value_id = "distance_text",
            value = "",
            style = text_style(11, "right", { 255, 218, 222, 228 }, { 88, 0, 4 }, { 34, 20 }),
        },
    }, scenegraph_id)
end

local last_layout_t

local function marker_projection(parent, ui_renderer, marker, widget)
    widget = widget or marker.widget
    if not widget then return false end
    if parent and ui_renderer and parent._get_camera then
        local camera = parent:_get_camera()
        local position = Unit.world_position(marker.unit, template.unit_node)
        if camera and position then
            return Bounds.point_in_screen_buffer(parent, ui_renderer, camera, position)
        end
    end
    local offset = widget.offset or { 0, 0 }
    return marker.draw, offset[1], offset[2]
end

local function layout_markers(parent, ui_renderer, t)
    if t ~= nil and last_layout_t == t then return end
    last_layout_t = t
    local markers = {}
    local max_distance = mod.get_pickup_distance()
    for unit, marker in pairs(mod.pickup_marker_refs) do
        if ALIVE[unit] then
            local widget = marker.widget
            local distance = widget and widget.content.distance
            local data = marker.data or mod.get_pickup_data(unit)
            local in_buffer, x, y = marker_projection(parent, ui_renderer, marker)
            if in_buffer and distance and distance <= max_distance
                and data and mod.get_pickup_visible(data) then
                widget.content.name = data.name
                markers[#markers + 1] = {
                    marker = marker,
                    x = x,
                    y = y,
                    distance = distance,
                    name = data.name,
                }
            end
        end
    end
    table.sort(markers, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return tostring(a.marker.unit) < tostring(b.marker.unit)
    end)

    -- ponytail: pickup counts are tiny; connected screen components and lane scans stay simpler than an index.
    local assigned = {}
    for i = 1, #markers do
        if not assigned[i] then
            local cluster, queue = { markers[i] }, { i }
            assigned[i] = true
            local queue_index = 1
            while queue_index <= #queue do
                local source = markers[queue[queue_index]]
                queue_index = queue_index + 1
                for j = 1, #markers do
                    local candidate = markers[j]
                    if not assigned[j]
                        and math.abs(source.x - candidate.x) < COMPACT_CARD_WIDTH + DETACH_GAP
                        and math.abs(source.y - candidate.y) < 24 + DETACH_GAP then
                        assigned[j] = true
                        cluster[#cluster + 1] = candidate
                        queue[#queue + 1] = j
                    end
                end
            end

            table.sort(cluster, function(a, b)
                if a.name ~= b.name then return a.name < b.name end
                if a.distance ~= b.distance then return a.distance < b.distance end
                return tostring(a.marker.unit) < tostring(b.marker.unit)
            end)
            local anchor_x, anchor_y = 0, 0
            for j = 1, #cluster do
                anchor_x = anchor_x + cluster[j].x
                anchor_y = anchor_y + cluster[j].y
            end
            anchor_x, anchor_y = anchor_x / #cluster, anchor_y / #cluster
            local compact = true
            local row_step = compact and 24 + STACK_GAP or template.size[2] + STACK_GAP
            local first_y = anchor_y + (#cluster - 1) * row_step * 0.5
            for j = 1, #cluster do
                local item = cluster[j]
                apply_stack_density(item.marker, compact)
                local target_x = #cluster > 1 and anchor_x or item.x
                local target_y = #cluster > 1
                    and first_y - (j - 1) * row_step or item.y
                local state = transition_states[item.marker.unit]
                if not state then
                    state = { x = 0, y = 0, last_t = t }
                    transition_states[item.marker.unit] = state
                end
                local dt = math.max(0, (t or state.last_t or 0) - (state.last_t or t or 0))
                state.last_t = t or state.last_t
                local alpha = 1 - math.exp(-STACK_SPEED * dt)
                state.x = state.x + (target_x - item.x - state.x) * alpha
                state.y = state.y + (target_y - item.y - state.y) * alpha
                item.marker.widget.offset[1] = item.x + state.x
                item.marker.widget.offset[2] = item.y + state.y
            end
        end
    end
end

template.on_enter = function(widget, marker)
    local data = marker.data or mod.get_pickup_data(marker.unit)
    if data then
        widget.content.name = data.name
        widget.style.name.text_color = table.clone(data.color)
        widget.style.accent.color = table.clone(data.color)
        widget.style.glow.color = table.clone(data.color)
    end
    mod.pickup_marker_refs[marker.unit] = marker
end

template.on_exit = function(_, marker)
    if mod.pickup_marker_refs[marker.unit] == marker then
        mod.pickup_marker_refs[marker.unit] = nil
        mod.pickup_active_markers[marker.unit] = nil
    end
    transition_states[marker.unit] = nil
end

template.update_function = function(parent, ui_renderer, widget, marker, _, _, t)
    if not ALIVE[marker.unit] then
        marker.remove = true
        return
    end
    local distance = widget.content.distance
    local in_buffer = marker_projection(parent, ui_renderer, marker, widget)
    if not mod.enabled or not mod.get_enable_pickup_esp() or not in_buffer or not distance
        or distance > mod.get_pickup_distance() then
        widget.visible = false
        return
    end

    local data = marker.data or mod.get_pickup_data(marker.unit)
    if not data then
        marker.remove = true
        return
    end
    if not mod.get_pickup_visible(data) then
        widget.visible = false
        return
    end
    layout_markers(parent, ui_renderer, t)
    local max_distance = mod.get_pickup_distance()
    local fade_start = max_distance * 0.6
    local fade = distance <= fade_start and 1
        or math.max(0, (max_distance - distance) / (max_distance - fade_start))
    local alpha = math.floor(data.color[1] * fade + 0.5)
    local name_color = widget.style.name.text_color
    name_color[1], name_color[2], name_color[3], name_color[4] =
        alpha, data.color[2], data.color[3], data.color[4]
    local accent_color = widget.style.accent.color
    accent_color[1], accent_color[2], accent_color[3], accent_color[4] =
        alpha, data.color[2], data.color[3], data.color[4]
    local glow_color = widget.style.glow.color
    glow_color[1], glow_color[2], glow_color[3], glow_color[4] =
        math.floor((marker.stack_dense and 45 or 70) * fade + 0.5),
        data.color[2], data.color[3], data.color[4]
    widget.style.name_shadow.text_color[1] = math.floor((marker.stack_dense and 140 or 180) * fade + 0.5)
    widget.style.distance.text_color[1] = math.floor(255 * fade + 0.5)
    widget.style.background.color[1] = math.floor((marker.stack_dense and 125 or 205) * fade + 0.5)
    widget.style.shadow.color[1] = math.floor((marker.stack_dense and 55 or 120) * fade + 0.5)
    local floor_distance = math.floor(distance)
    if floor_distance ~= marker.last_dist then
        marker.last_dist = floor_distance
        widget.content.distance_text = floor_distance .. "m"
    end
    widget.visible = true
end

return template
