math.clamp = math.clamp or function(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
math.atan2 = math.atan2 or math.atan
table.clear = table.clear or function(value)
    for key in pairs(value) do value[key] = nil end
end

local vector = {}
local transient_vector
local function components(value)
    return rawget(value, "_x") or rawget(value, "x"),
        rawget(value, "_y") or rawget(value, "y"),
        rawget(value, "_z") or rawget(value, "z")
end
vector.__index = vector
vector.__sub = function(a, b)
    local metatable = getmetatable(b)
    assert(metatable == vector or metatable == transient_vector,
        "native Vector3 cannot subtract boxed userdata")
    local ax, ay, az = components(a)
    local bx, by, bz = components(b)
    return Vector3(ax - bx, ay - by, az - bz)
end
vector.__add = function(a, b)
    local ax, ay, az = components(a)
    local bx, by, bz = components(b)
    return Vector3(ax + bx, ay + by, az + bz)
end
vector.__mul = function(a, scalar)
    local x, y, z = components(a)
    return Vector3(x * scalar, y * scalar, z * scalar)
end
local boxed_vector = {}
boxed_vector.__index = boxed_vector
boxed_vector.__sub = vector.__sub
boxed_vector.__add = vector.__add
local last_constructed
transient_vector = {
    __index = function(value, key)
        if key == "x" or key == "y" or key == "z" then
            error("Darktide Vector3 components must be read with Vector3.to_elements")
        end
        return transient_vector[key]
    end,
    __sub = vector.__sub,
    __add = vector.__add,
    __mul = vector.__mul,
}

Vector3 = setmetatable({
    length = function(v)
        local x, y, z = components(v)
        return math.sqrt(x * x + y * y + z * z)
    end,
    normalize = function(v)
        local length = Vector3.length(v)
        local x, y, z = components(v)
        return Vector3(x / length, y / length, z / length)
    end,
    dot = function(a, b)
        local ax, ay, az = components(a)
        local bx, by, bz = components(b)
        return ax * bx + ay * by + az * bz
    end,
    to_elements = components,
    lerp = function() error("Darktide's lerp binding rejects aim-position userdata") end,
}, {
    __call = function(_, x, y, z)
        last_constructed = setmetatable({ _x = x, _y = y, _z = z, _valid = true }, transient_vector)
        return last_constructed
    end,
})

Vector3Box = function(value)
    local x, y, z = Vector3.to_elements(value)
    return {
        store = function(self, next_value)
            self.x, self.y, self.z = Vector3.to_elements(next_value)
        end,
        unbox = function(self)
            return Vector3(self.x, self.y, self.z)
        end,
        x = x,
        y = y,
        z = z,
    }
end

local settings = {
    enable_outlines = false,
    enable_nameplates = false,
    enable_horde_esp = true,
    enable_pickup_esp = true,
    horde_distance = 80,
    pickup_distance = 80,
    max_distance = 80,
    outline_distance = 30,
    enable_aimbot = true,
    aim_distance = 80,
    aim_fov = 30,
    aim_smoothness = 55,
    aim_curve = 20,
    aim_location = "head",
    aim_activation = "left_mouse",
    trigger_activation = "off",
    trigger_fov = 5,
    trigger_fire_fov = 0.8,
    trigger_smoothness = 35,
    rage_distance = 120,
    rage_smoothness = 10,
    enable_auto_fire = true,
    enable_no_recoil = false,
    enable_no_spread = false,
    enable_companion_target = false,
    companion_distance = 60,
    enable_auto_whistle = false,
}
local messages = {}
local hooks = {}
local parsed_fire_pressed = false
local shot_ready = false
local recoil_calls = 0
local recoil_offset_calls = 0
local randomized_spread_calls = 0
local target_style_spread_calls = 0
local recoil_api = {
    first_person_offset = function(_, recoil)
        recoil_offset_calls = recoil_offset_calls + 1
        return recoil.pitch_offset, recoil.yaw_offset
    end,
    weapon_offset = function(_, recoil)
        return recoil.pitch_offset, recoil.yaw_offset
    end,
    add_recoil = function()
        recoil_calls = recoil_calls + 1
    end,
}
package.preload["scripts/utilities/recoil"] = function()
    return recoil_api
end
package.preload["scripts/settings/damage/attack_settings"] = function()
    return { attack_types = { companion_dog = "companion_dog" } }
end
package.preload["scripts/utilities/weapon/weapon_template"] = function()
    return { current_weapon_template = function(component) return component.template end }
end
local HumanInputHandler = {
    _parse_input = function(self, input_cache, input_service, index)
        for action, cache_index in pairs(self._action_lookup) do
            input_cache[cache_index][index] = input_service:get_with_filters(action)
        end
    end,
}
package.preload["scripts/extension_systems/action_input/action_input_parser"] = function()
    error("action input parser must not be required during mod_script initialization")
end
local mod = {
    get = function(_, key) return settings[key] end,
    io_dofile = function(_, path)
        return { name = path:find("HordeMarker") and "ballhammer_horde_marker"
            or path:find("PickupMarker") and "ballhammer_pickup_marker"
            or "ballhammer_marker" }
    end,
    command = function() end,
    echo = function(_, message) messages[#messages + 1] = message end,
    hook_safe = function(_, object, method, handler)
        if type(object) == "string" then hooks[object .. "." .. method] = handler end
    end,
    hook = function(_, object, method, handler)
        if type(object) == "string" then
            hooks["delayed." .. object .. "." .. method] = handler
            return
        end
        local original = object[method]
        object[method] = function(...)
            return handler(original, ...)
        end
    end,
}

get_mod = function() return mod end
CLASS = {
    MinionSpawnManager = {
        spawn_minion = function(_, unit) return unit end,
    },
    OutlineSystem = {},
    PlayerUnitInputExtension = { get = function() return false end },
    PlayerUnitActionInputExtension = { fixed_update = function() end },
    PlayerUnitWeaponSpreadExtension = {
        randomized_spread = function(_, rotation)
            randomized_spread_calls = randomized_spread_calls + 1
            return { spread = rotation }
        end,
        target_style_spread = function(_, rotation)
            target_style_spread_calls = target_style_spread_calls + 1
            return { spread = rotation }
        end,
    },
}
local player_unit = {}
local local_recoil_component = { pitch_offset = 0.4, yaw_offset = -0.2 }
HEALTH_ALIVE = {}
ALIVE = { [player_unit] = true }
BLACKBOARDS = {}
local orientation = { yaw = 0, pitch = 0 }
local player = {
    player_unit = player_unit,
    viewport_name = "player_1",
    unit_is_alive = function() return true end,
    get_orientation = function() return orientation end,
    set_orientation = function(_, yaw, pitch, roll)
        orientation.yaw, orientation.pitch, orientation.roll = yaw, pitch, roll
    end,
}
local marker_events = {}
local held_action = "action_one_hold"
local preexisting_units = {}
local preexisting_pickups = {}
local smart_direct_target
local smart_target_updates = 0
local companion_can_order = false
local companion_orders = {}
local companion_unit = {}
local companion_network_unit = {}
local hud_camera_position = Vector3(0, 0, 0)
local whistle_equipped = false
local whistle_charged = false
local whistle_action_valid = true
local ability_extension = {
    get_current_grenade_ability_name = function()
        return whistle_equipped and "adamant_whistle" or "adamant_grenade"
    end,
    can_use_ability = function(_, ability_type)
        return ability_type == "grenade_ability" and whistle_charged
    end,
    action_input_is_currently_valid = function(_, component_name, action_input, used_input)
        return component_name == "grenade_ability_action" and action_input == "aim_pressed"
            and used_input == "grenade_ability_pressed" and whistle_action_valid
    end,
}
local weapon_action_inputs = {
    shoot_pressed = {
        input_sequence = { { input = "action_one_pressed", value = true } },
    },
}
local weapon_action_component = {
    current_action_name = "action_shoot_hip",
    start_t = 1.0,
    template = { action_inputs = weapon_action_inputs },
}
local weapon_extension = {
    action_input_is_currently_valid = function() return shot_ready end,
    recoil_template = function() return {} end,
}
Managers = {
    player = { local_player = function() return player end },
    input = {
        _find_active_device = function(_, device)
            assert(device == "mouse")
            return {
                button_index = function(_, button) return button end,
                held = function() return false end,
            }
        end,
    },
    state = {
        game_session = { fixed_time_step = 0.1 },
        camera = {
            camera = function(_, viewport_name)
                assert(viewport_name == "player_1")
                return { position = hud_camera_position }
            end,
        },
        extension = {
            get_entities = function(_, name)
                if name == "MinionUnitDataExtension" then return preexisting_units end
                if name == "InteracteeExtension" then return preexisting_pickups end
                error("unexpected extension query: " .. tostring(name))
            end,
            system = function(_, name)
                if name == "smart_tag_system" then
                    return {
                        set_contextual_unit_tag = function(_, tagger, target, alternate)
                            companion_orders[#companion_orders + 1] = {
                                tagger = tagger,
                                target = target,
                                alternate = alternate,
                            }
                        end,
                    }
                end
            end,
        },
        player_unit_spawn = {
            owner = function(_, unit)
                return (unit == companion_unit or unit == companion_network_unit) and player or nil
            end,
        },
    },
    event = {
        trigger = function(_, event_name, marker_name, unit, _, data)
            marker_events[#marker_events + 1] = {
                event_name = event_name,
                marker_name = marker_name,
                unit = unit,
                data = data,
            }
        end,
    },
}

local units = {}
local camera_rotation = Vector3(0, 1, 0)
local disabling_unit = nil
local disabling_type = "none"
ScriptUnit = {
    has_extension = function(unit, system)
        if unit == player_unit then
            if system == "companion_spawner_system" then
                return companion_can_order and {
                    companion_can_tag_order = function() return true end,
                    companion_units = function() return { companion_unit } end,
                } or nil
            end
            if system == "smart_targeting_system" then
                return {
                    force_update_smart_tag_targets = function()
                        smart_target_updates = smart_target_updates + 1
                    end,
                    smart_tag_targeting_data = function()
                        return { unit = smart_direct_target }
                    end,
                }
            end
            if system == "ability_system" then return ability_extension end
            if system == "weapon_system" then return weapon_extension end
            if system == "first_person_system" then
                return { _recoil_component = local_recoil_component }
            end
            return {
                read_component = function(_, name)
                    if name == "first_person" then
                        return { position = Vector3(0, 0, 0), rotation = camera_rotation }
                    end
                    if name == "weapon_action" then
                        return weapon_action_component
                    end
                    if name == "disabled_character_state" then
                        return {
                            is_disabled = disabling_unit ~= nil,
                            disabling_unit = disabling_unit,
                            disabling_type = disabling_type,
                        }
                    end
                    return { yaw_offset = 0, pitch_offset = 0, offset_x = 0, offset_y = 0 }
                end,
            }
        end
        if system == "health_system" then
            return {
                current_health_percent = function() return units[unit].health or 1 end,
            }
        end
        return {
            breed = function()
                return units[unit].breed_data or { name = units[unit].breed }
            end,
        }
    end,
}
Unit = {
    get_data = function(unit, key)
        local data = units[unit]
        if key == "pickup_type" then return data and data.pickup_type end
        if key == "is_pickup" then return data and data.pickup_type ~= nil end
    end,
    has_node = function(unit, name)
        local nodes = units[unit].nodes
        return not nodes or nodes[name] ~= nil
    end,
    node = function(unit, name)
        assert(Unit.has_node(unit, name), "missing aim bone: " .. name)
        return name
    end,
    world_position = function(unit, node)
        if unit == player_unit then return Vector3(0, 0, 0) end
        local data = units[unit]
        local position = data.nodes and data.nodes[node] or data.position
        local x, y, z = Vector3.to_elements(position)
        if data.mixed_vector then
            data.position_reads = (data.position_reads or 0) + 1
            if data.position_reads % 2 == 0 then return Vector3(x, y, z) end
        end
        return setmetatable({ x = x, y = y, z = z }, boxed_vector)
    end,
}
Quaternion = { forward = function(rotation) return rotation end }
Camera = { local_position = function(camera) return camera.position end }
local gameplay_world = {}
local physics_world = {}
Application = { main_world = function() return {} end }
World = {
    physics_world = function(world)
        assert(world == gameplay_world, "World does not have a PhysicsWorld")
        return physics_world
    end,
}
Actor = { unit = function(actor) return actor.unit end }
PhysicsWorld = {
    raycast = function(world, origin, direction, _, cast_type, filter_key, filter_name)
        assert(world == physics_world, "raycast should use the gameplay physics world")
        local ox, oy, oz = Vector3.to_elements(origin)
        local cx, cy, cz = Vector3.to_elements(hud_camera_position)
        assert(ox == cx and oy == cy and oz == cz,
            "aim and companion visibility should cast from the HUD camera")
        assert(cast_type == "all" and filter_key == "collision_filter" and
            filter_name == "filter_interactable_line_of_sight_marker_check",
            "aim and companion visibility should use the same filter as ESP")
        local direction_x = Vector3.to_elements(direction)
        if direction_x < 0.15 then return { { false, false, false, {} } } end
        return nil
    end,
}

dofile("scripts/mods/BallHammer/BallHammer.lua")
local function apply_delayed_hook(object_name, object, method)
    local handler = hooks["delayed." .. object_name .. "." .. method]
    assert(handler, object_name .. "." .. method .. " should use DMF's deferred hook path")
    local original = object[method]
    object[method] = function(...)
        return handler(original, ...)
    end
end
apply_delayed_hook("HumanInputHandler", HumanInputHandler, "_parse_input")
apply_delayed_hook("PlayerUnitWeaponSpreadExtension",
    CLASS.PlayerUnitWeaponSpreadExtension, "randomized_spread")
apply_delayed_hook("PlayerUnitWeaponSpreadExtension",
    CLASS.PlayerUnitWeaponSpreadExtension, "target_style_spread")
assert(messages[#messages] == "Loaded! - By @luinbytes",
    "load banner should use the requested credit")

local rotation = {}
assert(CLASS.PlayerUnitWeaponSpreadExtension.randomized_spread({ _unit = player_unit }, rotation).spread == rotation,
    "BallHammer should not override weapon spread")
assert(CLASS.PlayerUnitWeaponSpreadExtension.target_style_spread({ _unit = player_unit }, rotation).spread == rotation,
    "BallHammer should not override pellet spread")
recoil_api.add_recoil(0, nil, nil, nil, nil, nil, nil, nil, player_unit)
assert(recoil_calls == 1, "BallHammer should not override weapon recoil")
settings.enable_no_recoil = true
settings.enable_no_spread = true
mod.on_setting_changed("enable_no_recoil")
mod.on_setting_changed("enable_no_spread")
local weapon_orientation_yaw, weapon_orientation_pitch = orientation.yaw, orientation.pitch
assert(CLASS.PlayerUnitWeaponSpreadExtension.randomized_spread(
    { _unit = player_unit }, rotation
) == rotation, "no spread should return the unmodified shot rotation")
assert(CLASS.PlayerUnitWeaponSpreadExtension.target_style_spread(
    { _unit = player_unit }, rotation
) == rotation, "no spread should return the unmodified pellet rotation")
assert(randomized_spread_calls == 2 and target_style_spread_calls == 2,
    "no spread must still advance Darktide's deterministic spread state")
recoil_api.add_recoil(0, nil, nil, nil, nil, nil, nil, nil, player_unit)
assert(recoil_calls == 2,
    "no recoil must preserve native recoil state for multiplayer prediction")
local camera_pitch, camera_yaw = recoil_api.first_person_offset(
    nil, local_recoil_component
)
assert(camera_pitch == 0 and camera_yaw == 0,
    "no recoil should suppress only the local camera recoil offset")
local remote_camera_pitch, remote_camera_yaw = recoil_api.first_person_offset(
    nil, { pitch_offset = 0.3, yaw_offset = -0.1 }
)
assert(remote_camera_pitch == 0.3 and remote_camera_yaw == -0.1,
    "no recoil must preserve non-local camera recoil on a multiplayer host")
local weapon_pitch, weapon_yaw = recoil_api.weapon_offset(
    nil, { pitch_offset = 0.4, yaw_offset = -0.2 }
)
assert(weapon_pitch == 0.4 and weapon_yaw == -0.2,
    "no recoil must preserve the weapon offset used by multiplayer shot prediction")
assert(orientation.yaw == weapon_orientation_yaw and orientation.pitch == weapon_orientation_pitch,
    "weapon suppression must never compensate through player orientation")
local remote_weapon_unit = {}
assert(CLASS.PlayerUnitWeaponSpreadExtension.randomized_spread(
    { _unit = remote_weapon_unit }, rotation
).spread == rotation, "no spread must not alter remote weapon prediction")
recoil_api.add_recoil(0, nil, nil, nil, nil, nil, nil, nil, remote_weapon_unit)
assert(recoil_calls == 3, "no recoil must not alter remote weapon prediction")

hooks["HudElementWorldMarkers.init"]({ _marker_templates = {} })
local plasteel_pickup = {}
units[plasteel_pickup] = {
    pickup_type = "large_metal",
    position = Vector3(1, 6, 0),
}
ALIVE[plasteel_pickup] = true
preexisting_pickups[plasteel_pickup] = true
for frame = 1, 60 do hooks["HudElementWorldMarkers.update"]({}, 0.016, frame * 0.016) end
assert(marker_events[1] and marker_events[1].marker_name == "ballhammer_pickup_marker"
    and marker_events[1].data.name == "Plasteel",
    "pickup ESP should discover and classify materials that predate a hot reload")
table.clear(preexisting_pickups)
settings.enable_pickup_esp = false
mod.on_setting_changed("enable_pickup_esp")
local pickup_events_before = #marker_events
local ammo_pickup = {}
units[ammo_pickup] = { pickup_type = "large_clip", position = Vector3(1, 7, 0) }
ALIVE[ammo_pickup] = true
hooks["InteracteeExtension.init"](nil, nil, ammo_pickup)
assert(#marker_events == pickup_events_before,
    "pickup ESP should respect its independent setting")
settings.enable_pickup_esp = true
mod.on_setting_changed("enable_pickup_esp")
table.clear(marker_events)
ALIVE[plasteel_pickup], ALIVE[ammo_pickup] = false, false

local preexisting_unit = {}
units[preexisting_unit] = {
    breed_data = { name = "renegade_rifleman", base_height = 1.8, tags = { minion = true, roamer = true } },
    position = Vector3(2, 15, 0),
}
HEALTH_ALIVE[preexisting_unit] = true
preexisting_units[preexisting_unit] = true
for frame = 1, 60 do hooks["HudElementWorldMarkers.update"]({}, 0.016, frame * 0.016) end
assert(marker_events[1] and marker_events[1].unit == preexisting_unit,
    "ESP should discover enemies that already existed when BallHammer loaded")
for frame = 61, 180 do hooks["HudElementWorldMarkers.update"]({}, 0.016, frame * 0.016) end
assert(marker_events[2] and marker_events[2].unit == preexisting_unit,
    "ESP should retry a marker request if the HUD never created it")
table.clear(marker_events)
table.clear(preexisting_units)
HEALTH_ALIVE[preexisting_unit] = false

local horde_unit = {}
units[horde_unit] = {
    breed_data = { name = "chaos_poxwalker", base_height = 1.7, tags = { horde = true } },
    position = Vector3(0, 20, 0),
}
HEALTH_ALIVE[horde_unit] = true
hooks["HealthExtension.init"](nil, nil, horde_unit)
assert(marker_events[1].marker_name == "ballhammer_horde_marker", "horde breeds should use the dynamic box marker")
assert(marker_events[1].data.base_height == 1.7, "horde marker should carry the breed height")

local regular_unit = {}
units[regular_unit] = {
    breed_data = { name = "cultist_melee", base_height = 1.9, tags = { minion = true, roamer = true } },
    position = Vector3(1.5, 8, 0),
    nodes = { j_spine = Vector3(1.5, 8, 0.5) },
}
HEALTH_ALIVE[regular_unit] = true
hooks["HealthExtension.init"](nil, nil, regular_unit)
assert(marker_events[2].unit == regular_unit, "ordinary minions should be registered for ESP")
assert(marker_events[2].data.clusterable, "ordinary minions should join nearby horde clusters")
assert(marker_events[2].data.name == "Melee", "ordinary enemy labels should omit faction prefixes")

local infected_unit = {}
units[infected_unit] = {
    breed_data = { name = "chaos_newly_infected", base_height = 1.8, tags = { minion = true, horde = true } },
    position = Vector3(3, 12, 0),
}
HEALTH_ALIVE[infected_unit] = true
hooks["HealthExtension.init"](nil, nil, infected_unit)
assert(marker_events[3].data.name == "Newly Infected",
    "crowded horde labels should be short enough not to overlap unnecessarily")
assert(marker_events[3].data.force_horde_merge,
    "newly infected should be allowed to merge into an adjacent horde")

local armored_infected_unit = {}
units[armored_infected_unit] = {
    breed_data = { name = "chaos_armored_infected", base_height = 1.9, tags = { minion = true, horde = true } },
    position = Vector3(4, 12, 0),
}
HEALTH_ALIVE[armored_infected_unit] = true
hooks["HealthExtension.init"](nil, nil, armored_infected_unit)
assert(marker_events[4].data.force_horde_merge,
    "armored infected should be allowed to merge into an adjacent horde")

local priority_unit = {}
settings.enable_nameplates = true
mod.on_setting_changed("enable_nameplates")
units[priority_unit] = {
    breed_data = {
        name = "cultist_ritualist",
        base_height = 1.8,
        smart_tag_target_type = "breed",
        tags = { minion = true, ritualist = true },
    },
    position = Vector3(20, 80, 0),
}
HEALTH_ALIVE[priority_unit] = true
hooks["HealthExtension.init"](nil, nil, priority_unit)
assert(marker_events[5].marker_name == "ballhammer_marker" and marker_events[5].data.flag == "SPECIAL",
    "every non-grunt enemy should use the visible boss marker path")

local shotgunner_unit = {}
units[shotgunner_unit] = {
    breed_data = {
        name = "renegade_shocktrooper",
        base_height = 1.9,
        smart_tag_target_type = "breed",
        tags = { minion = true, elite = true },
    },
    position = Vector3(3, 18, 0),
}
HEALTH_ALIVE[shotgunner_unit] = true
hooks["HealthExtension.init"](nil, nil, shotgunner_unit)
assert(marker_events[6].data.name == "Shotgunner" and marker_events[6].data.flag == "SPECIAL",
    "shotgunners should always receive a visible boss tag")
local live_priority_marker = { template = { unit_node = "j_head" } }
local live_horde_marker = { template = { unit_node = "j_head" } }
mod.marker_refs[priority_unit] = live_priority_marker
mod.horde_marker_refs[horde_unit] = live_horde_marker
settings.aim_location = "torso"
mod.on_setting_changed("aim_location")
assert(live_priority_marker.template.unit_node == "j_spine" and
    live_horde_marker.template.unit_node == "j_spine",
    "changing aim bone should update cloned templates on live ESP markers")
settings.aim_location = "head"
mod.on_setting_changed("aim_location")
mod.marker_refs[priority_unit] = nil
mod.horde_marker_refs[horde_unit] = nil
table.clear(marker_events)
mod.marker_refs[shotgunner_unit] = { remove = true }
for frame = 181, 240 do hooks["HudElementWorldMarkers.update"]({}, 0.016, frame * 0.016) end
local respawn_marker_found = false
for i = 1, #marker_events do
    if marker_events[i].unit == shotgunner_unit then respawn_marker_found = true end
end
assert(respawn_marker_found, "a respawned enemy should replace its stale removed marker")
HEALTH_ALIVE[shotgunner_unit] = false

local training_respawn = {}
units[training_respawn] = {
    breed_data = {
        name = "renegade_sniper",
        base_height = 1.8,
        smart_tag_target_type = "breed",
        tags = { minion = true, special = true },
    },
    position = Vector3(5, 20, 0),
}
HEALTH_ALIVE[training_respawn] = true
table.clear(marker_events)
assert(CLASS.MinionSpawnManager.spawn_minion({}, training_respawn) == training_respawn,
    "spawn hook should preserve Darktide's returned minion unit")
assert(marker_events[1] and marker_events[1].unit == training_respawn,
    "a newly spawned training-range replacement should receive ESP immediately")
HEALTH_ALIVE[training_respawn] = false

mod.toggle_esp()

local blocked_best = {}
local visible_fallback = {}
units[blocked_best] = { breed = "renegade_sniper", position = Vector3(1, 10, 0) }
units[visible_fallback] = { breed = "renegade_sniper", position = Vector3(2, 10, 0) }
HEALTH_ALIVE[blocked_best] = true
HEALTH_ALIVE[visible_fallback] = true
hooks["HealthExtension.init"](nil, nil, blocked_best)
hooks["HealthExtension.init"](nil, nil, visible_fallback)

mod.aimbot_held(false)
settings.enable_aimbot = false
settings.aim_activation = "right_mouse"
settings.aim_smoothness = 80
settings.aim_curve = 0
mod.on_setting_changed("enable_aimbot")
mod.on_setting_changed("aim_activation")
mod.on_setting_changed("aim_smoothness")
mod.on_setting_changed("aim_curve")
held_action = "action_two_hold"

local first_person_extension = {
    _world = gameplay_world,
    _weapon_extension = weapon_extension,
    _recoil_component = local_recoil_component,
    _movement_state_component = {},
    _locomotion_component = {},
    _inair_state_component = {},
    _input_extension = {
        _is_local_unit = true,
        get = function(_, action) return action == held_action end,
    },
    is_within_default_view = function(_, position)
        local _, y = Vector3.to_elements(position)
        return y > 0
    end,
}
local recoil_reads_before_aim = recoil_offset_calls
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 0)
assert(recoil_offset_calls == recoil_reads_before_aim,
    "aimbot should follow view orientation without compensating animated weapon recoil")

local expected_yaw = math.atan2(8, 1.5) - math.pi * 0.5
local expected_pitch = math.asin(0.5 / math.sqrt(1.5 * 1.5 + 8 * 8 + 0.5 * 0.5))
local aim_alpha = 1 - math.exp(-(2 + (100 - settings.aim_smoothness) * 0.22) * 0.1)
assert(math.abs(orientation.yaw - expected_yaw * aim_alpha) < 0.0001 and orientation.yaw ~= expected_yaw,
    "right mouse should interpolate smoothly even when the legacy enable flag is false")
assert(math.abs(orientation.pitch - expected_pitch * aim_alpha) < 0.0001 and orientation.roll == 0,
    "a target above the crosshair must move aim up, not down")

local held_yaw, held_pitch = orientation.yaw, orientation.pitch
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 1)
assert(orientation.yaw == held_yaw and orientation.pitch == held_pitch,
    "releasing right mouse should stop aim immediately")

held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 2)
assert(math.abs(orientation.yaw - (held_yaw + (expected_yaw - held_yaw) * aim_alpha)) < 0.0001,
    "holding right mouse should continue interpolating toward the target")

orientation.pitch = math.pi * 2 - 0.02
local wrapped_error = math.abs((expected_pitch - orientation.pitch + math.pi) % (math.pi * 2) - math.pi)
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3)
local corrected_error = math.abs((expected_pitch - orientation.pitch + math.pi) % (math.pi * 2) - math.pi)
assert(corrected_error < wrapped_error,
    "aim should take the shortest pitch path across Darktide's wrapped orientation")

for target_unit in pairs(units) do HEALTH_ALIVE[target_unit] = false end
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.5)
local fallback_bone_target = {}
units[fallback_bone_target] = {
    breed = "renegade_sniper",
    position = Vector3(2, 10, 1),
    nodes = {
        j_head = Vector3(1, 10, 1.8),
        j_spine = Vector3(2, 10, 1),
    },
}
HEALTH_ALIVE[fallback_bone_target] = true
hooks["HealthExtension.init"](nil, nil, fallback_bone_target)
settings.aim_smoothness = 0
mod.on_setting_changed("aim_smoothness")
camera_rotation = Vector3.normalize(Vector3(2, 10, 1))
orientation.yaw, orientation.pitch = 0, 0
held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.6)
assert(orientation.yaw == 0 and orientation.pitch == 0,
    "aim should not bypass an occluded configured bone using a different body point")
units[fallback_bone_target].nodes.j_head = nil
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.65)
held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.66)
local fallback_yaw = math.atan2(10, 2) - math.pi * 0.5
local fallback_alpha = 1 - math.exp(-(2 + 100 * 0.22) * 0.1)
assert(math.abs(orientation.yaw - fallback_yaw * fallback_alpha) < 0.0001,
    "aim should use the next configured bone only when the primary bone is absent")
HEALTH_ALIVE[fallback_bone_target] = false
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.7)

local direct_pick, angular_pick = {}, {}
units[direct_pick] = {
    breed = "renegade_sniper",
    position = Vector3(6, 20, 0),
    nodes = { j_head = Vector3(10, 20, 1.8) },
}
units[angular_pick] = {
    breed = "renegade_sniper",
    position = Vector3(5, 20, 0),
    nodes = { j_head = Vector3(5, 20, 1.8) },
}
HEALTH_ALIVE[direct_pick], HEALTH_ALIVE[angular_pick] = true, true
hooks["HealthExtension.init"](nil, nil, direct_pick)
hooks["HealthExtension.init"](nil, nil, angular_pick)
smart_direct_target = direct_pick
camera_rotation = Vector3.normalize(Vector3(5, 20, 1.8))
orientation.yaw, orientation.pitch = 0, 0
held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.8)
local direct_yaw = math.atan2(20, 10) - math.pi * 0.5
local angular_yaw = math.atan2(20, 5) - math.pi * 0.5
assert(smart_target_updates > 0 and
    math.abs(orientation.yaw - direct_yaw) < math.abs(orientation.yaw - angular_yaw),
    "a game-confirmed crosshair hit should win initial aim acquisition")
smart_direct_target = nil
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.9)
HEALTH_ALIVE[direct_pick], HEALTH_ALIVE[angular_pick] = false, false

local outside_fov = {}
units[outside_fov] = {
    breed = "renegade_sniper",
    position = Vector3(30, 5, 0),
    nodes = { j_head = Vector3(30, 5, 1.8) },
}
HEALTH_ALIVE[outside_fov], HEALTH_ALIVE[angular_pick] = true, true
smart_direct_target = outside_fov
camera_rotation = Vector3.normalize(Vector3(5, 20, 1.8))
orientation.yaw, orientation.pitch = 0, 0
held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.95)
assert(math.abs(orientation.yaw - angular_yaw) < math.abs(orientation.yaw -
    (math.atan2(5, 30) - math.pi * 0.5)),
    "native smart targeting should not bypass BallHammer's configured aim FOV")
smart_direct_target = nil
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.96)
HEALTH_ALIVE[outside_fov], HEALTH_ALIVE[angular_pick] = false, false

local lock_left, lock_right = {}, {}
units[lock_left] = { breed = "renegade_sniper", position = Vector3(4, 20, 0), mixed_vector = true }
units[lock_right] = { breed = "renegade_sniper", position = Vector3(20, 10, 0) }
HEALTH_ALIVE[lock_left], HEALTH_ALIVE[lock_right] = true, true
hooks["HealthExtension.init"](nil, nil, lock_left)
hooks["HealthExtension.init"](nil, nil, lock_right)
settings.aim_smoothness = 0
mod.on_setting_changed("aim_smoothness")
orientation.yaw, orientation.pitch = 0, 0
camera_rotation = Vector3.normalize(Vector3(4, 20, 0))
held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 4)
assert(orientation.yaw < 0, "initial acquisition should select the target nearest the crosshair")
last_constructed._valid = false
camera_rotation = Vector3.normalize(Vector3(20, 10, 0))
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 5)
local left_yaw = math.atan2(20, 4) - math.pi * 0.5
local right_yaw = math.atan2(10, 20) - math.pi * 0.5
assert(math.abs(orientation.yaw - left_yaw) < math.abs(orientation.yaw - right_yaw),
    "normal aim should keep its live target even after the crosshair leaves acquisition FOV")

local swap_target = {}
units[swap_target] = { breed = "renegade_sniper", position = Vector3(6, 20, 0) }
HEALTH_ALIVE[swap_target] = true
hooks["HealthExtension.init"](nil, nil, swap_target)
HEALTH_ALIVE[lock_right] = false
units[lock_left].position = Vector3(1, 20, 0)
camera_rotation = Vector3.normalize(Vector3(6, 20, 0))
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0.1, 5.1)
local swap_yaw = math.atan2(20, 6) - math.pi * 0.5
assert(math.abs(orientation.yaw - swap_yaw) < math.abs(orientation.yaw - left_yaw),
    "an occluded locked target should swap cleanly to the nearest visible target")

local death_target = {}
units[death_target] = { breed = "renegade_sniper", position = Vector3(8, 20, 0) }
HEALTH_ALIVE[death_target] = true
hooks["HealthExtension.init"](nil, nil, death_target)
HEALTH_ALIVE[swap_target] = false
camera_rotation = Vector3.normalize(Vector3(8, 20, 0))
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0.2, 5.2)
local death_yaw = math.atan2(20, 8) - math.pi * 0.5
assert(math.abs(orientation.yaw - death_yaw) < math.abs(orientation.yaw - swap_yaw),
    "a dead locked target should swap cleanly to the nearest visible target")

for target_unit in pairs(units) do HEALTH_ALIVE[target_unit] = false end
local activation_target = {}
units[activation_target] = { breed = "renegade_sniper", position = Vector3(4, 20, 0) }
HEALTH_ALIVE[activation_target] = true
hooks["HealthExtension.init"](nil, nil, activation_target)
settings.aim_activation = "both_mouse"
mod.on_setting_changed("aim_activation")
orientation.yaw, orientation.pitch = 0, 0
held_action = "action_one_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0.8, 8)
assert(orientation.yaw < 0, "either-mouse activation should accept left mouse")
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0.9, 9)
orientation.yaw, orientation.pitch = 0, 0
held_action = "action_two_hold"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 1.0, 10)
assert(orientation.yaw < 0, "either-mouse activation should accept right mouse")

settings.aim_activation = "left_mouse"
mod.on_setting_changed("aim_activation")
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 1.05, 10)
held_action = "action_one_hold"
shot_ready = true
assert(not parsed_fire_pressed,
    "semi-automatic repeat fire must not forge action_one_pressed inside Darktide's input parser")
local input_values = { action_one_hold = true }
local input_service = {
    get_with_filters = function(_, action) return input_values[action] or false end,
}
local input_handler = {
    _action_lookup = {
        action_one_hold = 1,
        action_one_pressed = 2,
        action_two_hold = 3,
        grenade_ability_pressed = 4,
        grenade_ability_hold = 5,
    },
    _frame = 11,
    _player = player,
}
local network_input_cache = { {}, {}, {}, {}, {} }
local function parse_network_input(index)
    HumanInputHandler._parse_input(input_handler, network_input_cache, input_service, index)
    input_handler._frame = input_handler._frame + 1
    return network_input_cache[2][index], network_input_cache[4][index],
        network_input_cache[5][index], network_input_cache[1][index]
end
assert(parse_network_input(1),
    "semi-automatic fire must add its press to Darktide's networked input frame")
assert(not parse_network_input(2),
    "semi-automatic fire should send only one press per weapon action")
hooks["ActionInputParser.mispredict_happened"]({
    _player = player,
    _action_component_name = "weapon_action",
})
assert(parse_network_input(2.5),
    "multiplayer rollback should allow the same weapon action press to be resent")
weapon_action_component.start_t = 1.1
assert(parse_network_input(3),
    "semi-automatic fire should send the next press after the weapon action advances")
settings.enable_auto_fire = false
mod.on_setting_changed("enable_auto_fire")
weapon_action_component.start_t = 1.2
assert(not parse_network_input(4),
    "semi-automatic repeat fire should respect its independent weapon setting")
settings.enable_auto_fire = true
mod.on_setting_changed("enable_auto_fire")
shot_ready = false
assert(not parse_network_input(5),
    "semi-automatic fire should wait for Darktide's action timing")
shot_ready = true
assert(parse_network_input(6),
    "semi-automatic fire should send when Darktide accepts the action")

weapon_action_inputs = {
    shoot_pressed = {
        input_sequence = { { input = "action_one_hold", value = true } },
    },
}
weapon_action_component.template.action_inputs = weapon_action_inputs
weapon_action_component.start_t = 1.3
assert(not parse_network_input(7),
    "holding mouse one should not repeat presses for an automatic fire action")
weapon_action_inputs = {
    shoot = {
        input_sequence = { { input = "action_one_pressed", value = true } },
    },
    zoom_shoot = {
        input_sequence = { { input = "action_one_pressed", value = true } },
    },
}
weapon_action_component.template.action_inputs = weapon_action_inputs
weapon_action_component.start_t = 1.4
assert(parse_network_input(8),
    "press-driven weapons named shoot should repeat with Darktide's native timing")
input_values.action_one_hold = false
assert(not parse_network_input(9),
    "releasing mouse one should stop and reset semi-automatic fire")

settings.aim_activation = "off"
settings.trigger_activation = "custom"
settings.trigger_fov = 5
settings.trigger_fire_fov = 0.8
settings.trigger_smoothness = 0
mod.on_setting_changed("aim_activation")
mod.on_setting_changed("trigger_activation")
mod.on_setting_changed("trigger_fov")
mod.on_setting_changed("trigger_fire_fov")
mod.on_setting_changed("trigger_smoothness")
camera_rotation = Vector3.normalize(Vector3(4, 20, 0))
orientation.yaw = math.atan2(20, 4) - math.pi * 0.5
orientation.pitch = 0
weapon_action_component.start_t = 1.5
mod.triggerbot_held(true)
hooks["PlayerUnitFirstPersonExtension.fixed_update"](
    first_person_extension, player_unit, 0.1, 2.0, 20
)
input_handler._frame = 21
local trigger_pressed, _, _, trigger_hold = parse_network_input(10)
assert(trigger_pressed and trigger_hold,
    "triggerbot fire must be written into Darktide's networked input frame")
mod.triggerbot_held(false)
weapon_action_component.start_t = 1.6
local released_trigger_pressed = parse_network_input(11)
assert(not released_trigger_pressed,
    "releasing the trigger bind must cancel generated fire without a sticky mouse-one frame")

for target_unit in pairs(units) do HEALTH_ALIVE[target_unit] = false end
local rage_target = {}
units[rage_target] = {
    breed_data = {
        name = "chaos_hound",
        base_height = 1.4,
        smart_tag_target_type = "breed",
        tags = { minion = true, special = true },
    },
    position = Vector3(4, 20, 0),
}
HEALTH_ALIVE[rage_target] = true
hooks["HealthExtension.init"](nil, nil, rage_target)
settings.aim_fov = 5
settings.rage_distance = 120
settings.rage_smoothness = 0
mod.on_setting_changed("aim_fov")
mod.on_setting_changed("rage_distance")
mod.on_setting_changed("rage_smoothness")
camera_rotation = Vector3(0, 1, 0)
orientation.yaw = math.atan2(20, 4) - math.pi * 0.5
orientation.pitch = 0
weapon_action_component.start_t = 1.7
mod.rage_held(true)
hooks["PlayerUnitFirstPersonExtension.fixed_update"](
    first_person_extension, player_unit, 0.1, 2.2, 22
)
input_handler._frame = 23
local rage_pressed, _, _, rage_hold = parse_network_input(12)
assert(rage_pressed and rage_hold,
    "rage must acquire a visible on-screen target outside normal FOV and network its shot")
mod.rage_held(false)
weapon_action_component.start_t = 1.8
assert(not parse_network_input(13),
    "releasing rage must cancel generated fire")

for target_unit in pairs(units) do HEALTH_ALIVE[target_unit] = false end
local companion_hound, companion_gunner = {}, {}
units[companion_hound] = {
    breed_data = {
        name = "chaos_hound",
        base_height = 1.4,
        smart_tag_target_type = "breed",
        tags = { minion = true, special = true },
    },
    position = Vector3(8, 20, 0),
    health = 1,
}
units[companion_gunner] = {
    breed_data = {
        name = "cultist_gunner",
        base_height = 1.8,
        smart_tag_target_type = "breed",
        tags = { minion = true, elite = true },
    },
    position = Vector3(2, 5, 0),
    health = 0.1,
}
HEALTH_ALIVE[companion_hound], HEALTH_ALIVE[companion_gunner] = true, true
hooks["HealthExtension.init"](nil, nil, companion_hound)
hooks["HealthExtension.init"](nil, nil, companion_gunner)
settings.enable_companion_target = true
settings.companion_distance = 60
mod.on_setting_changed("enable_companion_target")
mod.on_setting_changed("companion_distance")
companion_can_order = true
held_action = nil
local companion_yaw, companion_pitch = orientation.yaw, orientation.pitch
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 2.0, 20)
assert(companion_orders[1] and companion_orders[1].tagger == player_unit and
    companion_orders[1].target == companion_gunner and companion_orders[1].alternate == "companion_order",
    "companion auto-target should issue the native order for the highest weighted special")
assert(orientation.yaw == companion_yaw and orientation.pitch == companion_pitch,
    "companion targeting must not move the player's aim")
units[companion_hound].position = Vector3(1, 2, 0)
units[companion_hound].health = 0
units[companion_gunner].position = Vector3(2, 70, 0)
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 2.4, 24)
assert(#companion_orders == 1,
    "temporary range or visibility loss should not bypass the companion damage gate")
hooks["AttackReportManager.add_attack_result"](
    {}, {}, companion_gunner, {}, {}, nil, false, 10
)
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 2.8, 28)
assert(#companion_orders == 1,
    "damage from someone other than the local companion must not unlock retargeting")
hooks["AttackReportManager.add_attack_result"](
    {}, {}, companion_gunner, companion_unit, {}, nil, false, 10
)
input_handler._frame = 31
local _, grenade_pressed = parse_network_input(20)
assert(not grenade_pressed,
    "companion damage must not network a different Arbites grenade ability")
whistle_equipped = true
settings.enable_auto_whistle = true
mod.on_setting_changed("enable_auto_whistle")
hooks["AttackReportManager.add_attack_result"](
    {}, {}, companion_gunner, companion_unit, {}, nil, false, 10
)
_, grenade_pressed = parse_network_input(21)
assert(not grenade_pressed,
    "the Arbites whistle must not fire without an available charge")
whistle_charged = true
whistle_action_valid = false
hooks["AttackReportManager.add_attack_result"](
    {}, {}, companion_gunner, companion_network_unit, {}, nil, false, 0,
    nil, "companion_dog"
)
_, grenade_pressed = parse_network_input(22)
assert(not grenade_pressed,
    "the Arbites whistle should wait until Darktide's ability parser accepts the input")
whistle_action_valid = true
local _, network_grenade_pressed, network_grenade_hold = parse_network_input(23)
assert(network_grenade_pressed and network_grenade_hold,
    "a zero-damage dog contact must still network a charged Arbites whistle")
_, network_grenade_pressed, network_grenade_hold = parse_network_input(24)
assert(not network_grenade_pressed and not network_grenade_hold,
    "automatic dog EMP must release after its native press and hold sequence")
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 3.2, 32)
assert(companion_orders[2] and companion_orders[2].target == companion_hound,
    "companion damage should unlock a switch to a more dangerous target")
settings.enable_auto_whistle = false
mod.on_setting_changed("enable_auto_whistle")
units[companion_hound].position = Vector3(8, 50, 0)
units[companion_hound].health = 1
units[companion_gunner].position = Vector3(2, 5, 0)
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 3.6, 36)
assert(#companion_orders == 2,
    "a fresh companion order should remain damage-gated during its travel window")
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 6.21, 62)
assert(companion_orders[3] and companion_orders[3].target == companion_gunner,
    "a rejected companion order should eventually release its distance-based wait")
HEALTH_ALIVE[companion_gunner] = false
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 6.22, 63)
assert(companion_orders[4] and companion_orders[4].target == companion_hound,
    "a dead commanded target should unlock an immediate replacement")
hooks["AttackReportManager.add_attack_result"](
    {}, {}, companion_hound, companion_unit, {}, nil, false, 10
)
input_handler._frame = 64
_, network_grenade_pressed = parse_network_input(25)
assert(not network_grenade_pressed,
    "automatic dog EMP should respect its independent companion setting")
settings.enable_auto_whistle = true
mod.on_setting_changed("enable_auto_whistle")
_, network_grenade_pressed = parse_network_input(26)
assert(not network_grenade_pressed,
    "automatic dog EMP must wait for confirmed dog attack damage")
BLACKBOARDS[companion_unit] = {
    behavior = { move_state = "attacking" },
    pounce = { has_pounce_started = true, pounce_target = companion_hound },
}
hooks["PlayerUnitFirstPersonExtension.fixed_update"](
    first_person_extension, player_unit, 0.1, 6.235, 65
)
_, network_grenade_pressed, network_grenade_hold = parse_network_input(27)
assert(network_grenade_pressed and network_grenade_hold,
    "owned dog contact should network the EMP press and hold")
input_handler._frame = 1
_, network_grenade_pressed, network_grenade_hold = parse_network_input(28)
assert(not network_grenade_pressed and not network_grenade_hold,
    "a gameplay-time rewind must cancel an active automatic whistle hold")
HEALTH_ALIVE[companion_gunner] = true
units[companion_gunner].position = Vector3(8, 50, 0)
units[companion_hound].position = Vector3(2, 5, 0)
disabling_unit = companion_gunner
disabling_type = "netted"
local orders_before_rescue = #companion_orders
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 6.25, 66)
assert(#companion_orders == orders_before_rescue,
    "Darktide's native-excluded netted state should not trigger a rescue override")
disabling_type = "pounced"
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 6.3, 67)
assert(#companion_orders == orders_before_rescue + 1
    and companion_orders[#companion_orders].target == companion_gunner,
    "a local-player disabling attacker must override normal companion targeting")
disabling_unit = nil
disabling_type = "none"

for target_unit in pairs(units) do HEALTH_ALIVE[target_unit] = false end
held_action = "action_one_hold"
local no_target_ok, no_target_error = pcall(
    hooks["PlayerUnitFirstPersonExtension.fixed_update"],
    first_person_extension, player_unit, 0.1, 1.7, 17
)
assert(no_target_ok, "holding aim without a valid target should be a no-op: " .. tostring(no_target_error))
print("BallHammer aim smoke: ok")
