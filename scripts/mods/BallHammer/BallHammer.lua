local mod = get_mod("BallHammer")
local MarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerMarker")
local HordeMarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerHordeMarker")
local PickupMarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerPickupMarker")
local AimMarkerTemplate = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerAimMarker")
local Survival = mod:io_dofile("BallHammer/scripts/mods/BallHammer/BallHammerSurvival")
local AttackSettings = require("scripts/settings/damage/attack_settings")
local Recoil = require("scripts/utilities/recoil")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

mod:register_hud_element({
    class_name = "BallHammerThreatHud",
    filename = "BallHammer/scripts/mods/BallHammer/BallHammerThreatHud",
    use_hud_scale = true,
    visibility_groups = { "alive" },
})

local function optional_require(path)
    local ok, module = pcall(require, path)
    return ok and module or nil
end

local Action = optional_require("scripts/utilities/action/action")
local Armor = optional_require("scripts/utilities/attack/armor")
local DamageCalculation = optional_require("scripts/utilities/attack/damage_calculation")
local DamageProfile = optional_require("scripts/utilities/attack/damage_profile")
local HitZone = optional_require("scripts/utilities/attack/hit_zone")
local Weakspot = optional_require("scripts/utilities/attack/weakspot")

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
local COMPANION_RESCUE_TYPES = {
    pounced = true,
    warp_grabbed = true,
    mutant_charged = true,
    consumed = true,
    grabbed = true,
}
local HIGH_RISK_MELEE = {
    chaos_ogryn_executor = true,
    cultist_berzerker = true,
    renegade_berzerker = true,
    renegade_executor = true,
}
local RAGER_MELEE = {
    cultist_berzerker = true,
    renegade_berzerker = true,
}
local CRUSHER_MELEE = { chaos_ogryn_executor = true }
local MAULER_MELEE = { renegade_executor = true }

-- State
local unit_data_map       = {}
local active_markers      = {}
local horde_unit_data     = {}
local horde_active_markers = {}
local pickup_unit_data     = {}
local pickup_active_markers = {}
local aim_target_map      = {}
local outline_system      = nil
local markers_ready       = false
local outline_check_timer = 0
local marker_retry_frames = 0
local marker_watchdog_tick = 0
local marker_requested_at = {}
local horde_marker_requested_at = {}
local pickup_marker_requested_at = {}

mod.enabled        = true
mod.active_markers = active_markers
mod.horde_unit_data = horde_unit_data
mod.horde_active_markers = horde_active_markers
mod.pickup_active_markers = pickup_active_markers

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
local pickup_marker_refs = {}
mod.pickup_marker_refs = pickup_marker_refs

local enable_outlines   = true
local enable_nameplates = true
local enable_horde_esp  = true
local enable_pickup_esp = true
local max_distance      = 80
local horde_distance    = 80
local pickup_distance   = 80
local pickup_filter     = "all"
local PICKUP_FILTER_IDS = {
    "plasteel", "diamantine", "ammo", "ammo_crate", "grenade", "medkit", "med_stimm",
    "concentration_stimm", "combat_stimm", "celerity_stimm", "grimoire", "scripture", "other",
}
local pickup_custom = {}
for i = 1, #PICKUP_FILTER_IDS do pickup_custom[PICKUP_FILTER_IDS[i]] = true end
local outline_distance  = 30
local aimbot_held       = false
local aim_distance      = 80
local aim_fov           = 30
local aim_smoothness    = 55
local aim_curve         = 20
local aim_location      = "head"
local aim_activation    = "left_mouse"
local show_aim_fov      = true
local aim_fov_opacity   = 60
local aim_fov_red       = 255
local aim_fov_green     = 158
local aim_fov_blue      = 181
local triggerbot_held   = false
local rage_held         = false
local trigger_activation = "off"
local trigger_fov        = 5
local trigger_fire_fov   = 0.8
local trigger_smoothness = 35
local rage_distance      = 120
local rage_smoothness    = 10
local enable_auto_fire  = true
local enable_no_recoil  = false
local enable_no_spread  = false
local locked_target      = nil
local locked_position    = nil
local locked_mode        = nil
local aim_preview_target = nil
local aim_preview_position = nil
local aim_preview_radius = nil
local requested_auto_fire_mode = nil
local requested_auto_fire_until = nil
local physical_action_one_hold = nil
local enable_companion_target = true
local companion_distance = 60
local enable_auto_whistle = false
local enable_aim_director = true
local enable_threat_markers = true
local enable_threat_reactions = false
local reaction_timing = 50
local emergency_override = false
local enable_survival_debug = false
local enable_guard_brain = false
local stamina_reserve = 0.25
local enable_resource_governor = false
local enable_auto_vent = false
local peril_target = 0.9
local heat_target = 0.9
local companion_target = nil
local companion_next_scan_t = 0
local companion_waiting_for_damage = false
local companion_wait_deadline_t = 0
local companion_attackers = {}
local auto_whistle_pending_target = nil
local auto_whistle_used_target = nil
local auto_whistle_hold_until = nil
local next_smart_target_refresh_t = 0
local active_threat = nil
local requested_defense = nil
local requested_vent = nil
local survival_t = 0
local survival_warning = {}
local threat_seen_at = setmetatable({}, { __mode = "k" })
local resource_history = {}
local director_score_cache = setmetatable({}, { __mode = "k" })
local governor_suppress_fire = false

local function warn_once(key, message)
    if survival_warning[key] then return end
    survival_warning[key] = true
    mod:echo("BallHammer " .. message)
end

local function debug_survival(message)
    if enable_survival_debug and mod.info then mod:info("[Survival] " .. message) end
end

mod.get_unit_data         = function(unit) return unit_data_map[unit] end
mod.get_aim_preview       = function()
    return aim_preview_target, aim_preview_position, aim_preview_radius
end
mod.get_aim_marker_style  = function()
    return show_aim_fov, aim_fov_opacity, aim_fov_red, aim_fov_green, aim_fov_blue
end
mod.get_threat_indicator = function()
    if not enable_threat_markers or not active_threat then return nil end
    local action = active_threat.action or active_threat.kind
    local remaining = math.max(active_threat.impact_t - survival_t, 0)
    return string.format("%s %.1f", string.upper(action), remaining)
end
mod.get_enable_nameplates = function() return enable_nameplates end
mod.get_max_distance      = function() return max_distance end
mod.get_enable_horde_esp  = function() return enable_horde_esp end
mod.get_horde_distance    = function() return horde_distance end
mod.get_aim_location      = function() return aim_location end
mod.get_pickup_data       = function(unit) return pickup_unit_data[unit] end
mod.get_enable_pickup_esp = function() return enable_pickup_esp end
mod.get_pickup_distance   = function() return pickup_distance end
mod.get_pickup_visible    = function(data)
    return pickup_filter == "all" or data and (pickup_filter == "custom"
        and pickup_custom[data.filter_id] == true or data.category == pickup_filter)
end

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
    enable_pickup_esp = mod:get("enable_pickup_esp")
    max_distance      = mod:get("max_distance")
    horde_distance    = mod:get("horde_distance")
    pickup_distance   = mod:get("pickup_distance")
    pickup_filter     = mod:get("pickup_filter") or "all"
    for i = 1, #PICKUP_FILTER_IDS do
        local id = PICKUP_FILTER_IDS[i]
        pickup_custom[id] = mod:get("pickup_show_" .. id) ~= false
    end
    outline_distance  = mod:get("outline_distance")
    aim_distance      = mod:get("aim_distance")
    aim_fov           = mod:get("aim_fov")
    aim_smoothness    = mod:get("aim_smoothness")
    aim_curve         = mod:get("aim_curve")
    aim_location      = mod:get("aim_location")
    aim_activation    = mod:get("aim_activation")
    show_aim_fov      = mod:get("show_aim_fov")
    aim_fov_opacity   = mod:get("aim_fov_opacity")
    aim_fov_red       = mod:get("aim_fov_red")
    aim_fov_green     = mod:get("aim_fov_green")
    aim_fov_blue      = mod:get("aim_fov_blue")
    trigger_activation = mod:get("trigger_activation")
    trigger_fov        = mod:get("trigger_fov")
    trigger_fire_fov   = mod:get("trigger_fire_fov")
    trigger_smoothness = mod:get("trigger_smoothness")
    rage_distance      = mod:get("rage_distance")
    rage_smoothness    = mod:get("rage_smoothness")
    enable_auto_fire  = mod:get("enable_auto_fire")
    enable_no_recoil  = mod:get("enable_no_recoil")
    enable_no_spread  = mod:get("enable_no_spread")
    enable_companion_target = mod:get("enable_companion_target")
    companion_distance = mod:get("companion_distance")
    enable_auto_whistle = mod:get("enable_auto_whistle")
    enable_aim_director = mod:get("enable_aim_director")
    enable_threat_markers = mod:get("enable_threat_markers")
    enable_threat_reactions = mod:get("enable_threat_reactions")
    reaction_timing = mod:get("reaction_timing")
    emergency_override = mod:get("emergency_override")
    enable_survival_debug = mod:get("enable_survival_debug")
    enable_guard_brain = mod:get("enable_guard_brain")
    stamina_reserve = mod:get("stamina_reserve") / 100
    enable_resource_governor = mod:get("enable_resource_governor")
    enable_auto_vent = mod:get("enable_auto_vent")
    peril_target = mod:get("peril_target") / 100
    heat_target = mod:get("heat_target") / 100
    refresh_marker_aim_node()
end

local function activation_is_held(activation, custom_held, input_extension)
    if activation == "custom" then return custom_held end
    if not input_extension then return false end
    local left_held = physical_action_one_hold
    if left_held == nil then left_held = input_extension:get("action_one_hold") end
    if activation == "left_mouse" then return left_held end
    if activation == "right_mouse" then return input_extension:get("action_two_hold") end
    if activation == "both_mouse" then
        return left_held or input_extension:get("action_two_hold")
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

local function kill_pickup_marker(unit)
    local marker = pickup_marker_refs[unit]
    if marker then
        marker.remove = true
        pickup_marker_refs[unit] = nil
    end
    pickup_active_markers[unit] = nil
    pickup_marker_requested_at[unit] = nil
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

local function add_pickup_marker(unit)
    if not markers_ready or pickup_active_markers[unit] then return end
    pickup_active_markers[unit] = true
    pickup_marker_requested_at[unit] = marker_watchdog_tick
    Managers.event:trigger(
        "add_world_marker_unit", PickupMarkerTemplate.name, unit, nil, pickup_unit_data[unit]
    )
end

local function add_aim_marker()
    if not markers_ready or mod.aim_marker_ref then return end
    Managers.event:trigger(
        "add_world_marker_position", AimMarkerTemplate.name, Vector3(0, 0, 0)
    )
end

local function attach_world_markers(world_markers)
    if not world_markers or not world_markers._marker_templates then return false end
    world_markers._marker_templates[MarkerTemplate.name] = MarkerTemplate
    world_markers._marker_templates[HordeMarkerTemplate.name] = HordeMarkerTemplate
    world_markers._marker_templates[PickupMarkerTemplate.name] = PickupMarkerTemplate
    world_markers._marker_templates[AimMarkerTemplate.name] = AimMarkerTemplate
    markers_ready = true
    table.clear(active_markers)
    table.clear(marker_refs)
    table.clear(horde_active_markers)
    table.clear(horde_marker_refs)
    table.clear(pickup_active_markers)
    table.clear(pickup_marker_refs)
    mod.aim_marker_ref = nil
    add_aim_marker()
    if mod.enabled and (enable_nameplates or enable_horde_esp or enable_pickup_esp) then
        marker_retry_frames = 10
    end
    return true
end

local function attach_live_world_markers()
    local hud = Managers.ui and Managers.ui:get_hud()
    local world_markers = hud and hud:element("HudElementWorldMarkers")
    return attach_world_markers(world_markers)
end

local PICKUP_STYLES = {
    small_metal = { name = "Plasteel", category = "materials", filter_id = "plasteel", color = { 255, 70, 220, 255 } },
    large_metal = { name = "Plasteel", category = "materials", filter_id = "plasteel", color = { 255, 70, 220, 255 } },
    small_platinum = { name = "Diamantine", category = "materials", filter_id = "diamantine", color = { 255, 190, 100, 255 } },
    large_platinum = { name = "Diamantine", category = "materials", filter_id = "diamantine", color = { 255, 190, 100, 255 } },
    small_clip = { name = "Ammo", category = "supplies", filter_id = "ammo", color = { 255, 255, 210, 70 } },
    large_clip = { name = "Ammo", category = "supplies", filter_id = "ammo", color = { 255, 255, 210, 70 } },
    large_ammunition_crate = { name = "Ammo Crate", category = "supplies", filter_id = "ammo_crate", color = { 255, 255, 180, 40 } },
    small_grenade = { name = "Grenade", category = "supplies", filter_id = "grenade", color = { 255, 255, 145, 55 } },
    medical_crate_pocketable = { name = "Medkit", category = "supplies", filter_id = "medkit", color = { 255, 80, 235, 120 } },
    ammo_cache_pocketable = { name = "Ammo Crate", category = "supplies", filter_id = "ammo_crate", color = { 255, 255, 180, 40 } },
    syringe_corruption_pocketable = { name = "Med Stimm", category = "stimms", filter_id = "med_stimm", color = { 255, 70, 220, 80 } },
    syringe_ability_boost_pocketable = { name = "Concentration Stimm", category = "stimms", filter_id = "concentration_stimm", color = { 255, 240, 195, 50 } },
    syringe_power_boost_pocketable = { name = "Combat Stimm", category = "stimms", filter_id = "combat_stimm", color = { 255, 240, 75, 55 } },
    syringe_speed_boost_pocketable = { name = "Celerity Stimm", category = "stimms", filter_id = "celerity_stimm", color = { 255, 40, 170, 255 } },
    grimoire = { name = "Grimoire", category = "mission", filter_id = "grimoire", color = { 255, 110, 255, 110 } },
    tome = { name = "Scripture", category = "mission", filter_id = "scripture", color = { 255, 110, 210, 255 } },
}

local function pickup_style(pickup_name)
    local style = PICKUP_STYLES[pickup_name]
    if style then
        return {
            name = style.name,
            category = style.category,
            filter_id = style.filter_id,
            color = { style.color[1], style.color[2], style.color[3], style.color[4] },
        }
    end
    local name, category, filter_id, color
    if pickup_name:find("syringe") then
        name, category, filter_id, color = "Stimm", "stimms", "other", { 255, 255, 100, 180 }
    elseif pickup_name:find("grenade") then
        name, category, filter_id, color = "Grenade", "supplies", "grenade", { 255, 255, 145, 55 }
    elseif pickup_name:find("ammo") or pickup_name:find("ammunition") then
        name, category, filter_id, color = "Ammo", "supplies", "ammo", { 255, 255, 210, 70 }
    elseif pickup_name:find("medical") or pickup_name:find("health") then
        name, category, filter_id, color = "Medical", "supplies", "medkit", { 255, 80, 235, 120 }
    elseif pickup_name:find("grimoire") then
        name, category, filter_id, color = "Grimoire", "mission", "grimoire", { 255, 110, 255, 110 }
    elseif pickup_name:find("tome") then
        name, category, filter_id, color = "Scripture", "mission", "scripture", { 255, 110, 210, 255 }
    else
        name, category, filter_id, color = breed_label(pickup_name:gsub("_pickup.*$", "")), "supplies", "other",
            { 255, 210, 220, 235 }
    end
    return { name = name, category = category, filter_id = filter_id, color = color }
end

local function pickup_is_socketed(unit)
    local extension_manager = Managers.state and Managers.state.extension
    local socket_system = extension_manager and extension_manager:system("luggable_socket_system")
    local socket_units = socket_system and socket_system:socket_units()
    for i = 1, socket_units and #socket_units or 0 do
        local socket = ScriptUnit.has_extension(socket_units[i], "luggable_socket_system")
        if socket and socket:socketed_unit() == unit then return true end
    end
    return false
end

local function add_pickup_esp(unit)
    if pickup_unit_data[unit] then return end
    local pickup_name = Unit.get_data(unit, "pickup_type")
    if not pickup_name or pickup_is_socketed(unit) then return end
    pickup_unit_data[unit] = pickup_style(pickup_name)
    if mod.enabled and enable_pickup_esp then add_pickup_marker(unit) end
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
        breed_name = breed.name,
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
        for unit in pairs(pickup_unit_data) do kill_pickup_marker(unit) end
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
        if enable_pickup_esp then
            for unit in pairs(pickup_unit_data) do
                if ALIVE and ALIVE[unit] then add_pickup_marker(unit) end
            end
        end
    end
end

mod.aimbot_held = function(held)
    aimbot_held = held
end

mod.triggerbot_held = function(held)
    triggerbot_held = held
    if not held and requested_auto_fire_mode == "trigger" then
        requested_auto_fire_mode = nil
        requested_auto_fire_until = nil
    end
end

mod.rage_held = function(held)
    rage_held = held
    if not held and requested_auto_fire_mode == "rage" then
        requested_auto_fire_mode = nil
        requested_auto_fire_until = nil
    end
end

mod.on_setting_changed = function(setting_id)
    mod:echo("setting_changed: " .. tostring(setting_id))
    if not setting_id then return end

    if setting_id == "aim_distance" or setting_id == "aim_fov" or setting_id == "aim_smoothness" or
       setting_id == "aim_curve" or setting_id == "aim_location" or setting_id == "aim_activation"
       or setting_id == "show_aim_fov" or setting_id == "aim_fov_opacity"
       or setting_id == "aim_fov_red" or setting_id == "aim_fov_green"
       or setting_id == "aim_fov_blue" then
        refresh_settings()
        return
    end

    if setting_id == "trigger_activation" or setting_id == "trigger_fov"
        or setting_id == "trigger_fire_fov" or setting_id == "trigger_smoothness"
        or setting_id == "rage_distance" or setting_id == "rage_smoothness" then
        refresh_settings()
        return
    end

    if setting_id == "enable_aim_director" or setting_id == "enable_threat_markers"
        or setting_id == "enable_threat_reactions" or setting_id == "reaction_timing"
        or setting_id == "emergency_override" or setting_id == "enable_survival_debug"
        or setting_id == "enable_guard_brain" or setting_id == "stamina_reserve"
        or setting_id == "enable_resource_governor"
        or setting_id == "enable_auto_vent" or setting_id == "peril_target"
        or setting_id == "heat_target" then
        refresh_settings()
        if not enable_threat_markers and active_threat and active_threat.source then
            local data = unit_data_map[active_threat.source]
            if data then data.threat_text = nil end
        end
        if not enable_threat_reactions and not enable_guard_brain then requested_defense = nil end
        if not enable_resource_governor then
            governor_suppress_fire = false
            requested_vent = nil
        end
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

    if setting_id == "enable_pickup_esp" then
        enable_pickup_esp = mod:get("enable_pickup_esp")
        if enable_pickup_esp and mod.enabled then
            for unit in pairs(pickup_unit_data) do
                if ALIVE and ALIVE[unit] then add_pickup_marker(unit) end
            end
        else
            for unit in pairs(pickup_unit_data) do kill_pickup_marker(unit) end
        end
        return
    end

    if setting_id == "pickup_distance" then
        pickup_distance = mod:get("pickup_distance")
        return
    end

    if setting_id == "pickup_filter" or setting_id and setting_id:find("^pickup_show_") then
        pickup_filter = mod:get("pickup_filter") or "all"
        for i = 1, #PICKUP_FILTER_IDS do
            local id = PICKUP_FILTER_IDS[i]
            pickup_custom[id] = mod:get("pickup_show_" .. id) ~= false
        end
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
    attach_world_markers(self)
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
        if mod.enabled and enable_pickup_esp then
            for unit in pairs(pickup_unit_data) do
                if ALIVE and ALIVE[unit] and not pickup_active_markers[unit] then
                    add_pickup_marker(unit)
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
    outline_system = extension_manager and extension_manager:system("outline_system") or nil
    local minions = extension_manager and extension_manager:get_entities("MinionUnitDataExtension")
    for unit in pairs(minions or {}) do
        if HEALTH_ALIVE[unit] and not unit_data_map[unit] and not horde_unit_data[unit] then
            add_esp_for_unit(unit)
        end
    end
    local interactees = extension_manager and extension_manager:get_entities("InteracteeExtension")
    for unit in pairs(interactees or {}) do
        if ALIVE[unit] and not pickup_unit_data[unit] then add_pickup_esp(unit) end
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
    for unit in pairs(pickup_active_markers) do
        local marker = pickup_marker_refs[unit]
        local requested_at = pickup_marker_requested_at[unit] or marker_watchdog_tick
        if ALIVE[unit] and marker and marker.remove then
            pickup_marker_refs[unit] = nil
            pickup_active_markers[unit] = nil
            pickup_marker_requested_at[unit] = nil
        elseif ALIVE[unit] and not marker and marker_watchdog_tick - requested_at >= 2 then
            pickup_active_markers[unit] = nil
            pickup_marker_requested_at[unit] = nil
        end
    end
    if mod.enabled and enable_horde_esp then
        for unit in pairs(horde_unit_data) do
            if HEALTH_ALIVE[unit] and not horde_active_markers[unit] then add_horde_marker(unit) end
        end
    end
    for unit in pairs(pickup_unit_data) do
        if not ALIVE[unit] then
            kill_pickup_marker(unit)
            pickup_unit_data[unit] = nil
        elseif pickup_is_socketed(unit) then
            kill_pickup_marker(unit)
            pickup_unit_data[unit] = nil
        elseif mod.enabled and enable_pickup_esp and not pickup_active_markers[unit] then
            add_pickup_marker(unit)
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
        if actor then
            if Actor.unit(actor) ~= target_unit then return false end
            if HitZone then
                local ok, name = pcall(HitZone.get_name, target_unit, actor)
                if ok and (name == "shield" or name == "captain_void_shield") then
                    return false
                end
            end
        end
    end

    return true
end

local function aim_zone_scale(distance)
    if distance <= 4 then return 1.25 end
    if distance >= 80 then return 0.45 end
    return 1.25 + (distance - 4) / 76 * (0.45 - 1.25)
end

local function effective_aim_fov(fov, distance)
    local bounded_fov = math.clamp(fov, 0.1, 89)
    return math.deg(math.atan(math.tan(math.rad(bounded_fov)) * aim_zone_scale(distance)))
end

local function aim_zone_radius(fov, distance)
    local resolution = RESOLUTION_LOOKUP or {}
    local screen_height = resolution.height or 1080
    local vertical_fov = math.rad(65)
    local player = Managers.player and Managers.player:local_player(1)
    local camera_manager = Managers.state and Managers.state.camera
    if player and camera_manager and camera_manager.fov then
        local ok, current_fov = pcall(camera_manager.fov, camera_manager, player.viewport_name)
        if ok and current_fov then vertical_fov = current_fov end
    end
    local focal_length = screen_height * 0.5 / math.tan(vertical_fov * 0.5)
    return focal_length * math.tan(math.rad(effective_aim_fov(fov, distance)))
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

local function order_companion_target(player_unit, spawner, target, t, wait_time)
    local extension_manager = Managers.state and Managers.state.extension
    local smart_tag_system = extension_manager and extension_manager:system("smart_tag_system")
    if not smart_tag_system then return false end

    smart_tag_system:set_contextual_unit_tag(player_unit, target, "companion_order")
    table.clear(companion_attackers)
    local companions = spawner:companion_units()
    for i = 1, companions and #companions or 0 do
        companion_attackers[companions[i]] = true
    end
    companion_waiting_for_damage = true
    companion_wait_deadline_t = t + wait_time
    companion_target = target
    return true
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
    local spawner = ScriptUnit.has_extension(player_unit, "companion_spawner_system")
    if not spawner or not spawner:companion_can_tag_order() then
        companion_target = nil
        companion_waiting_for_damage = false
        companion_wait_deadline_t = 0
        table.clear(companion_attackers)
        return
    end

    local player_unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
    local disabled_state = player_unit_data and player_unit_data:read_component("disabled_character_state")
    local disabling_unit = disabled_state and disabled_state.is_disabled
        and COMPANION_RESCUE_TYPES[disabled_state.disabling_type]
        and disabled_state.disabling_unit
    if disabling_unit and HEALTH_ALIVE and HEALTH_ALIVE[disabling_unit] then
        if disabling_unit ~= companion_target then
            order_companion_target(player_unit, spawner, disabling_unit, t, 3)
        end
        return
    end

    if t < companion_next_scan_t then return end
    companion_next_scan_t = t + 0.35

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
        if not order_companion_target(player_unit, spawner, chosen, t, chosen_wait) then
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

local function is_local_companion_attack(attacking_unit, attack_type)
    if companion_attackers[attacking_unit] then return true end
    if attack_type ~= AttackSettings.attack_types.companion_dog then return false end

    local spawn_manager = Managers.state and Managers.state.player_unit_spawn
    local player = Managers.player and Managers.player:local_player(1)
    if not spawn_manager or not player then return false end

    local ok, owner = pcall(spawn_manager.owner, spawn_manager, attacking_unit)
    return ok and (owner == player
        or type(owner) == "table" and owner.player_unit == player.player_unit)
end

local function update_auto_whistle_from_companion_state(player_unit)
    if not enable_auto_whistle or not companion_target or not BLACKBOARDS then return end

    local spawner = ScriptUnit.has_extension(player_unit, "companion_spawner_system")
    local companions = spawner and spawner:companion_units()
    for i = 1, companions and #companions or 0 do
        local companion_unit = companions[i]
        local blackboard = BLACKBOARDS[companion_unit]
        local pounce = blackboard and blackboard.pounce
        local behavior = blackboard and blackboard.behavior
        local attack_landed = pounce and (pounce.has_pounce_started
            or (pounce.has_pounce_target and behavior and behavior.move_state == "attacking"))
        if attack_landed and pounce.pounce_target == companion_target then
            queue_auto_whistle(companion_target)
            return
        end
    end
end

mod:hook_safe("AttackReportManager", "add_attack_result", function(
    self, damage_profile, attacked_unit, attacking_unit, attack_direction,
    hit_world_position, hit_weakspot, damage, attack_result, attack_type
)
    if attacked_unit == companion_target
        and is_local_companion_attack(attacking_unit, attack_type) then
        queue_auto_whistle(attacked_unit)
        if damage and damage > 0 and companion_waiting_for_damage then
            companion_waiting_for_damage = false
            companion_wait_deadline_t = 0
            companion_next_scan_t = 0
        end
    end
end)

local function danger_score(unit)
    local data = unit_data_map[unit]
    if data then return data.companion_danger or 0.75 end
    local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
    local breed = unit_data and unit_data:breed()
    local tags = breed and breed.tags or {}
    if tags.monster or tags.captain or tags.cultist_captain then return 1 end
    if tags.special then return 0.9 end
    if tags.elite then return 0.75 end
    if breed and breed.smart_tag_target_type == "breed" then return 0.65 end
    return 0.2
end

local function current_damage_profile(player_unit)
    if not Action or not DamageProfile then return nil end
    local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
    local weapon_action = unit_data and unit_data:read_component("weapon_action")
    local weapon_template = weapon_action and WeaponTemplate.current_weapon_template(weapon_action)
    if not weapon_template or not weapon_template.actions then return nil end

    local profile
    local action_names = {
        weapon_action.current_action_name,
        "action_shoot_zoomed",
        "action_shoot",
        "action_shoot_hip",
        weapon_template.entry_actions and weapon_template.entry_actions.primary_action,
    }
    for i = 1, 5 do
        local settings = action_names[i] and weapon_template.actions[action_names[i]]
        if settings then
            local ok, value = pcall(Action.damage_template, settings)
            if ok and type(value) == "table" then
                profile = value
                break
            end
        end
    end
    if not profile then return nil end
    local ok, lerp_values = pcall(DamageProfile.lerp_values, profile, player_unit, 1)
    if not ok or not lerp_values then return nil end
    return profile, lerp_values
end

local function melee_aim_reach(unit_data)
    if not physical_action_one_hold then return nil end
    local inventory = unit_data:read_component("inventory")
    if not inventory or inventory.wielded_slot ~= "slot_primary" then return nil end
    local action = unit_data:read_component("weapon_action")
    local template = action and WeaponTemplate.current_weapon_template(action)
    local settings = template and template.actions and template.actions[action.current_action_name]
    local box = settings and settings.weapon_box or template and template.weapon_box
    if not box then return 4 end
    local range = math.max(box[1] or 0, box[2] or 0, box[3] or 0)
    return range * (settings and settings.range_mod or 1) + 1.5
end

local function director_candidates(target_unit)
    if not enable_aim_director then return nil, false end
    if not Armor or not DamageCalculation or not DamageProfile or not HitZone or not Weakspot then
        warn_once("director", "Armor Director disabled: a required game utility is unavailable")
        return nil, false
    end
    local player = Managers.player and Managers.player:local_player(1)
    local player_unit = player and player.player_unit
    if not player_unit then return nil, false end
    local profile, lerp_values = current_damage_profile(player_unit)
    if not profile then return nil, false end
    local unit_data = ScriptUnit.has_extension(target_unit, "unit_data_system")
    local breed = unit_data and unit_data:breed()
    if not breed or not breed.hit_zones then return nil, false end
    local ok, target_settings = pcall(DamageProfile.target_settings, profile, 1)
    if not ok or not target_settings then return nil, false end

    local cached = director_score_cache[target_unit]
    local candidates = cached and cached.profile == profile and survival_t < cached.expires_t
        and cached.candidates
    if not candidates then
        candidates = {}
        local seen = {}
        for i = 1, #breed.hit_zones do
            local name = breed.hit_zones[i].name
            if name and name ~= "center_mass" and name ~= "shield"
                and name ~= "captain_void_shield" and not seen[name] then
                seen[name] = true
                local armor_ok, armor_type = pcall(Armor.armor_type, target_unit, breed, name)
                local weakspot_ok, weakspot, shield = pcall(
                    Weakspot.hit_weakspot, breed, name, player_unit
                )
                local modifier_ok, armor_modifier = false, nil
                if armor_ok then
                    modifier_ok, armor_modifier = pcall(
                        DamageProfile.armor_damage_modifier,
                        "attack", profile, target_settings, lerp_values, armor_type,
                        false, 0, false, nil
                    )
                end
                local finesse = 1
                if modifier_ok and weakspot_ok and weakspot then
                    local finesse_ok, value = pcall(
                        DamageCalculation.ui_finesse_multiplier,
                        profile, target_settings, armor_type, true, false, lerp_values
                    )
                    if finesse_ok and value then finesse = value end
                end
                if modifier_ok and type(armor_modifier) == "number" and armor_modifier > 0
                    and not shield then
                    candidates[#candidates + 1] = {
                        name = name,
                        armor_modifier = armor_modifier,
                        weakspot_modifier = finesse,
                    }
                end
            end
        end
        table.sort(candidates, function(a, b)
            if a.armor_modifier ~= b.armor_modifier then
                return a.armor_modifier > b.armor_modifier
            end
            return a.weakspot_modifier > b.weakspot_modifier
        end)
        director_score_cache[target_unit] = {
            profile = profile,
            candidates = candidates,
            expires_t = survival_t + 0.1,
        }
    end
    local positioned = {}
    for i = 1, #candidates do
        local candidate = candidates[i]
        local position_ok, position = pcall(
            HitZone.hit_zone_center_of_mass, target_unit, candidate.name, true
        )
        if position_ok and position then
            positioned[#positioned + 1] = {
                name = candidate.name,
                position = native_vector(position),
                armor_modifier = candidate.armor_modifier,
                weakspot_modifier = candidate.weakspot_modifier,
            }
        end
    end
    return positioned, #positioned > 0
end

local function target_metrics(
    physics_world, target_unit, origin, camera_forward,
    distance_limit, fov, ignore_fov, mode, on_screen
)
    if not HEALTH_ALIVE or not HEALTH_ALIVE[target_unit] then return nil end
    local first_position, first_score, first_distance

    local function within_fov(position, distance)
        if ignore_fov then return true end
        local direction = Vector3.normalize(position - origin)
        return Vector3.dot(camera_forward, direction)
            >= math.cos(math.rad(effective_aim_fov(fov, distance)))
    end

    local function evaluate(position, defer_fov)
        if not position then return nil end
        local offset = position - origin
        local distance = Vector3.length(offset)
        if distance <= 0 or distance > distance_limit then return nil end

        local direction = Vector3.normalize(offset)
        local dot = Vector3.dot(camera_forward, direction)
        if (mode == "rage" or mode == "preview")
            and (dot <= 0 or not on_screen or not on_screen(position)) then
            return nil
        end
        if not defer_fov and not within_fov(position, distance) then
            return nil
        end

        local range_score = 1 - distance / distance_limit
        local score = mode == "rage"
            and danger_score(target_unit) * 0.5 + math.max(dot, 0) * 0.3 + range_score * 0.2
            or dot + range_score * 0.001
        if not first_position then
            first_position, first_score, first_distance = position, score, distance
        end
        if has_line_of_sight(physics_world, target_unit, origin, direction, distance) then
            return position, score, true, distance
        end
    end

    local candidates, director_handled = director_candidates(target_unit)
    for i = 1, candidates and #candidates or 0 do
        local position, score, visible, distance = evaluate(candidates[i].position, true)
        if visible then
            if within_fov(position, distance) then return position, score, true, distance end
            return nil
        end
    end
    if director_handled then return nil, nil, "immune" end

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
    locked_mode = nil
end

local function set_aim_preview(target, position, mode, distance)
    aim_preview_target = target
    aim_preview_position = position
    local fov = mode == "trigger" and trigger_fov or aim_fov
    aim_preview_radius = target and position and mode ~= "rage" and distance
        and aim_zone_radius(fov, distance) or nil
    local marker = mod.aim_marker_ref
    if marker and marker.world_position and position then
        marker.world_position:store(position)
    end
end

local function select_aim_target(
    physics_world, origin, camera_forward, distance_limit, fov, dt,
    preferred_target, mode, on_screen
)
    mode = mode or "aim"
    if locked_mode and locked_mode ~= mode then clear_aim_lock() end
    local current_position, current_score, current_visible, current_distance
    if locked_target then
        if not HEALTH_ALIVE or not HEALTH_ALIVE[locked_target] then
            clear_aim_lock()
        else
            current_position, current_score, current_visible, current_distance = target_metrics(
                physics_world, locked_target, origin, camera_forward,
                distance_limit, fov, mode == "rage" or mode == "preview", mode, on_screen
            )
            if current_visible ~= true then clear_aim_lock() end
        end
    end

    local best_unit, best_position, best_score, best_distance
    if not locked_target then
        if mode == "aim" and preferred_target and aim_target_map[preferred_target] then
            local position, score, visible, distance = target_metrics(
                physics_world, preferred_target, origin, camera_forward,
                distance_limit, fov, false, mode, on_screen
            )
            if visible == true then
                best_unit, best_position, best_score, best_distance = preferred_target, position, score, distance
            end
        end
        if not best_unit then
            for target_unit in pairs(aim_target_map) do
                local position, score, visible, distance = target_metrics(
                    physics_world, target_unit, origin, camera_forward,
                    distance_limit, fov, mode == "rage" or mode == "preview", mode, on_screen
                )
                if visible == true and (not best_score or score > best_score or
                   score == best_score and distance < best_distance) then
                    best_unit, best_position, best_score, best_distance = target_unit, position, score, distance
                end
            end
        end
    end

    if best_unit and not locked_target then
        locked_target = best_unit
        locked_mode = mode
        locked_position = Vector3Box(best_position)
        current_position, current_visible, current_distance = best_position, true, best_distance
    end
    if not locked_target or not current_position then return nil end

    locked_position:store(current_position)
    return locked_position:unbox(), current_visible, locked_target, current_distance
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
    return math.deg(math.sqrt(yaw_delta * yaw_delta + pitch_delta * pitch_delta))
end

local function local_player_unit()
    local player = Managers.player and Managers.player:local_player(1)
    return player and player.player_unit
end

local function replicated_field(unit, field)
    local game_session_manager = Managers.state and Managers.state.game_session
    local unit_spawner = Managers.state and Managers.state.unit_spawner
    local game_session = game_session_manager and game_session_manager.game_session
        and game_session_manager:game_session()
    local id_ok, game_object_id
    if unit_spawner then
        id_ok, game_object_id = pcall(
            unit_spawner.game_object_id, unit_spawner, unit
        )
    end
    if not game_session or not game_object_id or not GameSession
        or not id_ok then
        return nil
    end
    local has_ok, has_field = pcall(
        GameSession.has_game_object_field, game_session, game_object_id, field
    )
    if not has_ok or not has_field then return nil end
    local read_ok, value = pcall(
        GameSession.game_object_field, game_session, game_object_id, field
    )
    return read_ok and value or nil
end

local function replicated_target(unit)
    local target_id = replicated_field(unit, "target_unit_id")
    local unit_spawner = Managers.state and Managers.state.unit_spawner
    return target_id and unit_spawner and unit_spawner:unit(target_id) or nil
end

local function threat_target(scratchpad, blackboard)
    local perception = scratchpad and scratchpad.perception_component
        or blackboard and blackboard.perception
    return perception and perception.target_unit
end

local function set_threat_marker(threat, text)
    local data = threat and threat.source and unit_data_map[threat.source]
    if data then data.threat_text = enable_threat_markers and text or nil end
end

local function clear_active_threat()
    set_threat_marker(active_threat, nil)
    active_threat = nil
end

local function register_threat(
    kind, source, target, category, commit_t, impact_t, danger_position, phase,
    exact_reaction_t
)
    local player_unit = local_player_unit()
    if not source or target ~= player_unit then return end
    commit_t = commit_t or survival_t
    impact_t = math.max(impact_t or commit_t, commit_t)
    if active_threat and commit_t > active_threat.impact_t + 0.05 then clear_active_threat() end
    local previous_t = threat_seen_at[source]
    if previous_t and commit_t - previous_t < 0.2 then return end
    threat_seen_at[source] = commit_t
    if exact_reaction_t and active_threat and active_threat.source == source
        and active_threat.kind == kind and active_threat.reacted
        and impact_t > active_threat.impact_t + 0.1 then
        clear_active_threat()
    end
    if active_threat and active_threat.source == source and active_threat.kind == kind then
        active_threat.impact_t = math.min(active_threat.impact_t, impact_t)
        active_threat.phase = phase or active_threat.phase
        if danger_position then
            active_threat.danger_position = Vector3Box(native_vector(danger_position))
        end
        if not active_threat.reacted then
            active_threat.reaction_t = exact_reaction_t or Survival.reaction_time(
                kind, active_threat.commit_t, active_threat.impact_t, reaction_timing
            ) or commit_t
        end
        return
    end
    local candidate = {
        kind = kind,
        source = source,
        target = target,
        category = category,
        commit_t = commit_t,
        impact_t = impact_t,
        danger_position = danger_position and Vector3Box(native_vector(danger_position)),
        phase = phase or "committed",
    }
    local chosen = Survival.prefer_threat(active_threat, candidate)
    if chosen ~= active_threat then
        clear_active_threat()
        active_threat = candidate
        active_threat.reaction_t = exact_reaction_t or Survival.reaction_time(
            kind, commit_t, impact_t, reaction_timing
        ) or commit_t
        set_threat_marker(active_threat, string.upper(kind))
        local source_position = native_vector(Unit.world_position(source, 1))
        local target_position = native_vector(Unit.world_position(target, 1))
        local distance = source_position and target_position
            and Vector3.length(source_position - target_position) or -1
        debug_survival(string.format(
            "%s target=%s phase=%s commit=%.3f impact=%.3f react=%.3f distance=%.2f",
            kind, tostring(target), active_threat.phase, commit_t, impact_t,
            active_threat.reaction_t, distance
        ))
    end
end

local function current_weapon_context(player_unit)
    local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
    local inventory = unit_data and unit_data:read_component("inventory")
    local action = unit_data and unit_data:read_component("weapon_action")
    local template = action and WeaponTemplate.current_weapon_template(action)
    local action_inputs = template and template.action_inputs or {}
    return {
        unit_data = unit_data,
        inventory = inventory,
        action = action,
        template = template,
        action_inputs = action_inputs,
        can_block = inventory and inventory.wielded_slot == "slot_primary" and action_inputs.block ~= nil,
    }
end

local function defensive_move_action(threat, first_person)
    local player_position = first_person.position
    local danger_position = threat.danger_position and threat.danger_position:unbox()
        or threat.source and native_vector(Unit.world_position(threat.source, 1))
    if not danger_position then return "move_left" end
    local direction = danger_position - player_position
    local dx, dy = Vector3.to_elements(direction)
    local forward = Quaternion.forward(first_person.rotation)
    local fx, fy = Vector3.to_elements(forward)
    local side = fx * dy - fy * dx
    return side >= 0 and "move_right" or "move_left"
end

local function nearby_enemy_geometry(player_position, radius)
    local distances, quadrants = {}, {}
    for unit in pairs(aim_target_map) do
        if HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local position = native_vector(Unit.world_position(unit, 1))
            if position then
                local offset = position - player_position
                local distance = Vector3.length(offset)
                if distance <= radius then
                    distances[#distances + 1] = distance
                    local x, y = Vector3.to_elements(offset)
                    local quadrant = math.abs(x) > math.abs(y)
                        and (x >= 0 and "right" or "left")
                        or (y >= 0 and "front" or "back")
                    quadrants[quadrant] = true
                end
            end
        end
    end
    local covered = 0
    for _ in pairs(quadrants) do covered = covered + 1 end
    return distances, covered < 3
end

local function has_active_ranged_attack(player_unit)
    for unit in pairs(aim_target_map) do
        if HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local blackboard = BLACKBOARDS and BLACKBOARDS[unit]
            local perception = blackboard and blackboard.perception
            if perception and perception.target_unit == player_unit then
                local behavior = ScriptUnit.has_extension(unit, "behavior_system")
                local running_action = behavior and behavior.running_action
                local ok, action = running_action
                    and pcall(running_action, behavior)
                if ok and type(action) == "string"
                    and (action:find("shoot", 1, true) or action:find("throw", 1, true)) then
                    return true
                end
            end
        end
    end
    return false
end

local function update_resource_governor(player_unit, first_person)
    governor_suppress_fire = false
    requested_vent = nil
    if not enable_resource_governor then return end
    local context = current_weapon_context(player_unit)
    local unit_data = context.unit_data
    if not unit_data then
        warn_once("governor", "Resource Governor disabled: player unit data is unavailable")
        return
    end
    local warp = unit_data:read_component("warp_charge")
    local warp_value = warp and warp.current_percentage or 0
    local slot = context.inventory and context.inventory.wielded_slot
    local heat_config = context.template and context.template.overheat_configuration
    local slot_component = heat_config and slot and unit_data:read_component(slot)
    local heat_value = slot_component and slot_component.overheat_current_percentage or 0
    local kind, value, target, resume_margin
    if warp_value > 0 then
        kind, value, target, resume_margin = "peril", warp_value, peril_target, 0.1
    elseif heat_value > 0 then
        kind, value, target, resume_margin = "heat", heat_value, heat_target, 0.15
    else
        return
    end
    local history = resource_history[kind] or { value = value, increment = 0.02, suppressed = false }
    local increase = math.max(value - history.value, 0)
    history.increment = math.max(increase, history.increment, 0.02)
    local suppress, resumed = Survival.govern(
        value, target, history.increment, history.suppressed, resume_margin
    )
    history.value = value
    if suppress then
        history.suppressed = true
    elseif resumed then
        history.suppressed = false
    end
    resource_history[kind] = history
    governor_suppress_fire = history.suppressed

    if enable_auto_vent and value >= target and not active_threat
        and not has_active_ranged_attack(player_unit) then
        local nearby = nearby_enemy_geometry(first_person.position, 6)
        local safe = #nearby == 0
        local heat_is_safe = kind ~= "heat" or heat_config and not heat_config.vent_damage_profile
        if safe and heat_is_safe and context.action_inputs.vent then
            requested_vent = context.action_inputs.vent
        end
    end
end

local next_guard_push_t = 0
local function update_survival(player_unit, first_person, t)
    survival_t = t
    if active_threat and t > active_threat.impact_t + 0.05 then clear_active_threat() end

    for unit, data in pairs(unit_data_map) do
        local network_target = replicated_target(unit)
        if (data.breed_name == "chaos_hound" or data.breed_name == "chaos_armored_hound")
            and HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local blackboard = BLACKBOARDS and BLACKBOARDS[unit]
            local pounce = blackboard and blackboard.pounce
            if pounce and pounce.started_leap then
                local target = pounce.target_unit or pounce.pounce_target
                    or blackboard.perception and blackboard.perception.target_unit
                register_threat("hound", unit, target, "disabling", t, t + 0.35, nil, "leap")
            end
            local locomotion = ScriptUnit.has_extension(unit, "locomotion_system")
            local position = native_vector(Unit.world_position(unit, 1))
            local velocity = locomotion and locomotion.current_velocity
                and native_vector(locomotion:current_velocity())
            if network_target == player_unit and position and velocity then
                local dx, dy = Vector3.to_elements(first_person.position - position)
                local vx, vy = Vector3.to_elements(velocity)
                local impact_t = Survival.charge_impact_time(dx, dy, vx, vy, 10.5, 1, 1.5)
                if impact_t then
                    register_threat(
                        "hound", unit, player_unit, "disabling", t, t + impact_t,
                        nil, "replicated_leap"
                    )
                end
            end
        end
        if data.breed_name and data.breed_name:gsub("_mutator$", "") == "cultist_mutant"
            and HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local locomotion = ScriptUnit.has_extension(unit, "locomotion_system")
            local position = native_vector(Unit.world_position(unit, 1))
            local velocity = locomotion and locomotion.current_velocity
                and native_vector(locomotion:current_velocity())
            if position and velocity then
                local dx, dy = Vector3.to_elements(first_person.position - position)
                local vx, vy = Vector3.to_elements(velocity)
                local impact_t = Survival.charge_impact_time(dx, dy, vx, vy)
                if impact_t then
                    register_threat(
                        "mutant", unit, player_unit, "disabling", t, t + impact_t,
                        nil, "replicated_charge"
                    )
                end
            end
        end
        if (data.breed_name == "cultist_flamer" or data.breed_name == "renegade_flamer")
            and network_target == player_unit
            and HEALTH_ALIVE and HEALTH_ALIVE[unit]
            and replicated_field(unit, "state") == 3 then
            register_threat(
                "flamer", unit, player_unit, "lethal", t, t + 0.25,
                replicated_field(unit, "aim_position"), "replicated_beam"
            )
        end
    end

    local context = current_weapon_context(player_unit)
    if active_threat then
        local remaining = math.max(active_threat.impact_t - t, 0)
        active_threat.time_left = remaining
        local reaction = Survival.reaction(active_threat)
        active_threat.action = reaction
        set_threat_marker(active_threat, string.format(
            "%s %.1f", string.upper(reaction), remaining
        ))
        local reaction_enabled = (active_threat.kind == "overhead"
                or active_threat.kind == "rager")
            and enable_guard_brain
            or enable_threat_reactions
        if t >= active_threat.reaction_t and not active_threat.reacted and reaction_enabled then
            active_threat.reacted = true
            requested_defense = {
                action = reaction,
                move_action = defensive_move_action(active_threat, first_person),
                force_t = active_threat.impact_t - 0.12,
                until_t = active_threat.impact_t + 0.25,
                source = active_threat.source,
            }
            debug_survival(string.format(
                "reaction=%s kind=%s target=%s phase=%s time_left=%.3f move=%s",
                reaction, active_threat.kind, tostring(active_threat.target),
                active_threat.phase, remaining, requested_defense.move_action
            ))
        end
    end

    if enable_guard_brain and context.can_block
        and not requested_defense and t >= next_guard_push_t then
        local stamina = context.unit_data and context.unit_data:read_component("stamina")
        local distances, safe_retreat = nearby_enemy_geometry(first_person.position, 4)
        if Survival.should_push(
            distances, stamina and stamina.current_fraction or 0, stamina_reserve, safe_retreat
        ) then
            requested_defense = { action = "push", until_t = t + 0.1 }
            next_guard_push_t = t + 1
        end
    end
    update_resource_governor(player_unit, first_person)
end

mod:hook_safe("BtShootNetAction", "_start_shooting", function(self, unit, scratchpad)
    register_threat(
        "trapper", unit, threat_target(scratchpad), "disabling",
        survival_t, survival_t + 0.2, nil, "shooting"
    )
end)

mod:hook_safe("BtMutantChargerChargeAction", "_start_charging", function(
    self, unit, scratchpad, action_data, t
)
    register_threat(
        "mutant", unit, threat_target(scratchpad), "disabling", t, t + 0.45, nil, "charging"
    )
end)

mod:hook_safe("BtSniperShootAction", "_start_shooting", function(
    self, unit, t, scratchpad
)
    register_threat(
        "sniper", unit, threat_target(scratchpad), "lethal", t, t + 0.15, nil, "shooting"
    )
end)

mod:hook_safe("BtShootLiquidBeamAction", "_start_shooting", function(
    self, unit, t, scratchpad
)
    local danger_position = scratchpad and scratchpad.current_aim_position
        and scratchpad.current_aim_position:unbox()
    register_threat(
        "flamer", unit, threat_target(scratchpad), "lethal", t, t + 0.25,
        danger_position, "shooting"
    )
end)

mod:hook_safe("BtGrenadierThrowAction", "_throw_grenade", function(
    self, unit, breed, scratchpad, action_data, throw_type,
    throw_position, throw_direction, blackboard, t
)
    local danger_position = throw_position and throw_direction
        and throw_position + throw_direction * 10 or throw_position
    register_threat(
        "grenade", unit, threat_target(scratchpad, blackboard), "lethal",
        t, t + 0.45, danger_position, "projectile_spawned"
    )
end)

mod:hook_safe("BtMeleeAttackAction", "_start_attack_anim", function(
    self, unit, breed, target_unit, t, spawn_component, scratchpad, action_data
)
    local tags = breed and breed.tags or {}
    if not tags.elite and not tags.monster then return end
    local event = tostring(scratchpad and scratchpad.attack_event or ""):lower()
    local rager = breed and (breed.name == "cultist_berzerker"
        or breed.name == "renegade_berzerker")
    local overhead = event:find("overhead", 1, true)
        or action_data and action_data.aoe_threat_timing ~= nil
    local kind = rager and "rager"
        or overhead and "overhead" or "unknown"
    local impact_t = scratchpad and (scratchpad.attack_timing or scratchpad.start_sweep_t) or t
    local dodge_window = scratchpad and scratchpad.dodge_window
    local exact_reaction_t = dodge_window and math.max(t + 0.02, dodge_window + 0.02)
    register_threat(
        kind, unit, target_unit, (kind == "overhead" or kind == "rager") and "lethal" or "other",
        t, impact_t, nil, event ~= "" and event or "melee_attack", exact_reaction_t
    )
end)

local function nearest_network_attacker(position, breed_filter)
    local player_unit = local_player_unit()
    position = position and native_vector(position)
    local best_unit, best_distance
    for unit, data in pairs(unit_data_map) do
        if breed_filter[data.breed_name] and replicated_target(unit) == player_unit
            and HEALTH_ALIVE and HEALTH_ALIVE[unit] then
            local unit_position = native_vector(Unit.world_position(unit, 1))
            local distance = position and unit_position
                and Vector3.length(unit_position - position) or 0
            if not best_distance or distance < best_distance then
                best_unit, best_distance = unit, distance
            end
        end
    end
    return best_unit
end

local MELEE_SOUND_CUES = {
    ["wwise/events/weapon/play_minion_swing_1h_sword_elite"] = {
        breeds = RAGER_MELEE,
        kind = "rager",
        impact_lead = 0.22,
    },
    ["wwise/events/weapon/play_minion_swing_2h_sword_elite"] = {
        breeds = RAGER_MELEE,
        kind = "rager",
        impact_lead = 0.25,
    },
    ["wwise/events/weapon/play_minion_swing_chainaxe"] = {
        breeds = MAULER_MELEE,
        kind = "overhead",
        impact_lead = 0.3,
    },
    ["wwise/events/weapon/play_minion_swing_2h_blunt_large_cleave"] = {
        breeds = CRUSHER_MELEE,
        kind = "overhead",
        impact_lead = 0.35,
    },
    ["wwise/events/weapon/play_minion_swing_2h_blunt_large_sweep"] = {
        breeds = CRUSHER_MELEE,
        kind = "overhead",
        impact_lead = 0.3,
    },
}

if WwiseWorld then
    mod:hook_safe(WwiseWorld, "trigger_resource_event", function(
        wwise_world, event_name
    )
        local cue = MELEE_SOUND_CUES[event_name]
        if not cue then return end
        local game_session = Managers.state and Managers.state.game_session
        if game_session and game_session.is_server and game_session:is_server() then return end
        local source = nearest_network_attacker(nil, cue.breeds)
        if source then
            register_threat(
                cue.kind, source, local_player_unit(), "lethal", survival_t,
                survival_t + cue.impact_lead, nil, "melee_audio_cue",
                survival_t + 0.02
            )
        end
    end)
end

mod:hook_safe("MinionFxExtension", "rpc_trigger_minion_inventory_wwise_event", function(
    self, channel_id, go_id, event_id, inventory_slot_id, fx_source_name_id,
    optional_target_unit_id
)
    local event_name = NetworkLookup and NetworkLookup.sound_events
        and NetworkLookup.sound_events[event_id]
    if event_name ~= "wwise/events/minions/play_weapon_netgunner" then return end
    local unit_spawner = Managers.state and Managers.state.unit_spawner
    local target = unit_spawner and unit_spawner:unit(optional_target_unit_id)
    local source = self and self._unit
    if not source or not target then return end
    local source_position = native_vector(Unit.world_position(source, 1))
    local target_position = native_vector(Unit.world_position(target, 1))
    local distance = source_position and target_position
        and Vector3.length(source_position - target_position) or 4
    register_threat(
        "trapper", source, target, "disabling", survival_t,
        survival_t + math.max(0.12, distance / 20), nil, "replicated_net_shot"
    )
end)

mod:hook_safe("FxSystem", "rpc_trigger_wwise_event", function(
    self, channel_id, event_id, position
)
    local event_name = NetworkLookup and NetworkLookup.sound_events
        and NetworkLookup.sound_events[event_id]
    if event_name ~= "wwise/events/weapon/play_special_sniper_flash" then return end
    local source = nearest_network_attacker(position, { renegade_sniper = true })
    if source then
        register_threat(
            "sniper", source, local_player_unit(), "lethal", survival_t,
            survival_t + 0.45, position, "replicated_scope_flash"
        )
    end
end)

mod:hook_safe("FxSystem", "rpc_start_template_effect", function(
    self, channel_id, buffer_index, template_id, optional_unit_id
)
    local template_name = NetworkLookup and NetworkLookup.effect_templates
        and NetworkLookup.effect_templates[template_id]
    if template_name ~= "renegade_grenadier_grenade"
        and template_name ~= "cultist_grenadier_grenade" then return end
    local unit_spawner = Managers.state and Managers.state.unit_spawner
    local source = unit_spawner and unit_spawner:unit(optional_unit_id)
    local target = source and replicated_target(source)
    register_threat(
        "grenade", source, target, "lethal", survival_t, survival_t + 0.6,
        nil, "replicated_throw_windup"
    )
end)

mod:hook_safe("PlayerUnitFxExtension", "rpc_play_exclusive_player_sound", function(
    self, channel_id, game_object_id, event_id, position
)
    local event_name = NetworkLookup and NetworkLookup.player_character_sounds
        and NetworkLookup.player_character_sounds[event_id]
    if event_name ~= "wwise/events/player/play_backstab_indicator_melee_elite" then return end
    local source = nearest_network_attacker(position, HIGH_RISK_MELEE)
    if source then
        register_threat(
            "overhead", source, local_player_unit(), "lethal", survival_t,
            survival_t + 0.6, position, "replicated_elite_backstab"
        )
    end
end)

local semi_auto_pressed_action_t = setmetatable({}, { __mode = "k" })

local function activation_is_held_in_cache(activation, custom_held, lookup, input_cache, index)
    if activation == "custom" then return custom_held end
    local left_index = lookup.action_one_hold
    local right_index = lookup.action_two_hold
    local left = left_index and input_cache[left_index][index] or false
    local right = right_index and input_cache[right_index][index] or false
    if activation == "left_mouse" then return left end
    if activation == "right_mouse" then return right end
    if activation == "both_mouse" then return left or right end
    return false
end

local function cached_input(lookup, input_cache, index, action)
    local cache_index = lookup[action]
    return cache_index and input_cache[cache_index][index]
end

local function set_cached_input(lookup, input_cache, index, action, value)
    local cache_index = lookup[action]
    if cache_index then input_cache[cache_index][index] = value end
end

local function has_physical_survival_input(lookup, input_cache, index)
    local actions = {
        "dodge", "action_one_hold", "action_one_pressed", "action_two_hold",
        "wield_1", "wield_2", "weapon_reload_hold", "weapon_extra_hold",
    }
    for i = 1, #actions do
        local value = cached_input(lookup, input_cache, index, actions[i])
        if value == true or type(value) == "number" and value ~= 0 then return true end
    end
    return false
end

local function physical_move_action(lookup, input_cache, index)
    for _, action in ipairs({ "move_forward", "move_backward", "move_left", "move_right" }) do
        local value = cached_input(lookup, input_cache, index, action)
        if value == true or type(value) == "number" and value ~= 0 then return action end
    end
end

local function apply_input_sequence(sequence, lookup, input_cache, index)
    for i = 1, sequence and #sequence or 0 do
        local input = sequence[i]
        if input and input.input and input.value ~= nil then
            set_cached_input(lookup, input_cache, index, input.input, input.value)
        end
    end
end

local function apply_survival_input(lookup, input_cache, index, t)
    local physical = has_physical_survival_input(lookup, input_cache, index)
    local physical_move = physical_move_action(lookup, input_cache, index)
    if requested_defense then
        local request = requested_defense
        local force_dodge = request.action == "dodge" and t and request.force_t
            and t >= request.force_t
        if t and t > request.until_t then
            requested_defense = nil
        elseif not physical or emergency_override or force_dodge then
            if request.action == "dodge" then
                set_cached_input(lookup, input_cache, index, "dodge", true)
                if not physical_move then
                    set_cached_input(lookup, input_cache, index, request.move_action or "move_left", 1)
                end
                requested_defense = nil
            elseif request.action == "push" then
                set_cached_input(lookup, input_cache, index, "action_two_hold", true)
                request.action = "push_attack"
                request.until_t = math.max(request.until_t, (t or 0) + 0.2)
            elseif request.action == "push_attack" then
                set_cached_input(lookup, input_cache, index, "action_two_hold", true)
                set_cached_input(lookup, input_cache, index, "action_one_pressed", true)
                requested_defense = nil
            end
        end
    end

    if requested_vent and not physical then
        apply_input_sequence(requested_vent.input_sequence, lookup, input_cache, index)
    end
end

mod:hook("HumanInputHandler", "_parse_input", function(
    func, self, input_cache, input_service, index
)
    func(self, input_cache, input_service, index)

    local lookup = self._action_lookup
    local hold_index = lookup and lookup.action_one_hold
    local press_index = lookup and lookup.action_one_pressed
    local player = Managers.player and Managers.player:local_player(1)
    local player_unit = player and player.player_unit
    if not player_unit or self._player ~= player or not lookup then return end

    physical_action_one_hold = hold_index and input_cache[hold_index][index] == true or false
    local fixed_time_step = Managers.state and Managers.state.game_session
        and Managers.state.game_session.fixed_time_step
    local frame = self._frame
    local t = frame and fixed_time_step and frame * fixed_time_step

    local whistle_target = auto_whistle_pending_target
    if whistle_target and t then
        local grenade_press_index = lookup.grenade_ability_pressed
        local grenade_hold_index = lookup.grenade_ability_hold
        if not auto_whistle_hold_until
            and (not HEALTH_ALIVE or not HEALTH_ALIVE[whistle_target]) then
            auto_whistle_pending_target = nil
        elseif auto_whistle_hold_until and t < auto_whistle_hold_until - 1 then
            auto_whistle_pending_target = nil
            auto_whistle_hold_until = nil
        elseif grenade_press_index and grenade_hold_index then
            if auto_whistle_hold_until and t >= auto_whistle_hold_until then
                auto_whistle_pending_target = nil
                auto_whistle_used_target = whistle_target
                auto_whistle_hold_until = nil
            elseif auto_whistle_hold_until then
                input_cache[grenade_hold_index][index] = true
            else
                local ability = ScriptUnit.has_extension(player_unit, "ability_system")
                local can_whistle = ability
                    and ability:get_current_grenade_ability_name() == "adamant_whistle"
                    and ability:can_use_ability("grenade_ability")
                    and ability:action_input_is_currently_valid(
                        "grenade_ability_action", "aim_pressed", "grenade_ability_pressed", t
                    )
                if can_whistle then
                    input_cache[grenade_press_index][index] = true
                    input_cache[grenade_hold_index][index] = true
                    auto_whistle_hold_until = t + 0.08
                end
            end
        end
    end

    apply_survival_input(lookup, input_cache, index, t)

    local generated_fire = requested_auto_fire_mode and t and requested_auto_fire_until
        and t <= requested_auto_fire_until
    if generated_fire and requested_auto_fire_mode == "rage" then
        generated_fire = rage_held
    elseif generated_fire and requested_auto_fire_mode == "trigger" then
        generated_fire = activation_is_held_in_cache(
            trigger_activation, triggerbot_held, lookup, input_cache, index
        )
    end
    if generated_fire and governor_suppress_fire then generated_fire = false end
    if requested_auto_fire_mode and not generated_fire then
        requested_auto_fire_mode = nil
        requested_auto_fire_until = nil
    end

    local physical_repeat = enable_auto_fire and physical_action_one_hold
    if not hold_index or not press_index or not (physical_repeat or generated_fire) then
        semi_auto_pressed_action_t[self] = nil
        return
    end
    if generated_fire then input_cache[hold_index][index] = true end
    if input_cache[press_index][index] then return end

    local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
    local weapon_extension = ScriptUnit.has_extension(player_unit, "weapon_system")
    local action_component = unit_data and unit_data:read_component("weapon_action")
    local action_start_t = action_component and action_component.start_t
    if not weapon_extension or action_start_t == nil
        or semi_auto_pressed_action_t[self] == action_start_t then return end

    local weapon_template = WeaponTemplate.current_weapon_template(action_component)
    local action_inputs = weapon_template and weapon_template.action_inputs
    if not action_inputs then return end

    local hip_action = action_inputs.shoot_pressed and "shoot_pressed"
        or action_inputs.shoot and "shoot"
    if not hip_action then return end
    local action_two_index = lookup.action_two_hold
    local action = action_two_index and input_cache[action_two_index][index]
        and action_inputs.zoom_shoot
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

    if t and weapon_extension:action_input_is_currently_valid(
        "weapon_action", action, "action_one_pressed", t
    ) then
        input_cache[press_index][index] = true
        semi_auto_pressed_action_t[self] = action_start_t
    end
end)

mod:hook_safe("ActionInputParser", "mispredict_happened", function(self)
    local player = Managers.player and Managers.player:local_player(1)
    if player and self._player == player and self._action_component_name == "weapon_action" then
        table.clear(semi_auto_pressed_action_t)
    end
end)

local function suppress_local_spread(self)
    local player = Managers.player and Managers.player:local_player(1)
    return enable_no_spread and player and self._unit == player.player_unit
end

mod:hook("PlayerUnitWeaponSpreadExtension", "randomized_spread", function(
    func, self, current_rotation, ...
)
    if suppress_local_spread(self) then
        func(self, current_rotation, ...)
        return current_rotation
    end
    return func(self, current_rotation, ...)
end)

mod:hook("PlayerUnitWeaponSpreadExtension", "target_style_spread", function(
    func, self, current_rotation, ...
)
    if suppress_local_spread(self) then
        func(self, current_rotation, ...)
        return current_rotation
    end
    return func(self, current_rotation, ...)
end)

mod:hook(Recoil, "first_person_offset", function(
    func, recoil_template, read_recoil_component, ...
)
    local player = Managers.player and Managers.player:local_player(1)
    local first_person = player and player.player_unit
        and ScriptUnit.has_extension(player.player_unit, "first_person_system")
    if enable_no_recoil and first_person
        and read_recoil_component == first_person._recoil_component then return 0, 0 end
    return func(recoil_template, read_recoil_component, ...)
end)

mod:hook_safe("PlayerUnitFirstPersonExtension", "fixed_update", function(self, unit, dt, t, frame)
    if not dt or dt <= 0 then return end

    requested_auto_fire_mode = nil
    requested_auto_fire_until = nil

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
    update_auto_whistle_from_companion_state(unit)
    update_survival(unit, first_person, t)

    local mode
    if rage_held then
        mode = "rage"
    elseif activation_is_held(trigger_activation, triggerbot_held, self._input_extension) then
        mode = "trigger"
    elseif activation_is_held(aim_activation, aimbot_held, self._input_extension) then
        mode = "aim"
    end
    local camera_forward = Quaternion.forward(first_person.rotation)
    local on_screen = function(position) return self:is_within_default_view(position) end
    if not mode then
        clear_aim_lock()
        local preview_mode = aim_activation ~= "off" and "aim"
            or trigger_activation ~= "off" and "trigger"
        if not preview_mode then
            set_aim_preview(nil, nil, nil, nil)
            return
        end
        local preview_fov = preview_mode == "trigger" and trigger_fov or aim_fov
        local preview_position, _, preview_target, preview_distance = select_aim_target(
            physics_world, visibility_origin, camera_forward,
            aim_distance, preview_fov, dt, nil, "preview", on_screen
        )
        set_aim_preview(preview_target, preview_position, preview_mode, preview_distance)
        clear_aim_lock()
        return
    end

    local preferred_target
    if mode == "aim" and not locked_target then
        preferred_target = aim_preview_target
        local smart_targeting = not preferred_target
            and ScriptUnit.has_extension(unit, "smart_targeting_system")
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
    local distance_limit = mode == "rage" and rage_distance or aim_distance
    local melee_reach = melee_aim_reach(unit_data)
    if melee_reach then distance_limit = math.min(distance_limit, melee_reach) end
    local fov = mode == "trigger" and trigger_fov or aim_fov
    local target_position, visible, target, target_distance = select_aim_target(
        physics_world, visibility_origin, camera_forward,
        distance_limit, fov, dt, preferred_target, mode, on_screen
    )
    if target_position or mode == "rage" then
        set_aim_preview(target, target_position, mode, target_distance)
    else
        local preview_position, _, preview_target, preview_distance = select_aim_target(
            physics_world, visibility_origin, camera_forward,
            aim_distance, fov, dt, nil, "preview", on_screen
        )
        set_aim_preview(preview_target, preview_position, mode, preview_distance)
        clear_aim_lock()
    end
    if not target_position then return end

    local smoothness = mode == "rage" and rage_smoothness
        or mode == "trigger" and trigger_smoothness
        or aim_smoothness
    local error = aim_at_position(player, first_person, target_position, dt, smoothness)
    local should_fire = visible and ((mode == "rage" and error <= 1.5)
        or (mode == "trigger" and error <= trigger_fire_fov))
    if should_fire then
        requested_auto_fire_mode = mode
        requested_auto_fire_until = t + math.max(0.15, dt * 2)
    end
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

mod:hook_safe("InteracteeExtension", "init", function(self, extension_init_context, unit)
    add_pickup_esp(unit)
end)

local function teardown_runtime(for_reload)
    mod.enabled = false
    aimbot_held, triggerbot_held, rage_held = false, false, false
    physical_action_one_hold = nil
    requested_auto_fire_mode, requested_auto_fire_until = nil, nil
    requested_defense, requested_vent = nil, nil
    governor_suppress_fire = false
    companion_target = nil
    companion_waiting_for_damage = false
    companion_wait_deadline_t = 0
    auto_whistle_pending_target = nil
    auto_whistle_used_target = nil
    auto_whistle_hold_until = nil
    clear_aim_lock()
    set_aim_preview(nil, nil, nil, nil)
    clear_active_threat()
    table.clear(companion_attackers)
    table.clear(semi_auto_pressed_action_t)
    table.clear(resource_history)

    for unit, data in pairs(unit_data_map) do
        remove_outline(unit, data)
        kill_marker(unit)
    end
    for unit in pairs(horde_unit_data) do kill_horde_marker(unit) end
    for unit in pairs(pickup_unit_data) do kill_pickup_marker(unit) end
    if mod.aim_marker_ref then
        mod.aim_marker_ref.remove = true
        mod.aim_marker_ref = nil
    end

    if for_reload then
        markers_ready = false
        outline_system = nil
        table.clear(unit_data_map)
        table.clear(horde_unit_data)
        table.clear(pickup_unit_data)
        table.clear(aim_target_map)
        table.clear(marker_requested_at)
        table.clear(horde_marker_requested_at)
        table.clear(pickup_marker_requested_at)
    end
end

local function discover_existing_units()
    local extension_manager = Managers.state and Managers.state.extension
    if not extension_manager then return end
    outline_system = extension_manager:system("outline_system")
    local minions = extension_manager:get_entities("MinionUnitDataExtension")
    for unit in pairs(minions or {}) do
        if HEALTH_ALIVE and HEALTH_ALIVE[unit] then add_esp_for_unit(unit) end
    end
    local interactees = extension_manager:get_entities("InteracteeExtension")
    for unit in pairs(interactees or {}) do
        if ALIVE and ALIVE[unit] then add_pickup_esp(unit) end
    end
end

mod.on_disabled = function()
    teardown_runtime(false)
end

mod.on_unload = function()
    teardown_runtime(true)
end

mod.on_enabled = function()
    mod.enabled = true
    refresh_settings()
    attach_live_world_markers()
    discover_existing_units()
    marker_retry_frames = 10
end

refresh_settings()
mod:echo("Loaded! - By @luinbytes")
