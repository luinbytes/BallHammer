local threat_text = "DODGE 0.2"
local mod = {
    enabled = true,
    get_threat_indicator = function() return threat_text end,
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

HudElementBase = {
    init = function(self, _, _, _, definitions)
        self.definitions = definitions
        self._widgets_by_name = { threat = { content = {} } }
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
element:init(nil, 1, 1)
local position = element.definitions.scenegraph_definition.threat.position
assert(position[1] == 0 and position[2] > 0,
    "danger indicator must use a fixed screen-space position below the crosshair")

element:update(0.016, 1, nil, {}, nil)
assert(element._widgets_by_name.threat.content.visible
    and element._widgets_by_name.threat.content.text == "DODGE 0.2",
    "active danger should render in the static HUD widget")
local x, y = position[1], position[2]
element:update(0.016, 2, nil, {}, nil)
assert(position[1] == x and position[2] == y,
    "camera updates must never move the screen-space danger indicator")

threat_text = nil
element:update(0.016, 3, nil, {}, nil)
assert(not element._widgets_by_name.threat.content.visible,
    "the static danger indicator should hide after danger clears")

print("BallHammer threat HUD smoke: ok")
