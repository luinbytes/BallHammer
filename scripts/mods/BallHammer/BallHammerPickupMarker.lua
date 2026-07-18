local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")
local template = {}

template.name = "ballhammer_pickup_marker"
template.unit_node = 1
template.size = { 220, 30 }
template.check_line_of_sight = false
template.max_distance = 999
template.screen_clamp = false
local STACK_GAP = 3
local STACK_SPEED = 14
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

local function layout_markers(t)
    if t ~= nil and last_layout_t == t then return end
    last_layout_t = t
    local markers = {}
    local max_distance = mod.get_pickup_distance()
    for unit, marker in pairs(mod.pickup_marker_refs) do
        local widget = marker.widget
        local distance = widget and widget.content.distance
        if ALIVE[unit] and marker.draw and distance and distance <= max_distance then
            local data = marker.data or mod.get_pickup_data(unit)
            markers[#markers + 1] = {
                marker = marker,
                x = widget.offset[1],
                y = widget.offset[2],
                distance = distance,
                name = data and data.name or "Pickup",
            }
        end
    end
    table.sort(markers, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return tostring(a.marker.unit) < tostring(b.marker.unit)
    end)

    -- ponytail: pickup counts are tiny; connected overlap scans beat a spatial index here.
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
                        and math.abs(source.x - candidate.x) < template.size[1]
                        and math.abs(source.y - candidate.y) < template.size[2] then
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
            local first_y = anchor_y + (#cluster - 1) * (template.size[2] + STACK_GAP) * 0.5
            for j = 1, #cluster do
                local item = cluster[j]
                local target_x = #cluster > 1 and anchor_x or item.x
                local target_y = #cluster > 1
                    and first_y - (j - 1) * (template.size[2] + STACK_GAP) or item.y
                local state = transition_states[item.marker.unit]
                if not state then
                    state = { x = item.x, y = item.y, last_t = t }
                    transition_states[item.marker.unit] = state
                end
                local dt = math.max(0, (t or state.last_t or 0) - (state.last_t or t or 0))
                state.last_t = t or state.last_t
                local alpha = 1 - math.exp(-STACK_SPEED * dt)
                state.x = state.x + (target_x - state.x) * alpha
                state.y = state.y + (target_y - state.y) * alpha
                item.marker.widget.offset[1] = state.x
                item.marker.widget.offset[2] = state.y
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

template.update_function = function(_, _, widget, marker, _, _, t)
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
    layout_markers(t)
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
        math.floor(70 * fade + 0.5), data.color[2], data.color[3], data.color[4]
    widget.style.name_shadow.text_color[1] = math.floor(180 * fade + 0.5)
    widget.style.distance.text_color[1] = math.floor(255 * fade + 0.5)
    widget.style.background.color[1] = math.floor(205 * fade + 0.5)
    widget.style.shadow.color[1] = math.floor(120 * fade + 0.5)
    local floor_distance = math.floor(distance)
    if floor_distance ~= marker.last_dist then
        marker.last_dist = floor_distance
        widget.content.distance_text = floor_distance .. "m"
    end
    widget.visible = true
end

return template
