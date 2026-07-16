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
    horde_distance = 80,
    max_distance = 80,
    outline_distance = 30,
    enable_aimbot = true,
    aim_distance = 80,
    aim_fov = 30,
    aim_smoothness = 55,
    aim_curve = 20,
    aim_location = "head",
    aim_activation = "left_mouse",
}
local messages = {}
local hooks = {}
local parsed_fire_pressed = false
local shot_ready = false
local recoil_calls = 0
local recoil_offset_calls = 0
local recoil_api = {
    first_person_offset = function(_, recoil)
        recoil_offset_calls = recoil_offset_calls + 1
        return recoil.pitch_offset, recoil.yaw_offset
    end,
    add_recoil = function()
        recoil_calls = recoil_calls + 1
    end,
}
package.preload["scripts/utilities/recoil"] = function()
    return recoil_api
end
package.preload["scripts/utilities/weapon/weapon_template"] = function()
    return { current_weapon_template = function(component) return component.template end }
end
local mod = {
    get = function(_, key) return settings[key] end,
    io_dofile = function(_, path)
        return { name = path:find("HordeMarker") and "ballhammer_horde_marker" or "ballhammer_marker" }
    end,
    command = function() end,
    echo = function(_, message) messages[#messages + 1] = message end,
    hook_safe = function(_, object, method, handler)
        if type(object) == "string" then hooks[object .. "." .. method] = handler end
    end,
    hook = function(_, object, method, handler)
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
    PlayerUnitActionInputExtension = {
        fixed_update = function()
            parsed_fire_pressed = CLASS.PlayerUnitInputExtension.get(
                { _is_local_unit = true }, "action_one_pressed"
            )
        end,
    },
    PlayerUnitWeaponSpreadExtension = {
        randomized_spread = function(_, rotation) return { spread = rotation } end,
        target_style_spread = function(_, rotation) return { spread = rotation } end,
    },
}
local player_unit = {}
HEALTH_ALIVE = {}
ALIVE = { [player_unit] = true }
local orientation = { yaw = 0, pitch = 0 }
local player = {
    player_unit = player_unit,
    unit_is_alive = function() return true end,
    get_orientation = function() return orientation end,
    set_orientation = function(_, yaw, pitch, roll)
        orientation.yaw, orientation.pitch, orientation.roll = yaw, pitch, roll
    end,
}
local marker_events = {}
local held_action = "action_one_hold"
local preexisting_units = {}
local weapon_action_inputs = {
    shoot_pressed = {
        input_sequence = { { input = "action_one_pressed", value = true } },
    },
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
        extension = {
            get_entities = function(_, name)
                assert(name == "MinionUnitDataExtension")
                return preexisting_units
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
ScriptUnit = {
    has_extension = function(unit, system)
        if unit == player_unit then
            return {
                read_component = function(_, name)
                    if name == "first_person" then
                        return { position = Vector3(0, 0, 0), rotation = camera_rotation }
                    end
                    if name == "weapon_action" then
                        return { template = { action_inputs = weapon_action_inputs } }
                    end
                    return { yaw_offset = 0, pitch_offset = 0, offset_x = 0, offset_y = 0 }
                end,
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
    raycast = function(world, _, direction)
        assert(world == physics_world, "raycast should use the gameplay physics world")
        local direction_x = Vector3.to_elements(direction)
        if direction_x < 0.15 then return { { false, false, false, {} } } end
        local closest
        for unit, data in pairs(units) do
            if HEALTH_ALIVE[unit] then
                local unit_direction = Vector3.normalize(data.position)
                local unit_direction_x = Vector3.to_elements(unit_direction)
                if math.abs(unit_direction_x - direction_x) < 0.001 then closest = unit end
            end
        end
        return closest and { { false, false, false, { unit = closest } } } or nil
    end,
}

dofile("scripts/mods/BallHammer/BallHammer.lua")
assert(messages[#messages] == "Loaded! - By @luinbytes",
    "load banner should use the requested credit")

local rotation = {}
assert(CLASS.PlayerUnitWeaponSpreadExtension.randomized_spread({ _unit = player_unit }, rotation).spread == rotation,
    "BallHammer should not override weapon spread")
assert(CLASS.PlayerUnitWeaponSpreadExtension.target_style_spread({ _unit = player_unit }, rotation).spread == rotation,
    "BallHammer should not override pellet spread")
recoil_api.add_recoil(0, nil, nil, nil, nil, nil, nil, nil, player_unit)
assert(recoil_calls == 1, "BallHammer should not override weapon recoil")

hooks["HudElementWorldMarkers.init"]({ _marker_templates = {} })
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
    _weapon_extension = {
        recoil_template = function() return {} end,
        action_input_is_currently_valid = function() return shot_ready end,
    },
    _recoil_component = { pitch_offset = 0, yaw_offset = 0 },
    _movement_state_component = {},
    _locomotion_component = {},
    _inair_state_component = {},
    _input_extension = {
        get = function(_, action) return action == held_action end,
    },
    is_within_default_view = function(_, position)
        local _, y = Vector3.to_elements(position)
        return y > 0
    end,
}
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 0)
assert(recoil_offset_calls == 0,
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
local fallback_yaw = math.atan2(10, 2) - math.pi * 0.5
local fallback_alpha = 1 - math.exp(-(2 + 100 * 0.22) * 0.1)
assert(math.abs(orientation.yaw - fallback_yaw * fallback_alpha) < 0.0001,
    "aim visibility should fall back from an occluded head to a visible configured bone")
HEALTH_ALIVE[fallback_bone_target] = false
held_action = nil
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 0, 3.7)

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
held_action = "action_one_hold"
shot_ready = true
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 1.1, 11)
local remote_unit = {}
CLASS.PlayerUnitActionInputExtension.fixed_update({}, remote_unit, 0.1, 1.1, 11)
assert(not parsed_fire_pressed,
    "another player's input update should not consume the local synthetic shot")
CLASS.PlayerUnitActionInputExtension.fixed_update({}, player_unit, 0.1, 1.1, 11)
assert(parsed_fire_pressed, "holding mouse one should fire a ready semi-automatic weapon")
CLASS.PlayerUnitActionInputExtension.fixed_update({}, player_unit, 0.1, 1.11, 11)
assert(not parsed_fire_pressed, "semi-automatic fire should emit one press per ready shot")
shot_ready = false
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 1.2, 12)
CLASS.PlayerUnitActionInputExtension.fixed_update({}, player_unit, 0.1, 1.2, 12)
assert(not parsed_fire_pressed, "semi-automatic fire should wait for Darktide's action timing")
shot_ready = true
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 1.3, 13)
CLASS.PlayerUnitActionInputExtension.fixed_update({}, player_unit, 0.1, 1.3, 13)
assert(parsed_fire_pressed, "semi-automatic fire should press again when the weapon is ready")

weapon_action_inputs = {
    shoot_pressed = {
        input_sequence = { { input = "action_one_hold", value = true } },
    },
}
hooks["PlayerUnitFirstPersonExtension.fixed_update"](first_person_extension, player_unit, 0.1, 1.4, 14)
CLASS.PlayerUnitActionInputExtension.fixed_update({}, player_unit, 0.1, 1.4, 14)
assert(not parsed_fire_pressed,
    "holding mouse one should not inject presses for an automatic fire action")

for target_unit in pairs(units) do HEALTH_ALIVE[target_unit] = false end
held_action = "action_one_hold"
local no_target_ok, no_target_error = pcall(
    hooks["PlayerUnitFirstPersonExtension.fixed_update"],
    first_person_extension, player_unit, 0.1, 1.7, 17
)
assert(no_target_ok, "holding aim without a valid target should be a no-op: " .. tostring(no_target_error))
print("BallHammer aim smoke: ok")
