local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local ScriptCamera = require("scripts/foundation/utilities/script_camera")
local PlayerUnitVisualLoadout = require(
    "scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout"
)
local Ammo = require("scripts/utilities/ammo")
local mod = get_mod("BallHammer")

local MAX_THREATS = 8
local MAX_PLAYERS = 4
local COMPASS_WIDTH = 520
local COMPASS_HALF = COMPASS_WIDTH * 0.5 - 24
local THREAT_SCAN_INTERVAL = 0.1
local STATUS_INTERVAL = 0.1
local PLAYER_INTERVAL = 0.25
local TONE_COLORS = {
    idle = { 255, 128, 137, 148 },
    ready = { 255, 105, 220, 145 },
    active = { 255, 255, 194, 70 },
    danger = { 255, 255, 82, 82 },
}
local BOSS_COLOR = { 255, 210, 100, 255 }
local CLASS_NAMES = {
    veteran = "Veteran",
    zealot = "Zealot",
    psyker = "Psyker",
    ogryn = "Ogryn",
    adamant = "Arbites",
    broker = "Hive Scum",
    cryptic = "Skitarii",
}

local function visible(content)
    return content.visible
end

local function rect(color, offset, size)
    return {
        color = color,
        offset = offset,
        size = size,
    }
end

local function text_style(size, alignment, color, offset)
    return {
        font_type = "mono_tide_regular",
        font_size = size,
        text_horizontal_alignment = alignment,
        text_vertical_alignment = "center",
        text_color = color,
        offset = offset,
    }
end

local scenegraph = {
    screen = UIWorkspaceSettings.screen,
    threat = {
        parent = "screen",
        size = { 108, 20 },
        vertical_alignment = "center",
        horizontal_alignment = "center",
        position = { 0, 52, 10 },
    },
    compass = {
        parent = "screen",
        size = { COMPASS_WIDTH, 58 },
        vertical_alignment = "top",
        horizontal_alignment = "center",
        position = { 0, 86, 5 },
    },
    status_header = {
        parent = "screen",
        size = { 260, 24 },
        vertical_alignment = "top",
        horizontal_alignment = "right",
        position = { -26, 176, 5 },
    },
    player_header = {
        parent = "screen",
        size = { 300, 24 },
        vertical_alignment = "top",
        horizontal_alignment = "right",
        position = { -26, 346, 5 },
    },
}

for i = 1, 5 do
    scenegraph["status_" .. i] = {
        parent = "status_header",
        size = { 260, 22 },
        vertical_alignment = "top",
        horizontal_alignment = "center",
        position = { 0, 24 + (i - 1) * 23, 1 },
    }
end
for i = 1, MAX_THREATS do
    scenegraph["compass_threat_" .. i] = {
        parent = "compass",
        size = { 100, 18 },
        vertical_alignment = "center",
        horizontal_alignment = "center",
        position = { 0, 0, 3 },
    }
end
for i = 1, MAX_PLAYERS do
    scenegraph["player_" .. i] = {
        parent = "player_header",
        size = { 300, 38 },
        vertical_alignment = "top",
        horizontal_alignment = "center",
        position = { 0, 24 + (i - 1) * 40, 1 },
    }
end

local widgets = {
    threat = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style = rect({ 150, 8, 10, 12 }, { 0, 0, 1 }, { 108, 20 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style = rect({ 255, 255, 90, 90 }, { -53, 0, 2 }, { 2, 20 }),
        },
        {
            pass_type = "text",
            value_id = "text",
            value = "",
            visibility_function = visible,
            style = text_style(13, "center", { 255, 255, 225, 225 }, { 0, 0, 3 }),
        },
    }, "threat"),
    compass = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "background",
            style = rect({ 150, 5, 8, 12 }, { 0, 0, 0 }, { COMPASS_WIDTH, 58 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "line",
            style = rect({ 180, 150, 160, 170 }, { 0, 0, 1 }, { COMPASS_WIDTH - 16, 1 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "center",
            style = rect({ 255, 235, 226, 168 }, { 0, 0, 2 }, { 2, 18 }),
        },
        {
            pass_type = "text",
            value = "THREATS",
            visibility_function = visible,
            style_id = "label",
            style = text_style(10, "center", { 210, 205, 210, 215 }, { 0, -22, 2 }),
        },
    }, "compass"),
    status_header = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "background",
            style = rect({ 190, 6, 9, 13 }, { 0, 0, 0 }, { 260, 24 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "accent",
            style = rect({ 255, 235, 226, 168 }, { -128, 0, 1 }, { 3, 22 }),
        },
        {
            pass_type = "text",
            value = "BALLHAMMER",
            visibility_function = visible,
            style_id = "text",
            style = text_style(12, "left", { 255, 235, 226, 168 }, { 9, 0, 2 }),
        },
    }, "status_header"),
    player_header = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "background",
            style = rect({ 190, 6, 9, 13 }, { 0, 0, 0 }, { 300, 24 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "accent",
            style = rect({ 255, 235, 226, 168 }, { -148, 0, 1 }, { 3, 22 }),
        },
        {
            pass_type = "text",
            value = "SQUAD",
            visibility_function = visible,
            style_id = "text",
            style = text_style(12, "left", { 255, 235, 226, 168 }, { 9, 0, 2 }),
        },
    }, "player_header"),
}

for i = 1, 5 do
    widgets["status_" .. i] = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "background",
            style = rect({ 150, 7, 10, 14 }, { 0, 0, 0 }, { 260, 22 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "accent",
            style = rect({ 255, 128, 137, 148 }, { -128, 0, 1 }, { 3, 20 }),
        },
        {
            pass_type = "text",
            value_id = "label",
            value = "",
            visibility_function = visible,
            style_id = "label",
            style = text_style(11, "left", { 255, 223, 226, 230 }, { 9, 0, 2 }),
        },
        {
            pass_type = "text",
            value_id = "key",
            value = "",
            visibility_function = visible,
            style_id = "key",
            style = text_style(10, "center", { 255, 152, 161, 171 }, { 0, 0, 2 }),
        },
        {
            pass_type = "text",
            value_id = "state",
            value = "",
            visibility_function = visible,
            style_id = "state",
            style = text_style(10, "right", { 255, 128, 137, 148 }, { -9, 0, 2 }),
        },
    }, "status_" .. i)
end

for i = 1, MAX_THREATS do
    widgets["compass_threat_" .. i] = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "pip",
            style = rect({ 255, 255, 194, 70 }, { 0, 8, 1 }, { 2, 8 }),
        },
        {
            pass_type = "text",
            value_id = "text",
            value = "",
            visibility_function = visible,
            style_id = "text",
            style = text_style(9, "center", { 255, 255, 194, 70 }, { 0, -3, 2 }),
        },
    }, "compass_threat_" .. i)
end

for i = 1, MAX_PLAYERS do
    widgets["player_" .. i] = UIWidget.create_definition({
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "background",
            style = rect({ 155, 7, 10, 14 }, { 0, 0, 0 }, { 300, 38 }),
        },
        {
            pass_type = "rect",
            visibility_function = visible,
            style_id = "accent",
            style = rect({ 255, 105, 220, 145 }, { -148, 0, 1 }, { 3, 36 }),
        },
        {
            pass_type = "text",
            value_id = "name",
            value = "",
            visibility_function = visible,
            style_id = "name",
            style = text_style(11, "left", { 255, 235, 238, 241 }, { 9, -8, 2 }),
        },
        {
            pass_type = "text",
            value_id = "class",
            value = "",
            visibility_function = visible,
            style_id = "class",
            style = text_style(9, "right", { 220, 170, 180, 190 }, { -9, -8, 2 }),
        },
        {
            pass_type = "text",
            value_id = "stats",
            value = "",
            visibility_function = visible,
            style_id = "stats",
            style = text_style(9, "left", { 235, 190, 198, 205 }, { 9, 8, 2 }),
        },
        {
            pass_type = "text",
            value_id = "state",
            value = "",
            visibility_function = visible,
            style_id = "state",
            style = text_style(9, "right", { 255, 105, 220, 145 }, { -9, 8, 2 }),
        },
    }, "player_" .. i)
end

local Definitions = {
    scenegraph_definition = scenegraph,
    widget_definitions = widgets,
}

local function set_color(color, source, alpha)
    color[1] = math.floor(source[1] * alpha + 0.5)
    color[2], color[3], color[4] = source[2], source[3], source[4]
end

local function alive(unit)
    return unit and ALIVE and ALIVE[unit]
end

local function unit_position(unit)
    return alive(unit) and Unit.world_position(unit, 1) or nil
end

local function extension(unit, name)
    return unit and ScriptUnit.has_extension(unit, name) or nil
end

local function percent(value)
    return math.floor(math.max(0, math.min(1, value or 0)) * 100 + 0.5)
end

BallHammerThreatHud = class("BallHammerThreatHud", "HudElementBase")

function BallHammerThreatHud:init(parent, draw_layer, start_scale)
    BallHammerThreatHud.super.init(self, parent, draw_layer, start_scale, Definitions)
    self._next_status_t = 0
    self._next_threat_scan_t = 0
    self._next_player_t = 0
    self._threat_candidates = {}
    self._selected_threats = {}
    self._display_threats = {}
    self._player_candidates = {}
    self._last_opacity = nil
    self._compass_visible = nil
    self._lane_x = { -math.huge, -math.huge, -math.huge }
    self._virtual_threat_data = { name = "THREAT", flag = "SPECIAL", companion_danger = 1 }
end

function BallHammerThreatHud:_apply_opacity(opacity)
    if opacity == self._last_opacity then return end
    self._last_opacity = opacity
    local alpha = math.max(0.2, math.min(1, opacity / 100))
    self._widgets_by_name.compass.style.background.color[1] = math.floor(150 * alpha)
    self._widgets_by_name.status_header.style.background.color[1] = math.floor(190 * alpha)
    self._widgets_by_name.player_header.style.background.color[1] = math.floor(190 * alpha)
    for i = 1, 5 do
        self._widgets_by_name["status_" .. i].style.background.color[1] = math.floor(150 * alpha)
    end
    for i = 1, MAX_PLAYERS do
        self._widgets_by_name["player_" .. i].style.background.color[1] = math.floor(155 * alpha)
    end
end

function BallHammerThreatHud:_refresh_status(visible_status)
    local header = self._widgets_by_name.status_header
    header.content.visible = visible_status
    local rows = mod.get_hud_status_rows()
    for i = 1, 5 do
        local widget = self._widgets_by_name["status_" .. i]
        local row = rows[i]
        widget.content.visible = visible_status
        widget.content.label = row.label
        widget.content.key = row.key
        widget.content.state = row.state
        local color = TONE_COLORS[row.tone] or TONE_COLORS.idle
        set_color(widget.style.accent.color, color, 1)
        set_color(widget.style.state.text_color, color, 1)
    end
end

local function threat_sort(a, b)
    if a.priority ~= b.priority then return a.priority > b.priority end
    return a.distance < b.distance
end

function BallHammerThreatHud:_refresh_threats(range)
    local camera = self._parent and self._parent.player_camera and self._parent:player_camera()
    local camera_position = camera and ScriptCamera.position(camera)
    local threat_map, active_threat = mod.get_hud_threats()
    local candidates = self._threat_candidates
    local count = 0
    local active_found = false
    if camera_position then
        for unit, data in pairs(threat_map) do
            local position = unit_position(unit)
            if position then
                local distance = Vector3.length(position - camera_position)
                if distance <= range then
                    count = count + 1
                    local candidate = candidates[count]
                    if not candidate then
                        candidate = {}
                        candidates[count] = candidate
                    end
                    candidate.unit = unit
                    candidate.position = nil
                    candidate.data = data
                    candidate.distance = distance
                    candidate.active = active_threat and active_threat.source == unit or false
                    active_found = active_found or candidate.active
                    candidate.label = string.format("%s %dm", data.name,
                        math.floor(distance + 0.5))
                    candidate.priority = candidate.active and 100
                        or data.flag == "BOSS" and 60
                        or (data.companion_danger or 0) * 40
                end
            end
        end
        if active_threat and not active_found then
            local position = unit_position(active_threat.source)
            local boxed_position = active_threat.danger_position
            if not position and boxed_position then
                local ok, value = pcall(function() return boxed_position:unbox() end)
                if ok then position = value end
            end
            if position then
                local distance = Vector3.length(position - camera_position)
                if distance <= range then
                    count = count + 1
                    local candidate = candidates[count]
                    if not candidate then
                        candidate = {}
                        candidates[count] = candidate
                    end
                    local data = self._virtual_threat_data
                    data.name = tostring(active_threat.kind or "THREAT"):gsub("_", " "):upper()
                    candidate.unit = nil
                    candidate.position = position
                    candidate.data = data
                    candidate.distance = distance
                    candidate.active = true
                    candidate.priority = 100
                    candidate.label = string.format("%s %dm", data.name,
                        math.floor(distance + 0.5))
                end
            end
        end
    end
    for i = count + 1, #candidates do candidates[i] = nil end
    table.sort(candidates, threat_sort)
    local selected = self._selected_threats
    local selected_count = math.min(count, MAX_THREATS)
    for i = 1, selected_count do selected[i] = candidates[i] end
    for i = selected_count + 1, #selected do selected[i] = nil end
end

local function bearing_sort(a, b)
    return a.x < b.x
end

function BallHammerThreatHud:_update_compass(visible_compass)
    local background = self._widgets_by_name.compass
    background.content.visible = visible_compass
    local visibility_changed = self._compass_visible ~= visible_compass
    self._compass_visible = visible_compass
    if not visible_compass then
        if visibility_changed then
            for i = 1, MAX_THREATS do
                self._widgets_by_name["compass_threat_" .. i].content.visible = false
            end
        end
        return
    end

    local camera = self._parent and self._parent.player_camera and self._parent:player_camera()
    if not camera then return end
    local camera_position = ScriptCamera.position(camera)
    local rotation = Camera.local_rotation(camera)
    local forward = Quaternion.forward(rotation)
    forward.z = 0
    forward = Vector3.normalize(forward)
    local right = Vector3.cross(forward, Vector3.up())
    local display = self._display_threats
    local count = 0
    for i = 1, #self._selected_threats do
        local candidate = self._selected_threats[i]
        local position = candidate.position or unit_position(candidate.unit)
        if position then
            local delta = position - camera_position
            local height = delta.z
            delta.z = 0
            delta = Vector3.normalize(delta)
            local angle = math.atan2(Vector3.dot(right, delta), Vector3.dot(forward, delta))
            count = count + 1
            local item = display[count]
            if not item then
                item = {}
                display[count] = item
            end
            item.candidate = candidate
            item.x = angle / math.pi * COMPASS_HALF
            item.height = height
        end
    end
    for i = count + 1, #display do display[i] = nil end
    table.sort(display, bearing_sort)

    local lane_x = self._lane_x
    lane_x[1], lane_x[2], lane_x[3] = -math.huge, -math.huge, -math.huge
    for i = 1, count do
        local item = display[i]
        local candidate = item.candidate
        local lane = 1
        while lane < 3 and item.x - lane_x[lane] < 90 do lane = lane + 1 end
        lane_x[lane] = item.x
        local widget = self._widgets_by_name["compass_threat_" .. i]
        local data = candidate.data
        local arrow = item.height > 2 and "^" or item.height < -2 and "v" or ""
        if widget.content.base_label ~= candidate.label or widget.content.arrow ~= arrow then
            widget.content.base_label = candidate.label
            widget.content.arrow = arrow
            widget.content.text = candidate.label .. arrow
        end
        widget.content.visible = true
        widget.offset[1] = item.x
        widget.offset[2] = (lane - 2) * 15
        local source = candidate.active and TONE_COLORS.danger
            or data.flag == "BOSS" and BOSS_COLOR
            or TONE_COLORS.active
        local center_fade = math.abs(item.x) < COMPASS_HALF * 0.25 and 0.72 or 1
        local edge_fade = 1 - math.max(0, math.abs(item.x) / COMPASS_HALF - 0.8) * 2.5
        local alpha = math.max(0.35, center_fade * edge_fade)
        set_color(widget.style.pip.color, source, alpha)
        set_color(widget.style.text.text_color, source, alpha)
    end
    for i = count + 1, MAX_THREATS do
        self._widgets_by_name["compass_threat_" .. i].content.visible = false
    end
end

local function player_sort(a, b)
    if a.local_player ~= b.local_player then return a.local_player end
    return a.name < b.name
end

local function player_state(player, unit, unit_data, visual_loadout)
    if not alive(unit) or player.unit_is_alive and not player:unit_is_alive() then
        return "DEAD", "danger"
    end
    local disabled = unit_data and unit_data:read_component("disabled_character_state")
    if disabled and disabled.is_disabled then
        local kind = disabled.disabling_type
        return kind and tostring(kind):gsub("_", " "):upper() or "DISABLED", "danger"
    end
    local inventory = unit_data and unit_data:read_component("inventory")
    if inventory and visual_loadout
        and PlayerUnitVisualLoadout.slot_equipped(inventory, visual_loadout, "slot_luggable") then
        return "OBJECTIVE", "active"
    end
    return "READY", "ready"
end

function BallHammerThreatHud:_refresh_players(visible_players)
    self._widgets_by_name.player_header.content.visible = visible_players
    if not visible_players then
        for i = 1, MAX_PLAYERS do
            self._widgets_by_name["player_" .. i].content.visible = false
        end
        return
    end
    local manager = Managers.player
    local players = manager and manager:players()
    local local_player = manager and manager:local_player(1)
    local camera = self._parent and self._parent.player_camera and self._parent:player_camera()
    local camera_position = camera and ScriptCamera.position(camera)
    local candidates = self._player_candidates
    local count = 0
    for _, player in pairs(players or {}) do
        count = count + 1
        local item = candidates[count]
        if not item then
            item = {}
            candidates[count] = item
        end
        item.player = player
        item.name = player.name and player:name() or "Player"
        item.local_player = player == local_player
    end
    for i = count + 1, #candidates do candidates[i] = nil end
    table.sort(candidates, player_sort)

    local shown = math.min(count, MAX_PLAYERS)
    for i = 1, shown do
        local item = candidates[i]
        local player = item.player
        local unit = player.player_unit
        local health = extension(unit, "health_system")
        local toughness = extension(unit, "toughness_system")
        local unit_data = extension(unit, "unit_data_system")
        local visual_loadout = extension(unit, "visual_loadout_system")
        local ability = extension(unit, "ability_system")
        local health_value = health and health.current_health_percent
            and percent(health:current_health_percent()) or 0
        local toughness_value = toughness and toughness.current_toughness_percent
            and percent(toughness:current_toughness_percent()) or 0
        local ammo_value = 100
        if unit_data and unit_data.has_component and unit_data:has_component("slot_secondary") then
            local slot = unit_data:read_component("slot_secondary")
            local current = (slot.current_ammunition_reserve or 0)
                + (Ammo.current_ammo_in_clips(slot) or 0)
            local maximum = (slot.max_ammunition_reserve or 0)
                + (Ammo.max_ammo_in_clips(slot) or 0)
            ammo_value = maximum > 0 and percent(current / maximum) or 100
        end
        local grenades = 0
        if ability and ability.remaining_ability_charges then
            grenades = ability:remaining_ability_charges("grenade_ability") or 0
        end
        local state, tone = player_state(player, unit, unit_data, visual_loadout)
        local profile = player.profile and player:profile()
        local archetype = profile and profile.archetype and profile.archetype.name or ""
        local class_name = CLASS_NAMES[archetype] or tostring(archetype):gsub("^%l", string.upper)
        local distance = 0
        local position = unit_position(unit)
        if camera_position and position then distance = Vector3.length(position - camera_position) end
        local widget = self._widgets_by_name["player_" .. i]
        widget.content.visible = true
        widget.content.name = item.name
        widget.content.class = class_name
        widget.content.stats = string.format("HP %d  T %d  AMMO %d%%  G %d",
            health_value, toughness_value, ammo_value, grenades)
        widget.content.state = item.local_player
            and (state == "READY" and "YOU" or state)
            or string.format("%s  %dm", state, math.floor(distance + 0.5))
        local color = TONE_COLORS[tone] or TONE_COLORS.ready
        set_color(widget.style.accent.color, color, 1)
        set_color(widget.style.state.text_color, color, 1)
    end
    for i = shown + 1, MAX_PLAYERS do
        self._widgets_by_name["player_" .. i].content.visible = false
    end
end

function BallHammerThreatHud:update(dt, t, ui_renderer, render_settings, input_service)
    BallHammerThreatHud.super.update(self, dt, t, ui_renderer, render_settings, input_service)
    local enabled = mod.enabled == true
    local show_status, show_compass, compass_range, show_players, opacity = mod.get_hud_settings()
    show_status, show_compass, show_players = enabled and show_status,
        enabled and show_compass, enabled and show_players
    self:_apply_opacity(opacity)

    local threat_content = self._widgets_by_name.threat.content
    local threat_text = enabled and mod.get_threat_indicator() or nil
    threat_content.text = threat_text or ""
    threat_content.visible = threat_text ~= nil

    if t < self._next_status_t - 1 then self._next_status_t = 0 end
    if t >= self._next_status_t then
        self._next_status_t = t + STATUS_INTERVAL
        self:_refresh_status(show_status)
    end

    if t < self._next_threat_scan_t - 1 then self._next_threat_scan_t = 0 end
    if t >= self._next_threat_scan_t then
        self._next_threat_scan_t = t + THREAT_SCAN_INTERVAL
        self:_refresh_threats(compass_range)
    end
    self:_update_compass(show_compass)

    if t < self._next_player_t - 1 then self._next_player_t = 0 end
    if t >= self._next_player_t then
        self._next_player_t = t + PLAYER_INTERVAL
        self:_refresh_players(show_players)
    end
end

return BallHammerThreatHud
