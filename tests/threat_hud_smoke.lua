local threat_text = "DODGE 0.2"
local show_status, show_compass, show_players = true, true, true
local hud_opacity = 80
local threat_unit = {}
local player_unit = {}
local positions = {
    [threat_unit] = { x = 10, y = 10, z = 3 },
    [player_unit] = { x = 0, y = 2, z = 0 },
}
local threat_data = {
    [threat_unit] = {
        name = "Mutant",
        flag = "SPECIAL",
        companion_danger = 1,
    },
}
local active_threat = { source = threat_unit, kind = "mutant" }
local status_rows = {
    { label = "AIM", key = "LMB", state = "LOCKED", tone = "active" },
    { label = "TRIGGER", key = "RMB", state = "FIRING", tone = "danger" },
    { label = "RAGE", key = "Z", state = "IDLE", tone = "idle" },
    { label = "GUARD", key = "AUTO", state = "READY", tone = "ready" },
    { label = "GOVERNOR", key = "AUTO", state = "OFF", tone = "idle" },
}
local mod = {
    enabled = true,
    get_threat_indicator = function() return threat_text end,
    get_hud_status_rows = function() return status_rows end,
    get_hud_threats = function()
        return threat_data, active_threat
    end,
    get_hud_settings = function()
        return show_status, show_compass, 80, show_players, hud_opacity
    end,
}

get_mod = function() return mod end
package.preload["scripts/settings/ui/ui_workspace_settings"] = function()
    return { screen = { size = { 1920, 1080 }, position = { 0, 0, 0 } } }
end
package.preload["scripts/managers/ui/ui_widget"] = function()
    return { create_definition = function(passes, scenegraph_id)
        return { passes = passes, scenegraph_id = scenegraph_id }
    end }
end
package.preload["scripts/foundation/utilities/script_camera"] = function()
    return { position = function(camera) return camera.position end }
end
package.preload[
    "scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout"
] = function()
    return { slot_equipped = function() return false end }
end
package.preload["scripts/utilities/ammo"] = function()
    return {
        current_ammo_in_clips = function() return 10 end,
        max_ammo_in_clips = function() return 20 end,
    }
end

local vector_mt = {
    __sub = function(a, b)
        return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, vector_mt)
    end,
}
local function vector(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, vector_mt)
end
for unit, value in pairs(positions) do positions[unit] = vector(value.x, value.y, value.z) end

Vector3 = {
    length = function(value)
        return math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
    end,
    normalize = function(value)
        local length = math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
        return length > 0 and vector(value.x / length, value.y / length, value.z / length)
            or vector(0, 0, 0)
    end,
    cross = function(a, b)
        return vector(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x)
    end,
    dot = function(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end,
    up = function() return vector(0, 0, 1) end,
}
Quaternion = { forward = function() return vector(0, 1, 0) end }
Camera = { local_rotation = function() return {} end }
Unit = { world_position = function(unit) return positions[unit] end }
ALIVE = { [threat_unit] = true, [player_unit] = true }
HEALTH_ALIVE = { [threat_unit] = true, [player_unit] = true }
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local health = { current_health_percent = function() return 0.75 end }
local toughness = { current_toughness_percent = function() return 0.5 end }
local unit_data = {
    has_component = function(_, name) return name == "slot_secondary" end,
    read_component = function(_, name)
        if name == "slot_secondary" then
            return { current_ammunition_reserve = 30, max_ammunition_reserve = 60 }
        end
        if name == "disabled_character_state" then return { is_disabled = false } end
        if name == "inventory" then return {} end
    end,
}
local ability = { remaining_ability_charges = function() return 2 end }
ScriptUnit = { has_extension = function(unit, name)
    if unit ~= player_unit then return nil end
    return ({
        health_system = health,
        toughness_system = toughness,
        unit_data_system = unit_data,
        visual_loadout_system = {},
        ability_system = ability,
    })[name]
end }
local player = {
    player_unit = player_unit,
    name = function() return "Veteran" end,
    profile = function() return { archetype = { name = "veteran" } } end,
    unit_is_alive = function() return true end,
}
local camera = { position = vector(0, 0, 0) }
local game_mode_name = "coop_complete_objective"
Managers = {
    state = { game_mode = {
        game_mode_name = function() return game_mode_name end,
    } },
    player = {
    players = function() return { one = player } end,
    local_player = function() return player end,
} }

local function make_widget(definition)
    local widget = { content = {}, style = {}, offset = { 0, 0, 0 } }
    for _, pass in ipairs(definition.passes) do
        if pass.style_id then widget.style[pass.style_id] = pass.style end
        if pass.value_id then widget.content[pass.value_id] = pass.value end
    end
    return widget
end

HudElementBase = {
    init = function(self, parent, _, _, definitions)
        self._parent = parent
        self.definitions = definitions
        self._widgets_by_name = {}
        for name, definition in pairs(definitions.widget_definitions) do
            self._widgets_by_name[name] = make_widget(definition)
        end
    end,
    update = function() end,
}
class = function(name, parent_name)
    local value = { super = _G[parent_name] }
    _G[name] = value
    return value
end

local ThreatHud = dofile("scripts/mods/BallHammer/BallHammerThreatHud.lua")
local element = setmetatable({}, { __index = ThreatHud })
local parent = { player_camera = function() return camera end }
element:init(parent, 1, 1)

local threat_position = element.definitions.scenegraph_definition.threat.position
assert(threat_position[1] == 0 and threat_position[2] > 0,
    "danger indicator must stay fixed below the crosshair")

element:update(0.016, 1, nil, {}, nil)
assert(element._widgets_by_name.threat.content.visible
    and element._widgets_by_name.threat.content.text == "DODGE 0.2",
    "active danger should render in the static HUD widget")
assert(element._widgets_by_name.status_header.content.visible
    and element._widgets_by_name.status_2.content.state == "FIRING",
    "system panel should render configured keys and live states")
assert(element._widgets_by_name.status_header.style.accent == nil
    and element._widgets_by_name.status_1.style.accent == nil,
    "system status rows should not render decorative state ticks")
assert(element._widgets_by_name.compass.content.visible
    and element._widgets_by_name.compass_threat_1.content.visible
    and element._widgets_by_name.compass_threat_1.offset[1] > 0
    and element._widgets_by_name.compass_threat_1.content.text:find("MUTANT", 1, true),
    "threat compass should project a named threat to its camera-relative bearing")
assert(element._widgets_by_name.player_header.content.visible
    and element._widgets_by_name.player_1.content.name == "Veteran"
    and element._widgets_by_name.player_1.content.stats:find("HP 75", 1, true)
    and element._widgets_by_name.player_1.content.stats:find("AMMO 50%%"),
    "squad list should render native health, toughness, ammo, and grenade data")
assert(element._widgets_by_name.status_1.style.label.text_color[1] == 204
    and element._widgets_by_name.compass.style.line.color[1] == 144
    and element._widgets_by_name.player_1.style.stats.text_color[1] == 188,
    "shared HUD opacity should apply to text, accents, and compass surfaces")

local crowded_units = { {}, {}, {} }
for i = 1, #crowded_units do
    local unit = crowded_units[i]
    positions[unit] = vector(10, 10, 3)
    ALIVE[unit], HEALTH_ALIVE[unit] = true, true
    threat_data[unit] = {
        name = "Rager " .. i,
        flag = "SPECIAL",
        companion_danger = 0.8,
    }
end
element:update(0.016, 1.2, nil, {}, nil)
assert(element._widgets_by_name.compass_threat_1.content.visible
    and element._widgets_by_name.compass_threat_2 == nil
    and element._widgets_by_name.compass_threat_1.content.text:find("MUTANT", 1, true)
    and element._widgets_by_name.compass_threat_1.offset[2] == 0,
    "threat compass should show only the committed threat")
for i = 1, #crowded_units do
    threat_data[crowded_units[i]] = nil
    HEALTH_ALIVE[crowded_units[i]] = false
end

positions[threat_unit] = vector(-10, 10, 3)
element:update(0.016, 1.32, nil, {}, nil)
assert(element._widgets_by_name.compass_threat_1.offset[1] < 0,
    "bearing should follow camera-relative movement every frame between scans")

HEALTH_ALIVE[threat_unit] = false
active_threat.danger_position = { unbox = function() return vector(-10, 10, 3) end }
element:update(0.016, 1.44, nil, {}, nil)
assert(not element._widgets_by_name.compass_threat_1.content.visible,
    "dead enemies should leave the threat compass before their unit despawns")

threat_data[threat_unit] = nil
active_threat = {
    kind = "grenade",
    danger_position = { unbox = function() return vector(8, 6, 0) end },
}
element:update(0.016, 1.56, nil, {}, nil)
assert(element._widgets_by_name.compass_threat_1.content.text:find("GRENADE", 1, true),
    "committed position-only threats should remain visible on the compass")

local unmapped_threat = {}
positions[unmapped_threat] = vector(4, 6, 0)
ALIVE[unmapped_threat], HEALTH_ALIVE[unmapped_threat] = true, true
active_threat = { source = unmapped_threat, kind = "rager" }
element:update(0.016, 1.7, nil, {}, nil)
assert(element._widgets_by_name.compass_threat_1.content.text:find("RAGER", 1, true),
    "committed threats should not depend on ESP metadata")

game_mode_name = "hub"
element:update(0.016, 1.71, nil, {}, nil)
assert(not element._widgets_by_name.threat.content.visible
    and not element._widgets_by_name.status_header.content.visible
    and not element._widgets_by_name.compass.content.visible
    and not element._widgets_by_name.compass_threat_1.content.visible
    and not element._widgets_by_name.player_header.content.visible,
    "the tactical HUD should hide immediately in the Mourningstar")

game_mode_name = nil
element:update(0.016, 1.72, nil, {}, nil)
assert(not element._widgets_by_name.compass.content.visible,
    "the tactical HUD should stay hidden while game mode state is unavailable")

game_mode_name = "coop_complete_objective"
threat_text = nil
show_status, show_compass, show_players = false, false, false
element:update(0.016, 2.0, nil, {}, nil)
assert(not element._widgets_by_name.threat.content.visible
    and not element._widgets_by_name.status_header.content.visible
    and not element._widgets_by_name.compass.content.visible
    and not element._widgets_by_name.player_header.content.visible,
    "every tactical HUD surface should obey its master switch")

print("BallHammer tactical HUD smoke: ok")
