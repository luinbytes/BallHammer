local mod = get_mod("BallHammer")
local MarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerMarker")
local HordeMarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerHordeMarker")
local Recoil = require("scripts/utilities/recoil")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

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

local COMPANION_DANGER = {
    chaos_hound = 1,
    chaos_armored_hound = 1,
    chaos_poxwalker_bomber = 1,
    cultist_mutant = 1,
    renegade_netgunner = 1,
    renegade_sniper = 0.95,
    cultist_flamer = 0.95,
    renegade_flamer = 0.95,
    cultist_grenadier = 0.95,
    renegade_grenadier = 0.95,
    renegade_plasma_gunner = 0.95,
    cultist_plasma_gunner = 0.95,
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
local aim_distance      = 80
local aim_fov           = 30
local aim_smoothness    = 55
local aim_curve         = 20
local aim_location      = "head"
local aim_activation    = "left_mouse"
local enable_auto_fire  = true
local enable_no_recoil  = false
local enable_no_spread  = false
local locked_target      = nil
local locked_position    = nil
local enable_companion_target = true
local companion_distance = 60
local enable_auto_whistle = false
local companion_target = nil
local companion_next_scan_t = 0
local companion_waiting_for_damage = false
local companion_wait_deadline_t = 0
local companion_attackers = {}
local auto_whistle_pending_target = nil
local auto_whistle_used_target = nil
local auto_whistle_hold_until = nil
local auto_whistle_input_phase = nil
local next_smart_target_refresh_t = 0

mod.get_unit_data         = function(unit) return unit_data_map[unit] end
mod.get_enable_nameplates = function() return enable_nameplates end
mod.get_max_distance      = function() return max_distance end
mod.get_enable_horde_esp  = function() return enable_horde_esp end
mod.get_horde_distance    = function() return horde_distance end
mod.get_aim_location      = function() return aim_location end

local function refresh_marker_aim_node()
    local node = aim_location == "torso" and "j_spine" or "j_head"
    MarkerTemplate.unit_node = node
    HordeMarkerTemplate.unit_node = node
    for _, marker in pairs(marker_refs) do
        if marker.template then marker.template.unit_node = node end
    end
    for _, marker in pairs(horde_marker_refs) do
        if marker.template then marker.template.unit_node = node end
    end
end

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
    enable_auto_fire  = mod:get("enable_auto_fire")
    enable_no_recoil  = mod:get("enable_no_recoil")
    enable_no_spread  = mod:get("enable_no_spread")
    enable_companion_target = mod:get("enable_companion_target")
    companion_distance = mod:get("companion_distance")
    enable_auto_whistle = mod:get("enable_auto_whistle")
    refresh_marker_aim_node()
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
        base_height = breed.base_height or 1.8,
        companion_targetable = breed.smart_tag_target_type == "breed",
        companion_danger = COMPANION_DANGER[breed.name]
            or COMPANION_DANGER[breed.name:gsub("_mutator$", "")]
            or (tags.monster or tags.captain or tags.cultist_captain) and 0.85
            or tags.special and 0.9
            or tags.elite and 0.7
            or 0.75,
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

mod.on_setting_changed = function(setting_id)
    mod:echo("setting_changed: " .. tostring(setting_id))
    if not setting_id then return end

    if setting_id == "aim_distance" or setting_id == "aim_fov" or setting_id == "aim_smoothness" or
       setting_id == "aim_curve" or setting_id == "aim_location" or setting_id == "aim_activation" then
        aim_distance  = mod:get("aim_distance")
        aim_fov       = mod:get("aim_fov")
        aim_smoothness = mod:get("aim_smoothness")
        aim_curve     = mod:get("aim_curve")
        aim_location  = mod:get("aim_location")
        aim_activation = mod:get("aim_activation")
        refresh_marker_aim_node()
        return
    end

    if setting_id == "enable_auto_fire" or setting_id == "enable_no_recoil"
        or setting_id == "enable_no_spread" then
        enable_auto_fire = mod:get("enable_auto_fire")
        enable_no_recoil = mod:get("enable_no_recoil")
        enable_no_spread = mod:get("enable_no_spread")
        return
    end

    if setting_id == "enable_companion_target" or setting_id == "companion_distance"
        or setting_id == "enable_auto_whistle" then
        enable_companion_target = mod:get("enable_companion_target")
        companion_distance = mod:get("companion_distance")
        enable_auto_whistle = mod:get("enable_auto_whistle")
        if not enable_companion_target then
            companion_target = nil
            companion_waiting_for_damage = false
            companion_wait_deadline_t = 0
            table.clear(companion_attackers)
        end
        if not enable_companion_target or not enable_auto_whistle then
            auto_whistle_pending_target = nil
            auto_whistle_used_target = nil
            auto_whistle_hold_until = nil
        end
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

local function has_line_of_sight(physics_world, target_unit, origin, direction, distance)
    local hits = PhysicsWorld.raycast(
        physics_world,
        origin,
        direction,
        distance,
        "all",
        "collision_filter",
        "filter_interactable_line_of_sight_marker_check"
    )

    if not hits then return true end

    for i = 1, #hits do
        local actor = hits[i][4]
        if actor and Actor.unit(actor) ~= target_unit then return false end
    end

    return true
end

local AIM_NODES = {
    head = { "j_head", "j_neck", "j_spine" },
    torso = { "j_spine", "j_spine1", "j_hips" },
}

local function native_vector(position)
    if not position then return nil end
    local x, y, z = Vector3.to_elements(position)
    return Vector3(x, y, z)
end

local function fallback_aim_position(unit)
    local body = native_vector(Unit.world_position(unit, 1))
    if not body then return nil end
    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    local breed = unit_data and unit_data:breed()
    local height = breed and breed.base_height or 1.8
    local height_fraction = aim_location == "torso" and 0.6 or 0.85
    return body + Vector3(0, 0, height * height_fraction)
end

local function player_camera_position(player, fallback)
    local camera_manager = Managers.state and Managers.state.camera
    if not camera_manager or not player.viewport_name then return fallback end
    local ok, camera = pcall(camera_manager.camera, camera_manager, player.viewport_name)
    if not ok or not camera then return fallback end
    local position_ok, position = pcall(Camera.local_position, camera)
    return position_ok and native_vector(position) or fallback
end

local function update_companion_target(player_unit, origin, physics_world, t)
    if t < companion_next_scan_t - 1 then
        companion_target = nil
        companion_next_scan_t = 0
        companion_waiting_for_damage = false
        companion_wait_deadline_t = 0
        table.clear(companion_attackers)
    end
    if not enable_companion_target then return end
    if companion_target and (not HEALTH_ALIVE or not HEALTH_ALIVE[companion_target]) then
        companion_target = nil
        companion_waiting_for_damage = false
        companion_wait_deadline_t = 0
        companion_next_scan_t = 0
        table.clear(companion_attackers)
    end
    if auto_whistle_pending_target and not auto_whistle_hold_until
        and (not HEALTH_ALIVE or not HEALTH_ALIVE[auto_whistle_pending_target]) then
        auto_whistle_pending_target = nil
    end
    if auto_whistle_used_target and (not HEALTH_ALIVE or not HEALTH_ALIVE[auto_whistle_used_target]) then
        auto_whistle_used_target = nil
    end
    if t < companion_next_scan_t then return end
    companion_next_scan_t = t + 0.35

    local spawner = ScriptUnit.has_extension(player_unit, "companion_spawner_system")
    if not spawner or not spawner:companion_can_tag_order() then
        companion_target = nil
        companion_waiting_for_damage = false
        companion_wait_deadline_t = 0
        table.clear(companion_attackers)
        return
    end

    local best_unit, best_score, best_wait, current_score, current_wait
    for unit, data in pairs(unit_data_map) do
        if data.companion_targetable and HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local body = native_vector(Unit.world_position(unit, 1))
            if body then
                local target_position = body + Vector3(0, 0, data.base_height * 0.6)
                local offset = target_position - origin
                local distance = Vector3.length(offset)
                if distance > 0 and distance <= companion_distance and has_line_of_sight(
                    physics_world, unit, origin, Vector3.normalize(offset), distance
                ) then
                    local health = ScriptUnit.has_extension(unit, "health_system")
                    local health_fraction = health and math.clamp(health:current_health_percent(), 0, 1) or 1
                    local score = data.companion_danger * 0.55
                        + (1 - distance / companion_distance) * 0.3
                        + (1 - health_fraction) * 0.15
                    local wait_time = math.clamp(2 + distance / 8, 3, 10)
                    if unit == companion_target then
                        current_score, current_wait = score, wait_time
                    end
                    if not best_score or score > best_score then
                        best_unit, best_score, best_wait = unit, score, wait_time
                    end
                end
            end
        end
    end

    if companion_waiting_for_damage and t < companion_wait_deadline_t then return end
    companion_waiting_for_damage = false
    companion_wait_deadline_t = 0

    local chosen, chosen_wait = current_score and companion_target or best_unit,
        current_score and current_wait or best_wait
    if current_score and best_unit ~= companion_target and best_score > current_score + 0.08 then
        chosen, chosen_wait = best_unit, best_wait
    end
    if not chosen then
        companion_target = nil
        table.clear(companion_attackers)
        return
    end

    if chosen ~= companion_target then
        local extension_manager = Managers.state and Managers.state.extension
        local smart_tag_system = extension_manager and extension_manager:system("smart_tag_system")
        if smart_tag_system then
            smart_tag_system:set_contextual_unit_tag(player_unit, chosen, "companion_order")
            table.clear(companion_attackers)
            local companions = spawner:companion_units()
            for i = 1, companions and #companions or 0 do
                companion_attackers[companions[i]] = true
            end
            companion_waiting_for_damage = true
            companion_wait_deadline_t = t + chosen_wait
        else
            companion_target = nil
            return
        end
    end
    companion_target = chosen
end

local function queue_auto_whistle(target_unit)
    if not enable_auto_whistle or target_unit == auto_whistle_used_target
        or target_unit == auto_whistle_pending_target then return end
    local player = Managers.player and Managers.player:local_player(1)
    local player_unit = player and player.player_unit
    local ability = player_unit and ScriptUnit.has_extension(player_unit, "ability_system")
    if ability and ability:get_current_grenade_ability_name() == "adamant_whistle"
        and ability:can_use_ability("grenade_ability") then
        auto_whistle_pending_target = target_unit
    end
end

mod:hook_safe("AttackReportManager", "add_attack_result", function(
    self, damage_profile, attacked_unit, attacking_unit, attack_direction,
    hit_world_position, hit_weakspot, damage
)
    if damage and damage > 0 and attacked_unit == companion_target
        and companion_attackers[attacking_unit] then
        queue_auto_whistle(attacked_unit)
        if companion_waiting_for_damage then
            companion_waiting_for_damage = false
            companion_wait_deadline_t = 0
            companion_next_scan_t = 0
        end
    end
end)

local function target_metrics(physics_world, target_unit, origin, camera_forward, distance_limit, fov, ignore_fov)
    if not HEALTH_ALIVE or not HEALTH_ALIVE[target_unit] then return nil end
    local first_position, first_score, first_distance

    local function evaluate(position)
        if not position then return nil end
        local offset = position - origin
        local distance = Vector3.length(offset)
        if distance <= 0 or distance > distance_limit then return nil end

        local direction = Vector3.normalize(offset)
        local dot = Vector3.dot(camera_forward, direction)
        if not ignore_fov and dot < math.cos(math.rad(fov)) then
            return nil
        end

        local score = dot
        if not first_position then
            first_position, first_score, first_distance = position, score, distance
        end
        if has_line_of_sight(physics_world, target_unit, origin, direction, distance) then
            return position, score, true, distance
        end
    end

    local nodes = AIM_NODES[aim_location] or AIM_NODES.head
    local aim_position
    for i = 1, #nodes do
        local node_name = nodes[i]
        if Unit.has_node(target_unit, node_name) then
            aim_position = native_vector(Unit.world_position(target_unit, Unit.node(target_unit, node_name)))
            break
        end
    end
    if not aim_position then aim_position = fallback_aim_position(target_unit) end
    local position, score, visible, distance = evaluate(aim_position)
    if visible then
        return position, score, true, distance
    end
    return first_position, first_score, false, first_distance
end

local function clear_aim_lock()
    locked_target = nil
    locked_position = nil
end

local function select_aim_target(physics_world, origin, camera_forward, distance_limit, fov, dt, preferred_target)
    local current_position, current_visible
    if locked_target then
        if not HEALTH_ALIVE or not HEALTH_ALIVE[locked_target] then
            clear_aim_lock()
        else
            current_position, _, current_visible = target_metrics(
                physics_world, locked_target, origin, camera_forward,
                distance_limit, fov, true
            )
            if not current_visible then clear_aim_lock() end
        end
    end

    local best_unit, best_position, best_score, best_distance
    if not locked_target then
        if preferred_target and aim_target_map[preferred_target] then
            local position, score, visible, distance = target_metrics(
                physics_world, preferred_target, origin, camera_forward,
                distance_limit, fov, false
            )
            if visible then
                best_unit, best_position, best_score, best_distance = preferred_target, position, score, distance
            end
        end
        if not best_unit then
            for target_unit in pairs(aim_target_map) do
                local position, score, visible, distance = target_metrics(
                    physics_world, target_unit, origin, camera_forward,
                    distance_limit, fov, false
                )
                if visible and (not best_score or score > best_score or
                   score == best_score and distance < best_distance) then
                    best_unit, best_position, best_score, best_distance = target_unit, position, score, distance
                end
            end
        end
    end

    if best_unit then
        locked_target = best_unit
        locked_position = Vector3Box(best_position)
        current_position, current_visible = best_position, true
    end
    if not locked_target or not current_position then return nil end

    local position_alpha = 1 - math.exp(-18 * dt)
    local previous_x, previous_y, previous_z = Vector3.to_elements(locked_position:unbox())
    local current_x, current_y, current_z = Vector3.to_elements(current_position)
    locked_position:store(Vector3(
        previous_x + (current_x - previous_x) * position_alpha,
        previous_y + (current_y - previous_y) * position_alpha,
        previous_z + (current_z - previous_z) * position_alpha
    ))
    return locked_position:unbox()
end

local function aim_at_position(player, first_person, target_position, dt, smoothness)
    local direction = Vector3.normalize(target_position - first_person.position)
    local direction_x, direction_y, direction_z = Vector3.to_elements(direction)
    local target_yaw = math.atan2(direction_y, direction_x) - math.pi * 0.5
    local target_pitch = math.asin(math.clamp(direction_z, -1, 1))
    local orientation = player:get_orientation()
    local yaw_delta = (target_yaw - orientation.yaw + math.pi) % (math.pi * 2) - math.pi
    local pitch_delta = (target_pitch - orientation.pitch + math.pi) % (math.pi * 2) - math.pi
    local response = 2 + (100 - math.clamp(smoothness, 0, 100)) * 0.22
    local alpha = 1 - math.exp(-response * dt)
    local curve = math.clamp(aim_curve, 0, 100) * 0.0035 * alpha * (1 - alpha)
    local yaw = orientation.yaw + yaw_delta * alpha - pitch_delta * curve
    local pitch = orientation.pitch + pitch_delta * alpha + yaw_delta * curve

    player:set_orientation(yaw, pitch, 0)
end

local function repeat_semi_auto_input(parser, input_extension, inputs)
    if not enable_auto_fire or not input_extension._is_local_unit
        or parser._action_component_name ~= "weapon_action"
        or not inputs.action_one_hold
        or inputs.action_one_pressed then return end

    local weapon_template = WeaponTemplate.current_weapon_template(parser._action_component)
    local action_inputs = weapon_template and weapon_template.action_inputs
    if not action_inputs then return end

    local hip_action = action_inputs.shoot_pressed and "shoot_pressed"
        or action_inputs.shoot and "shoot"
    if not hip_action then return end
    local action = inputs.action_two_hold and action_inputs.zoom_shoot
        and "zoom_shoot" or hip_action
    local input_sequence = action_inputs[action] and action_inputs[action].input_sequence
    local press_driven = false
    for i = 1, input_sequence and #input_sequence or 0 do
        local input = input_sequence[i]
        if input.input == "action_one_pressed" and input.value == true then
            press_driven = true
            break
        end
    end
    if not press_driven then return end

    local weapon_extension = parser._config_data.action_extension
    local t = parser._last_fixed_frame * parser._fixed_time_step
    if weapon_extension and weapon_extension:action_input_is_currently_valid(
        "weapon_action", action, "action_one_pressed", t
    ) then
        inputs.action_one_pressed = true
    end
end

mod:hook("ActionInputParser", "_this_frames_inputs", function(func, self, input_extension)
    local inputs = func(self, input_extension)
    repeat_semi_auto_input(self, input_extension, inputs)
    return inputs
end)

local function suppress_local_spread(self)
    local player = Managers.player and Managers.player:local_player(1)
    return enable_no_spread and player and self._unit == player.player_unit
end

mod:hook("PlayerUnitWeaponSpreadExtension", "randomized_spread", function(
    func, self, current_rotation, ...
)
    if suppress_local_spread(self) then return current_rotation end
    return func(self, current_rotation, ...)
end)

mod:hook("PlayerUnitWeaponSpreadExtension", "target_style_spread", function(
    func, self, current_rotation, ...
)
    if suppress_local_spread(self) then return current_rotation end
    return func(self, current_rotation, ...)
end)

mod:hook(Recoil, "add_recoil", function(
    func, t, recoil_template, recoil_component, recoil_control_component,
    movement_state_component, locomotion_component, inair_state_component, fp_rotation, unit
)
    local player = Managers.player and Managers.player:local_player(1)
    if enable_no_recoil and player and unit == player.player_unit then return end
    return func(t, recoil_template, recoil_component, recoil_control_component,
        movement_state_component, locomotion_component, inair_state_component, fp_rotation, unit)
end)

mod:hook(CLASS.PlayerUnitInputExtension, "get", function(func, self, action, ...)
    if auto_whistle_input_phase and self._is_local_unit then
        if action == "grenade_ability_pressed" then return auto_whistle_input_phase == "press" end
        if action == "grenade_ability_hold" then return auto_whistle_input_phase ~= "release" end
    end
    return func(self, action, ...)
end)

mod:hook(CLASS.PlayerUnitActionInputExtension, "fixed_update", function(func, self, unit, dt, t, fixed_frame)
    local player = Managers.player and Managers.player:local_player(1)
    local target = auto_whistle_pending_target
    if not player or unit ~= player.player_unit or not target then
        return func(self, unit, dt, t, fixed_frame)
    end
    if not auto_whistle_hold_until and (not HEALTH_ALIVE or not HEALTH_ALIVE[target]) then
        auto_whistle_pending_target = nil
        return func(self, unit, dt, t, fixed_frame)
    end
    if auto_whistle_hold_until and t < auto_whistle_hold_until - 1 then
        auto_whistle_pending_target = nil
        auto_whistle_hold_until = nil
        return func(self, unit, dt, t, fixed_frame)
    end

    local phase
    if auto_whistle_hold_until then
        phase = t >= auto_whistle_hold_until and "release" or "hold"
    else
        local ability = ScriptUnit.has_extension(unit, "ability_system")
        local can_whistle = ability and ability:get_current_grenade_ability_name() == "adamant_whistle"
            and ability:can_use_ability("grenade_ability")
            and ability:action_input_is_currently_valid(
                "grenade_ability_action", "aim_pressed", "grenade_ability_pressed", t
            )
        if not can_whistle then return func(self, unit, dt, t, fixed_frame) end
        phase = "press"
    end

    auto_whistle_input_phase = phase
    local ok, err = pcall(func, self, unit, dt, t, fixed_frame)
    auto_whistle_input_phase = nil
    if not ok then error(err) end
    if phase == "press" then
        auto_whistle_hold_until = t + 0.08
    elseif phase == "release" then
        auto_whistle_pending_target = nil
        auto_whistle_used_target = target
        auto_whistle_hold_until = nil
    end
end)

mod:hook_safe("PlayerUnitFirstPersonExtension", "fixed_update", function(self, unit, dt, t, frame)
    if not dt or dt <= 0 then return end

    local player = Managers.player and Managers.player:local_player(1)
    if not player or unit ~= player.player_unit or not player:unit_is_alive() then
        clear_aim_lock()
        return
    end

    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    if not unit_data then return end

    local first_person = unit_data:read_component("first_person")
    if not first_person or not first_person.position or not first_person.rotation then return end

    local physics_world = World.physics_world(self._world)
    local visibility_origin = player_camera_position(player, first_person.position)
    update_companion_target(unit, visibility_origin, physics_world, t)

    if not activation_is_held(aim_activation, aimbot_held, self._input_extension) then
        clear_aim_lock()
        return
    end

    local camera_forward = Quaternion.forward(first_person.rotation)
    local preferred_target
    if not locked_target then
        local smart_targeting = ScriptUnit.has_extension(unit, "smart_targeting_system")
        if smart_targeting then
            if t < next_smart_target_refresh_t - 1 then next_smart_target_refresh_t = 0 end
            if t >= next_smart_target_refresh_t then
                smart_targeting:force_update_smart_tag_targets()
                next_smart_target_refresh_t = t + 0.1
            end
            local targeting_data = smart_targeting:smart_tag_targeting_data()
            preferred_target = targeting_data and targeting_data.unit
        end
    end
    local target_position = select_aim_target(
        physics_world, visibility_origin, camera_forward,
        aim_distance, aim_fov, dt, preferred_target
    )
    if not target_position then return end

    aim_at_position(player, first_person, target_position, dt, aim_smoothness)
end)

mod:hook(CLASS.MinionSpawnManager, "spawn_minion", function(func, self, ...)
    local unit = func(self, ...)
    add_esp_for_unit(unit)
    return unit
end)

mod:hook_safe("HealthExtension", "init", function(self, extension_init_context, unit)
    add_esp_for_unit(unit)
end)

mod:hook_safe("HuskHealthExtension", "init", function(self, extension_init_context, unit)
    add_esp_for_unit(unit)
end)

refresh_settings()
mod:echo("Loaded! - By @luinbytes")
