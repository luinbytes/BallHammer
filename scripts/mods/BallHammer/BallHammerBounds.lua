local bounds = {}
bounds.OFFSCREEN_BUFFER = 128

local BONE_NODES = {
    "j_head", "j_jaw", "j_neck", "j_neck1", "j_spine", "j_spine1", "j_spine2", "j_hips",
    "j_leftshoulder", "j_leftarm", "j_leftforearm", "j_lefthand",
    "j_rightshoulder", "j_rightarm", "j_rightforearm", "j_righthand",
    "j_leftupleg", "j_leftleg", "j_leftfoot", "j_lefttoebase",
    "j_rightupleg", "j_rightleg", "j_rightfoot", "j_righttoebase",
}

local function screen_point(parent, camera, position, screen_x, screen_y, inverse_scale)
    local x, y = parent:_convert_world_to_screen_position(camera, position)
    if not x or not y then return nil end
    return (x - screen_x) * inverse_scale, (y - screen_y) * inverse_scale
end

function bounds.project(parent, ui_renderer, camera, unit, body, fallback_height, aim_node)
    local screen_x, screen_y = parent:_get_screen_offset(ui_renderer.scale)
    local inverse_scale = ui_renderer.inverse_scale
    local left, right, top, bottom, aim_x, aim_y
    local points = 0

    for i = 1, #BONE_NODES do
        local node_name = BONE_NODES[i]
        if Unit.has_node(unit, node_name) then
            local x, y = screen_point(parent, camera, Unit.world_position(unit, Unit.node(unit, node_name)), screen_x, screen_y, inverse_scale)
            if x then
                left, right = left and math.min(left, x) or x, right and math.max(right, x) or x
                top, bottom = top and math.min(top, y) or y, bottom and math.max(bottom, y) or y
                points = points + 1
                if node_name == aim_node then aim_x, aim_y = x, y end
            end
        end
    end

    if points < 2 then
        local body_x, body_y = screen_point(parent, camera, body, screen_x, screen_y, inverse_scale)
        local world_x, world_y, world_z = Vector3.to_elements(body)
        local top_x, top_y = screen_point(parent, camera,
            Vector3(world_x, world_y, world_z + (fallback_height or 1.8)), screen_x, screen_y, inverse_scale)
        if not body_x or not top_x then return nil end
        left, right = math.min(body_x, top_x), math.max(body_x, top_x)
        top, bottom = math.min(body_y, top_y), math.max(body_y, top_y)
    end

    local padding = 3
    left, right, top, bottom = left - padding, right + padding, top - padding, bottom + padding
    return {
        left = left,
        right = right,
        top = top,
        bottom = bottom,
        aim_x = aim_x or (left + right) * 0.5,
        aim_y = aim_y or top + padding,
    }
end

function bounds.in_screen_buffer(box, width, height, buffer)
    return box.right >= -buffer and box.left <= width + buffer and
        box.bottom >= -buffer and box.top <= height + buffer
end

function bounds.point_in_screen_buffer(parent, ui_renderer, camera, position)
    local screen_x, screen_y = parent:_get_screen_offset(ui_renderer.scale)
    local x, y = screen_point(parent, camera, position, screen_x, screen_y, ui_renderer.inverse_scale)
    if not x then return false end
    local width = RESOLUTION_LOOKUP.width * ui_renderer.inverse_scale
    local height = RESOLUTION_LOOKUP.height * ui_renderer.inverse_scale
    return bounds.in_screen_buffer({ left = x, right = x, top = y, bottom = y },
        width, height, bounds.OFFSCREEN_BUFFER), x, y
end

return bounds
