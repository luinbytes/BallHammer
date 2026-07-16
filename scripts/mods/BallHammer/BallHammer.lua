local mod = get_mod("BallHammer")
local MarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerMarker")
local HordeMarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerHordeMarker")
local Recoil = require("scripts/utilities/recoil")

local BREED_DATA = {
    chaos_hound                 = { name = "Hound",           color = { 255, 255, 61,  61  }, outline_color = { 1,   0.24, 0.24 }, slot = "special_target" },
    chaos_armored_hound         = { name = "Armored Hound",   color = { 255, 255, 61,  61  }, outline_color = { 1,   0.24, 0.24 }, slot = "special_target" },
    chaos_poxwalker_bomber      = { name = "Bomber",          color = { 255, 255, 61,  61  }, outline_color = { 1,   0.24, 0.24 }, slot = "special_target" },
    cultist_mutant              = { name = "Mutant",          color = { 255, 255, 61,  61  }, outline_color = { 1,   0.24, 0.24 }, slot = "special_target" },
    renegade_sniper             = { name = "Sniper",          color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    cultist_flamer              = { name = "Flamer",          color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    renegade_flamer             = { name = "Flamer",          color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    cultist_grenadier           = { name = "Grenadier",       color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    renegade_grenadier          = { name = "Grenadier",       color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    renegade_netgunner          = { name = "Trapper",         color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    renegade_plasma_gunner      = { name = "Plasma Gunner",   color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    cultist_plasma_gunner       = { name = "Plasma Gunner",   color = { 255, 255, 165, 0   }, outline_color = { 1,   0.65, 0    }, slot = "special_target" },
    chaos_ogryn_bulwark         = { name = "Bulwark",         color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    chaos_ogryn_executor        = { name = "Crusher",         color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    chaos_ogryn_gunner          = { name = "Reaper",          color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    cultist_berzerker           = { name = "Rager",           color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    renegade_berzerker          = { name = "Rager",           color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    cultist_shocktrooper        = { name = "Shotgunner",      color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    renegade_shocktrooper       = { name = "Shotgunner",      color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    renegade_executor           = { name = "Maul",            color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    cultist_gunner              = { name = "Gunner",          color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    renegade_gunner             = { name = "Gunner",          color = { 255, 255, 255, 0   }, outline_color = { 1,   1,    0    }, slot = "smart_tagged_enemy" },
    chaos_beast_of_nurgle       = { name = "Beast of Nurgle", color = { 255, 180, 0,   255 }, outline_color = { 0.7, 0,    1    }, slot = "smart_tagged_enemy" },
    chaos_daemonhost            = { name = "Daemonhost",      color = { 255, 180, 0,   255 }, outline_color = { 0.7, 0,    1    }, slot = "smart_tagged_enemy" },
    chaos_spawn                 = { name = "Chaos Spawn",     color = { 255, 180, 0,   255 }, outline_color = { 0.7, 0,    1    }, slot = "smart_tagged_enemy" },
    chaos_plague_ogryn          = { name = "Plague Ogryn",    color = { 255, 180, 0,   255 }, outline_color = { 0.7, 0,    1    }, slot = "smart_tagged_enemy" },
    chaos_ogryn_houndmaster     = { name = "Houndmaster",     color = { 255, 180, 0,   255 }, outline_color = { 0.7, 0,    1    }, slot = "smart_tagged_enemy" },
    renegade_captain            = { name = "Captain",         color = { 255, 180, 0,   255 }, outline_color = { 0.7, 0,    1    }, slot = "smart_tagged_enemy" },
}

-- State
local unit_data_map       = {}
local active_markers      = {}
local horde_unit_data     = {}
local horde_active_markers = {}
local aim_target_map      = {}
local outline_system      = nil
local markers_ready       = false
local outline_check_timer = 0
local marker_retry_frames = 0
local marker_watchdog_tick = 0
local marker_requested_at = {}
local horde_marker_requested_at = {}

mod.enabled        = true
mod.active_markers = active_markers
mod.horde_unit_data = horde_unit_data
mod.horde_active_markers = horde_active_markers

local function breed_label(name)
    name = name:gsub("_mutator$", ""):gsub("^chaos_", ""):gsub("^cultist_", ""):gsub("^renegade_", "")
    return name:gsub("_", " "):gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end)
end

-- Store actual marker objects so we can kill them directly
local marker_refs = {}
mod.marker_refs   = marker_refs
local horde_marker_refs = {}
mod.horde_marker_refs = horde_marker_refs

local enable_outlines   = true
local enable_nameplates = true
local enable_horde_esp  = true
local max_distance      = 80
local horde_distance    = 80
local outline_distance  = 30
local aimbot_held       = false
local triggerbot_held    = false
local rage_held          = false
local auto_fire          = false
local aim_distance      = 80
local aim_fov           = 30
local aim_smoothness    = 55
local aim_curve         = 20
local aim_location      = "head"
local aim_activation    = "left_mouse"
local trigger_activation = "off"
local trigger_fov        = 5
local trigger_fire_fov   = 0.8
local trigger_smoothness = 35
local rage_distance      = 120
local rage_smoothness    = 10
local locked_target      = nil
local locked_mode        = nil
local locked_position    = nil
local lock_last_visible_t = nil

mod.get_unit_data         = function(unit) return unit_data_map[unit] end
mod.get_enable_nameplates = function() return enable_nameplates end
mod.get_max_distance      = function() return max_distance end
mod.get_enable_horde_esp  = function() return enable_horde_esp end
mod.get_horde_distance    = function() return horde_distance end
mod.get_aim_location      = function() return aim_location end

local function refresh_settings()
    enable_outlines   = mod:get("enable_outlines")
    enable_nameplates = mod:get("enable_nameplates")
    enable_horde_esp  = mod:get("enable_horde_esp")
    max_distance      = mod:get("max_distance")
    horde_distance    = mod:get("horde_distance")
    outline_distance  = mod:get("outline_distance")
    aim_distance      = mod:get("aim_distance")
    aim_fov           = mod:get("aim_fov")
    aim_smoothness    = mod:get("aim_smoothness")
    aim_curve         = mod:get("aim_curve")
    aim_location      = mod:get("aim_location")
    aim_activation    = mod:get("aim_activation")
    trigger_activation = mod:get("trigger_activation")
    trigger_fov        = mod:get("trigger_fov")
    trigger_fire_fov   = mod:get("trigger_fire_fov")
    trigger_smoothness = mod:get("trigger_smoothness")
    rage_distance      = mod:get("rage_distance")
    rage_smoothness    = mod:get("rage_smoothness")
end

local function activation_is_held(activation, custom_held, input_extension)
    if activation == "custom" then return custom_held end
    if not input_extension then return false end
    if activation == "left_mouse" then return input_extension:get("action_one_hold") end
    if activation == "right_mouse" then return input_extension:get("action_two_hold") end
    if activation == "both_mouse" then
        return input_extension:get("action_one_hold") or input_extension:get("action_two_hold")
    end
    return false
end

local function apply_outline(unit, data)
    if not outline_system or not enable_outlines then return end
    pcall(function()
        outline_system:add_outline(unit, data.slot)
        local oc = data.outline_color
        Unit.set_vector3_for_materials(unit, "outline_color", Vector3(oc[1], oc[2], oc[3]), true)
    end)
end

local function remove_outline(unit, data)
    if not outline_system then return end
    pcall(function() outline_system:remove_outline(unit, data.slot) end)
end

local function kill_marker(unit)
    -- Set remove directly on the marker object — guaranteed cleanup
    local marker = marker_refs[unit]
    if marker then
        marker.remove = true
        marker_refs[unit] = nil
    end
    active_markers[unit] = nil
    marker_requested_at[unit] = nil
end

local function kill_horde_marker(unit)
    local marker = horde_marker_refs[unit]
    if marker then
        marker.remove = true
        horde_marker_refs[unit] = nil
    end
    horde_active_markers[unit] = nil
    horde_marker_requested_at[unit] = nil
end

local function add_marker(unit)
    if not markers_ready or active_markers[unit] then return end
    active_markers[unit] = true
    marker_requested_at[unit] = marker_watchdog_tick
    Managers.event:trigger("add_world_marker_unit", MarkerTemplate.name, unit, nil, unit_data_map[unit])
end

local function add_horde_marker(unit)
    if not markers_ready or horde_active_markers[unit] then return end
    horde_active_markers[unit] = true
    horde_marker_requested_at[unit] = marker_watchdog_tick
    Managers.event:trigger("add_world_marker_unit", HordeMarkerTemplate.name, unit, nil, horde_unit_data[unit])
end

local function add_esp_for_unit(unit)
    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    if not unit_data then return end
    local breed = unit_data:breed()
    if not breed then return end
    local tags = breed.tags or {}
    local is_enemy = tags.minion or tags.horde or tags.special or tags.elite or tags.monster
        or tags.captain or tags.cultist_captain or BREED_DATA[breed.name]
    if not is_enemy then return end

    local data = BREED_DATA[breed.name]
    local is_mutator = false
    if not data and breed.name:find("_mutator") then
        local base_name = breed.name:gsub("_mutator", "")
        data = BREED_DATA[base_name]
        is_mutator = true
    end
    local is_priority = breed.smart_tag_target_type == "breed" or data or tags.special or tags.elite
        or tags.monster or tags.captain or tags.cultist_captain or not (tags.horde or tags.roamer)
    if not is_priority then
        horde_unit_data[unit] = {
            name = breed_label(breed.name),
            color = { 255, 255, 158, 181 },
            base_height = breed.base_height or 1.8,
            clusterable = true,
            force_horde_merge = breed.name == "chaos_newly_infected" or breed.name == "chaos_armored_infected",
        }
        aim_target_map[unit] = true
        if mod.enabled and enable_horde_esp then add_horde_marker(unit) end
        return
    end

    local priority_data = {
        name = data and data.name or breed_label(breed.name),
        color = { 255, 255, 80, 80 },
        outline_color = { 1, 0.31, 0.31 },
        slot = data and data.slot or (tags.special and "special_target" or "smart_tagged_enemy"),
        flag = (tags.monster or tags.captain or tags.cultist_captain) and "BOSS" or "SPECIAL",
    }
    if is_mutator then priority_data.name = priority_data.name .. " [M]" end
    unit_data_map[unit] = priority_data
    aim_target_map[unit] = true

    if mod.enabled and enable_outlines then
        local has = false
        if outline_system then
            pcall(function() has = outline_system:has_outline(unit, priority_data.slot) end)
        end
        if not has then apply_outline(unit, unit_data_map[unit]) end
    end

    if mod.enabled and enable_nameplates then add_marker(unit) end
end

mod.toggle_esp = function()
    mod.enabled = not mod.enabled
    mod:echo("BallHammer: " .. (mod.enabled and "ON" or "OFF"))
    if not mod.enabled then
        for unit, data in pairs(unit_data_map) do
            remove_outline(unit, data)
            kill_marker(unit)
        end
        for unit, _ in pairs(horde_unit_data) do kill_horde_marker(unit) end
    else
        for unit, data in pairs(unit_data_map) do
            if HEALTH_ALIVE and HEALTH_ALIVE[unit] then
                apply_outline(unit, data)
                if enable_nameplates then add_marker(unit) end
            end
        end
        if enable_horde_esp then
            for unit, _ in pairs(horde_unit_data) do
                if HEALTH_ALIVE and HEALTH_ALIVE[unit] then add_horde_marker(unit) end
            end
        end
    end
end

mod.aimbot_held = function(held)
    aimbot_held = held
end

mod.triggerbot_held = function(held)
    triggerbot_held = held
end

mod.rage_held = function(held)
    rage_held = held
end

mod.on_setting_changed = function(setting_id)
    mod:echo("setting_changed: " .. tostring(setting_id))
    if not setting_id then return end

    if setting_id == "aim_distance" or setting_id == "aim_fov" or setting_id == "aim_smoothness" or
       setting_id == "aim_curve" or setting_id == "aim_location" or setting_id == "aim_activation" or
       setting_id == "trigger_activation" or setting_id == "trigger_fov" or
       setting_id == "trigger_fire_fov" or setting_id == "trigger_smoothness" or
       setting_id == "rage_distance" or setting_id == "rage_smoothness" then
        aim_distance  = mod:get("aim_distance")
        aim_fov       = mod:get("aim_fov")
        aim_smoothness = mod:get("aim_smoothness")
        aim_curve     = mod:get("aim_curve")
        aim_location  = mod:get("aim_location")
        aim_activation = mod:get("aim_activation")
        trigger_activation = mod:get("trigger_activation")
        trigger_fov = mod:get("trigger_fov")
        trigger_fire_fov = mod:get("trigger_fire_fov")
        trigger_smoothness = mod:get("trigger_smoothness")
        rage_distance = mod:get("rage_distance")
        rage_smoothness = mod:get("rage_smoothness")
        return
    end

    if setting_id == "enable_horde_esp" then
        enable_horde_esp = mod:get("enable_horde_esp")
        if enable_horde_esp and mod.enabled then
            for unit, _ in pairs(horde_unit_data) do
                if HEALTH_ALIVE and HEALTH_ALIVE[unit] then add_horde_marker(unit) end
            end
        else
            for unit, _ in pairs(horde_unit_data) do kill_horde_marker(unit) end
        end
        return
    end

    if setting_id == "horde_distance" then
        horde_distance = mod:get("horde_distance")
        return
    end

    if not mod.enabled then return end

    if setting_id == "enable_outlines" then
        local old = enable_outlines
        enable_outlines = mod:get("enable_outlines")
        if enable_outlines == old then return end
        if enable_outlines then
            for unit, data in pairs(unit_data_map) do
                if HEALTH_ALIVE and HEALTH_ALIVE[unit] then apply_outline(unit, data) end
            end
        else
            for unit, data in pairs(unit_data_map) do remove_outline(unit, data) end
        end
        if enable_nameplates then
            for unit, _ in pairs(unit_data_map) do kill_marker(unit) end
            marker_retry_frames = 10
        end
        return
    end

    if setting_id == "enable_nameplates" then
        local old = enable_nameplates
        enable_nameplates = mod:get("enable_nameplates")
        if enable_nameplates == old then return end
        if enable_nameplates then
            marker_retry_frames = 10
        else
            for unit, _ in pairs(unit_data_map) do kill_marker(unit) end
        end
        return
    end

    if setting_id == "outline_distance" then
        local old = outline_distance
        outline_distance = mod:get("outline_distance")
        if outline_distance == old then return end
        if outline_system then
            for unit, data in pairs(unit_data_map) do remove_outline(unit, data) end
        end
        outline_check_timer = 60
        return
    end

    if setting_id == "max_distance" then
        local old = max_distance
        max_distance = mod:get("max_distance")
        if max_distance == old then return end
        for unit, _ in pairs(unit_data_map) do kill_marker(unit) end
        marker_retry_frames = 5
        return
    end
end

mod:command("esp", "Toggle enemy ESP", mod.toggle_esp)

mod:hook_safe(CLASS.OutlineSystem, "init", function(self)
    outline_system = self
end)

mod:hook_safe(CLASS.OutlineSystem, "on_add_extension", function(self, world, unit, extension_name)
    if not mod.enabled then return end
    outline_system = self
    if not unit_data_map[unit] and not horde_unit_data[unit] then add_esp_for_unit(unit) end
    local data = unit_data_map[unit]
    if not data then return end
    if enable_outlines then
        local has = false
        pcall(function() has = self:has_outline(unit, data.slot) end)
        if not has then
            pcall(function()
                self:add_outline(unit, data.slot)
                local oc = data.outline_color
                Unit.set_vector3_for_materials(unit, "outline_color", Vector3(oc[1], oc[2], oc[3]), true)
            end)
        end
    end
    if enable_nameplates then add_marker(unit) end
end)

mod:hook_safe(CLASS.OutlineSystem, "on_remove_extension", function(self, unit, extension_name)
    kill_marker(unit)
    kill_horde_marker(unit)
    unit_data_map[unit] = nil
    horde_unit_data[unit] = nil
    aim_target_map[unit] = nil
end)

mod:hook_safe("HudElementWorldMarkers", "init", function(self)
    self._marker_templates[MarkerTemplate.name] = MarkerTemplate
    self._marker_templates[HordeMarkerTemplate.name] = HordeMarkerTemplate
    markers_ready = true
    -- HUD was recreated — clear stale marker state so retry loop re-adds everything
    table.clear(active_markers)
    table.clear(marker_refs)
    table.clear(horde_active_markers)
    table.clear(horde_marker_refs)
    if mod.enabled and (enable_nameplates or enable_horde_esp) then
        marker_retry_frames = 10
    end
end)

mod:hook_safe("HudElementWorldMarkers", "update", function(self, dt, t)
    -- Retry markers for pre-spawned units
    if marker_retry_frames > 0 then
        marker_retry_frames = marker_retry_frames - 1
        if mod.enabled and enable_nameplates then
            for unit, data in pairs(unit_data_map) do
                if HEALTH_ALIVE and HEALTH_ALIVE[unit] and not active_markers[unit] then
                    add_marker(unit)
                end
            end
        end
        if mod.enabled and enable_horde_esp then
            for unit, data in pairs(horde_unit_data) do
                if HEALTH_ALIVE and HEALTH_ALIVE[unit] and not horde_active_markers[unit] then
                    add_horde_marker(unit)
                end
            end
        end
    end

    -- Distance checks every 60 frames
    outline_check_timer = outline_check_timer + 1
    if outline_check_timer < 60 then return end
    outline_check_timer = 0
    marker_watchdog_tick = marker_watchdog_tick + 1

    local extension_manager = Managers.state and Managers.state.extension
    local minions = extension_manager and extension_manager:get_entities("MinionUnitDataExtension")
    for unit in pairs(minions or {}) do
        if HEALTH_ALIVE[unit] and not unit_data_map[unit] and not horde_unit_data[unit] then
            add_esp_for_unit(unit)
        end
    end

    -- A marker event can be dropped while the HUD is rebuilding. Retry any request
    -- that never produced a live marker object instead of losing that enemy forever.
    for unit in pairs(active_markers) do
        local marker = marker_refs[unit]
        local requested_at = marker_requested_at[unit] or marker_watchdog_tick
        if HEALTH_ALIVE[unit] and marker and marker.remove then
            marker_refs[unit] = nil
            active_markers[unit] = nil
            marker_requested_at[unit] = nil
        elseif HEALTH_ALIVE[unit] and not marker and marker_watchdog_tick - requested_at >= 2 then
            active_markers[unit] = nil
            marker_requested_at[unit] = nil
        end
    end
    for unit in pairs(horde_active_markers) do
        local marker = horde_marker_refs[unit]
        local requested_at = horde_marker_requested_at[unit] or marker_watchdog_tick
        if HEALTH_ALIVE[unit] and marker and marker.remove then
            horde_marker_refs[unit] = nil
            horde_active_markers[unit] = nil
            horde_marker_requested_at[unit] = nil
        elseif HEALTH_ALIVE[unit] and not marker and marker_watchdog_tick - requested_at >= 2 then
            horde_active_markers[unit] = nil
            horde_marker_requested_at[unit] = nil
        end
    end
    if mod.enabled and enable_horde_esp then
        for unit in pairs(horde_unit_data) do
            if HEALTH_ALIVE[unit] and not horde_active_markers[unit] then add_horde_marker(unit) end
        end
    end

    if not mod.enabled then return end

    local player = Managers.player and Managers.player:local_player(1)
    if not player or not player.player_unit or not ALIVE[player.player_unit] then return end
    local ppos = Unit.world_position(player.player_unit, 1)
    if not ppos then return end

    for unit, data in pairs(unit_data_map) do
        if HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local epos = Unit.world_position(unit, 1)
            if epos then
                local dist = Vector3.length(epos - ppos)

                if outline_system and enable_outlines then
                    local has = outline_system:has_outline(unit, data.slot)
                    if dist > outline_distance and has then
                        pcall(function() outline_system:remove_outline(unit, data.slot) end)
                    elseif dist <= outline_distance and not has then
                        pcall(function()
                            outline_system:add_outline(unit, data.slot)
                            local oc = data.outline_color
                            Unit.set_vector3_for_materials(unit, "outline_color", Vector3(oc[1], oc[2], oc[3]), true)
                        end)
                    end
                end

                if enable_nameplates then
                    if dist <= max_distance and not active_markers[unit] then
                        add_marker(unit)
                    end
                end
            end
        end
    end
end)

local function has_line_of_sight(physics_world, player_unit, target_unit, origin, direction, distance)
    local hits = PhysicsWorld.raycast(
        physics_world,
        origin,
        direction,
        distance,
        "all",
        "collision_filter",
        "filter_player_character_shooting_raycast"
    )

    if not hits then return true end

    for i = 1, #hits do
        local actor = hits[i][4]
        local hit_unit = actor and Actor.unit(actor)
        if not hit_unit then return false end
        if hit_unit == target_unit then return true end
        if hit_unit ~= player_unit then return false end
    end

    return true
end

local AIM_NODES = {
    head = { "j_head", "j_neck", "j_spine" },
    torso = { "j_spine", "j_spine1", "j_hips" },
}

local function native_vector(position)
    return position and Vector3(position.x, position.y, position.z) or nil
end

local function aim_position(unit)
    local nodes = AIM_NODES[aim_location] or AIM_NODES.head
    for i = 1, #nodes do
        local node_name = nodes[i]
        if Unit.has_node(unit, node_name) then
            return native_vector(Unit.world_position(unit, Unit.node(unit, node_name)))
        end
    end

    local body = native_vector(Unit.world_position(unit, 1))
    if not body then return nil end
    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    local breed = unit_data and unit_data:breed()
    local height = breed and breed.base_height or 1.8
    local height_fraction = aim_location == "torso" and 0.6 or 0.85
    return body + Vector3(0, 0, height * height_fraction)
end

local function danger_score(unit)
    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    local breed = unit_data and unit_data:breed()
    local tags = breed and breed.tags or {}
    if tags.monster or tags.captain or tags.cultist_captain then return 1 end
    if tags.special then return 0.9 end
    if tags.elite then return 0.75 end
    if breed and breed.smart_tag_target_type == "breed" then return 0.65 end
    return 0.2
end

local function target_metrics(physics_world, player_unit, target_unit, origin, camera_forward, mode, distance_limit, fov, on_screen)
    if not HEALTH_ALIVE or not HEALTH_ALIVE[target_unit] then return nil end
    local position = aim_position(target_unit)
    if not position then return nil end

    local offset = position - origin
    local distance = Vector3.length(offset)
    if distance <= 0 or distance > distance_limit then return nil end

    local direction = Vector3.normalize(offset)
    local dot = Vector3.dot(camera_forward, direction)
    if mode == "rage" then
        if not on_screen(position) then return nil end
    elseif dot < math.cos(math.rad(fov * 0.5)) then
        return nil
    end

    local visible = has_line_of_sight(physics_world, player_unit, target_unit, origin, direction, distance)
    local range_score = 1 - distance / distance_limit
    local score = mode == "rage"
        and danger_score(target_unit) * 0.5 + math.max(dot, 0) * 0.3 + range_score * 0.2
        or dot + range_score * 0.001
    return position, score, visible
end

local function clear_aim_lock()
    locked_target = nil
    locked_mode = nil
    locked_position = nil
    lock_last_visible_t = nil
end

local function select_aim_target(physics_world, player_unit, origin, camera_forward, mode, distance_limit, fov, on_screen, dt, t)
    if locked_mode ~= mode then clear_aim_lock() end

    local current_position, current_score, current_visible
    if locked_target then
        local lock_fov = math.min(fov * 1.3, 180)
        current_position, current_score, current_visible = target_metrics(
            physics_world, player_unit, locked_target, origin, camera_forward,
            mode, distance_limit, lock_fov, on_screen
        )
        if current_position then
            if current_visible then
                lock_last_visible_t = t
            elseif not lock_last_visible_t or t - lock_last_visible_t > 0.2 then
                current_position = nil
            end
        end
        if not current_position then clear_aim_lock() end
    end

    local best_unit, best_position, best_score
    if not locked_target or mode == "rage" then
        for target_unit in pairs(aim_target_map) do
            local position, score, visible = target_metrics(
                physics_world, player_unit, target_unit, origin, camera_forward,
                mode, distance_limit, fov, on_screen
            )
            if visible and (not best_score or score > best_score) then
                best_unit, best_position, best_score = target_unit, position, score
            end
        end
    end

    if not locked_target or mode == "rage" and best_unit and best_unit ~= locked_target
        and best_score > (current_score or -1) + 0.12 then
        locked_target = best_unit
        locked_mode = mode
        locked_position = { x = best_position.x, y = best_position.y, z = best_position.z }
        lock_last_visible_t = t
        current_position, current_visible = best_position, true
    end
    if not locked_target or not current_position then return nil end

    local position_alpha = 1 - math.exp(-18 * dt)
    locked_position.x = locked_position.x + (current_position.x - locked_position.x) * position_alpha
    locked_position.y = locked_position.y + (current_position.y - locked_position.y) * position_alpha
    locked_position.z = locked_position.z + (current_position.z - locked_position.z) * position_alpha
    return Vector3(locked_position.x, locked_position.y, locked_position.z), current_visible
end

local function aim_at_position(player, unit_data, self, first_person, target_position, dt, smoothness)
    local direction = Vector3.normalize(target_position - first_person.position)
    local target_yaw = math.atan2(direction.y, direction.x) - math.pi * 0.5
    local target_pitch = math.asin(math.clamp(direction.z, -1, 1))
    local recoil_pitch, recoil_yaw = Recoil.first_person_offset(
        self._weapon_extension:recoil_template(),
        self._recoil_component,
        self._movement_state_component,
        self._locomotion_component,
        self._inair_state_component
    )
    local sway = unit_data:read_component("sway")
    target_yaw = target_yaw - recoil_yaw - (sway and sway.offset_x or 0)
    target_pitch = target_pitch - recoil_pitch - (sway and sway.offset_y or 0)

    local orientation = player:get_orientation()
    local yaw_delta = (target_yaw - orientation.yaw + math.pi) % (math.pi * 2) - math.pi
    local pitch_delta = (target_pitch - orientation.pitch + math.pi) % (math.pi * 2) - math.pi
    local response = 2 + (100 - math.clamp(smoothness, 0, 100)) * 0.22
    local alpha = 1 - math.exp(-response * dt)
    local curve = math.clamp(aim_curve, 0, 100) * 0.0035 * alpha * (1 - alpha)
    local yaw = orientation.yaw + yaw_delta * alpha - pitch_delta * curve
    local pitch = orientation.pitch + pitch_delta * alpha + yaw_delta * curve

    player:set_orientation(yaw, pitch, 0)
    return math.deg(math.sqrt(yaw_delta * yaw_delta + pitch_delta * pitch_delta))
end

mod:hook(CLASS.PlayerUnitInputExtension, "get", function(func, self, action, ...)
    if auto_fire and self._is_local_unit and (action == "action_one_pressed" or action == "action_one_hold") then
        return true
    end
    return func(self, action, ...)
end)

mod:hook_safe("PlayerUnitFirstPersonExtension", "fixed_update", function(self, unit, dt, t, frame)
    if not dt or dt <= 0 then return end

    -- Generated fire must not satisfy the aimbot's left-mouse activation check.
    auto_fire = false
    local mode
    if rage_held then
        mode = "rage"
    elseif activation_is_held(trigger_activation, triggerbot_held, self._input_extension) then
        mode = "trigger"
    elseif activation_is_held(aim_activation, aimbot_held, self._input_extension) then
        mode = "aim"
    end
    if not mode then
        clear_aim_lock()
        return
    end

    local player = Managers.player and Managers.player:local_player(1)
    if not player or unit ~= player.player_unit or not player:unit_is_alive() then
        auto_fire = false
        clear_aim_lock()
        return
    end

    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    if not unit_data then return end

    local first_person = unit_data:read_component("first_person")
    if not first_person or not first_person.position or not first_person.rotation then return end

    local camera_forward = Quaternion.forward(first_person.rotation)
    local physics_world = World.physics_world(self._world)
    local distance_limit = mode == "rage" and rage_distance or aim_distance
    local fov = mode == "trigger" and trigger_fov or aim_fov
    local on_screen = function(position) return self:is_within_default_view(position) end
    local target_position, visible = select_aim_target(
        physics_world, unit, first_person.position, camera_forward,
        mode, distance_limit, fov, on_screen, dt, t
    )
    if not target_position then
        auto_fire = false
        return
    end

    local smoothness = mode == "rage" and rage_smoothness
        or mode == "trigger" and trigger_smoothness
        or aim_smoothness
    local error = aim_at_position(player, unit_data, self, first_person, target_position, dt, smoothness)
    auto_fire = visible and (mode == "rage" and error <= 1.5
        or mode == "trigger" and error <= trigger_fire_fov)
end)

mod:hook_safe("HealthExtension", "init", function(self, extension_init_context, unit)
    add_esp_for_unit(unit)
end)

mod:hook_safe("HuskHealthExtension", "init", function(self, extension_init_context, unit)
    add_esp_for_unit(unit)
end)

refresh_settings()
mod:echo("Loaded! - By @luinbytes")
