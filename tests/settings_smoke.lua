local localization = dofile("scripts/mods/BallHammer/BallHammer_localization.lua")
local mod = {
    localize = function(_, key)
        assert(localization[key], "missing localization: " .. key)
        return localization[key].en
    end,
}

get_mod = function() return mod end

local data = dofile("scripts/mods/BallHammer/BallHammer_data.lua")
local widgets = data.options.widgets

assert(#widgets == 3, "menu should expose ESP, aimbot, and companion sections")
assert(widgets[1].setting_id == "esp_settings", "ESP should be the first section")
assert(widgets[2].setting_id == "aimbot_settings", "Aimbot should be the second section")
assert(widgets[3].setting_id == "companion_settings", "Companion should be the third section")

local activation = widgets[2].sub_widgets[1]
assert(activation.setting_id == "aim_activation" and activation.default_value == "left_mouse",
    "left mouse should be the default native aim activation")
assert(activation.sub_widgets[1].setting_id == "aim_key",
    "custom keybind should be nested under aim activation")
assert(activation.options[1].value == "off", "aim activation should be the single aimbot enable control")
assert(activation.options[4].value == "both_mouse", "aimbot should support either mouse button")
assert(widgets[2].sub_widgets[5].setting_id == "aim_smoothness", "aim speed should use a smoothness slider")
assert(widgets[2].sub_widgets[6].setting_id == "aim_curve", "aimbot should expose curve strength")
assert(widgets[3].sub_widgets[1].setting_id == "enable_companion_target",
    "companion auto-target should have an independent toggle")
assert(widgets[3].sub_widgets[2].setting_id == "companion_distance",
    "companion auto-target should expose a range limit")

local function check_localization(widget)
    assert(localization[widget.setting_id], "missing setting localization: " .. widget.setting_id)
    for _, option in ipairs(widget.options or {}) do
        assert(localization[option.text], "missing option localization: " .. option.text)
    end
    for _, child in ipairs(widget.sub_widgets or {}) do check_localization(child) end
end

for _, widget in ipairs(widgets) do check_localization(widget) end
print("BallHammer settings smoke: ok")
