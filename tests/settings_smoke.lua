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

assert(#widgets == 11, "menu should expose all survival and existing combat sections")
assert(widgets[1].setting_id == "esp_settings", "ESP should be the first section")
assert(widgets[2].setting_id == "pickup_settings", "Pickup ESP should follow enemy ESP")
assert(widgets[3].setting_id == "aimbot_settings", "Aimbot should follow ESP sections")
assert(widgets[4].setting_id == "triggerbot_settings", "Triggerbot should follow the normal aimbot")
assert(widgets[5].setting_id == "rage_settings", "Rage should follow triggerbot")
assert(widgets[6].setting_id == "director_settings", "Aim modes should share the hit-zone director")
assert(widgets[7].setting_id == "threat_settings", "Threat Interceptor should follow aim controls")
assert(widgets[8].setting_id == "guard_settings", "Guard Brain should follow threat detection")
assert(widgets[9].setting_id == "governor_settings", "Resource governor should follow defense")
assert(widgets[10].setting_id == "weapon_settings", "Weapon should follow survival controls")
assert(widgets[11].setting_id == "companion_settings", "Companion should be the final section")

assert(widgets[2].sub_widgets[1].setting_id == "enable_pickup_esp"
    and widgets[2].sub_widgets[1].default_value == true,
    "pickup ESP should be enabled independently by default")
assert(widgets[2].sub_widgets[2].setting_id == "pickup_distance",
    "pickup ESP should expose a distance limit")
local pickup_filter = widgets[2].sub_widgets[3]
assert(pickup_filter.setting_id == "pickup_filter" and pickup_filter.type == "dropdown"
    and pickup_filter.default_value == "all" and #pickup_filter.options == 6,
    "pickup ESP should expose a compact category filter")
assert(pickup_filter.options[1].value == "all"
    and pickup_filter.options[2].value == "supplies"
    and pickup_filter.options[3].value == "stimms"
    and pickup_filter.options[4].value == "materials"
    and pickup_filter.options[5].value == "mission"
    and pickup_filter.options[6].value == "custom"
    and #pickup_filter.sub_widgets == 13,
    "pickup filter should cover all classified pickup categories")
assert(pickup_filter.sub_widgets[1].setting_id == "pickup_show_plasteel"
    and pickup_filter.sub_widgets[2].setting_id == "pickup_show_diamantine"
    and pickup_filter.sub_widgets[7].setting_id == "pickup_show_med_stimm"
    and pickup_filter.sub_widgets[13].setting_id == "pickup_show_other",
    "custom pickup filtering should expose individual pickup types")

local activation = widgets[3].sub_widgets[1]
assert(activation.setting_id == "aim_activation" and activation.default_value == "left_mouse",
    "left mouse should be the default native aim activation")
assert(activation.sub_widgets[1].setting_id == "aim_key",
    "custom keybind should be nested under aim activation")
assert(activation.options[1].value == "off", "aim activation should be the single aimbot enable control")
assert(activation.options[4].value == "both_mouse", "aimbot should support either mouse button")
local fov_display = widgets[3].sub_widgets[5]
assert(fov_display.setting_id == "show_aim_fov" and fov_display.default_value == true,
    "the target FOV display should have a master switch")
assert(fov_display.sub_widgets[1].setting_id == "aim_fov_opacity"
    and fov_display.sub_widgets[2].setting_id == "aim_fov_red"
    and fov_display.sub_widgets[3].setting_id == "aim_fov_green"
    and fov_display.sub_widgets[4].setting_id == "aim_fov_blue",
    "the target FOV display should expose opacity and full RGB controls")
assert(widgets[3].sub_widgets[6].setting_id == "aim_smoothness", "aim speed should use a smoothness slider")
assert(widgets[3].sub_widgets[7].setting_id == "aim_curve", "aimbot should expose curve strength")
local trigger_activation = widgets[4].sub_widgets[1]
assert(trigger_activation.setting_id == "trigger_activation"
    and trigger_activation.default_value == "off",
    "triggerbot should be opt-in and support native activation modes")
assert(trigger_activation.sub_widgets[1].function_name == "triggerbot_held",
    "triggerbot custom bind should use the held callback")
assert(widgets[5].sub_widgets[1].setting_id == "rage_key"
    and widgets[5].sub_widgets[1].function_name == "rage_held",
    "rage should expose a held keybind")
assert(widgets[6].sub_widgets[1].setting_id == "enable_aim_director"
    and widgets[6].sub_widgets[1].default_value == true,
    "armor and weakspot direction should enhance already-opt-in aim modes by default")
assert(widgets[7].sub_widgets[1].setting_id == "enable_threat_markers"
    and widgets[7].sub_widgets[1].default_value == true,
    "threat information should be on by default")
assert(widgets[7].sub_widgets[2].setting_id == "enable_threat_reactions"
    and widgets[7].sub_widgets[2].default_value == false,
    "automatic threat reactions should be opt-in")
assert(widgets[7].sub_widgets[3].setting_id == "reaction_timing"
    and widgets[7].sub_widgets[3].range[1] == 0
    and widgets[7].sub_widgets[3].range[2] == 100,
    "reaction timing should stay normalized inside safe windows")
assert(widgets[7].sub_widgets[4].setting_id == "emergency_override"
    and widgets[7].sub_widgets[4].default_value == false,
    "physical input should win by default")
assert(widgets[8].sub_widgets[1].setting_id == "enable_guard_brain"
    and widgets[8].sub_widgets[1].default_value == false,
    "Guard Brain should be opt-in")
assert(widgets[8].sub_widgets[2].setting_id == "enable_emergency_switch"
    and widgets[8].sub_widgets[2].default_value == false,
    "emergency melee switching should be opt-in")
assert(widgets[8].sub_widgets[3].setting_id == "stamina_reserve"
    and widgets[8].sub_widgets[3].range[1] == 20
    and widgets[8].sub_widgets[3].range[2] == 60,
    "push reserve must stay inside its safe range")
assert(widgets[9].sub_widgets[1].setting_id == "enable_resource_governor"
    and widgets[9].sub_widgets[1].default_value == false,
    "resource automation should be opt-in")
assert(widgets[9].sub_widgets[3].setting_id == "peril_target"
    and widgets[9].sub_widgets[3].range[1] == 80
    and widgets[9].sub_widgets[3].range[2] == 95,
    "peril target should expose only safe bounds")
assert(widgets[9].sub_widgets[4].setting_id == "heat_target"
    and widgets[9].sub_widgets[4].range[1] == 80
    and widgets[9].sub_widgets[4].range[2] == 95,
    "heat target should expose only safe bounds")
assert(widgets[10].sub_widgets[1].setting_id == "enable_auto_fire"
    and widgets[10].sub_widgets[1].default_value == true,
    "semi-automatic repeat fire should have an independent weapon toggle")
assert(widgets[10].sub_widgets[2].setting_id == "enable_no_recoil"
    and widgets[10].sub_widgets[2].default_value == false,
    "recoil suppression should have an independent weapon toggle")
assert(widgets[10].sub_widgets[3].setting_id == "enable_no_spread"
    and widgets[10].sub_widgets[3].default_value == false,
    "spread suppression should have an independent weapon toggle")
assert(widgets[11].sub_widgets[1].setting_id == "enable_companion_target",
    "companion auto-target should have an independent toggle")
assert(widgets[11].sub_widgets[2].setting_id == "companion_distance",
    "companion auto-target should expose a range limit")
assert(widgets[11].sub_widgets[3].setting_id == "enable_auto_whistle"
    and widgets[11].sub_widgets[3].default_value == false,
    "automatic dog EMP should have an independent opt-in toggle")

local function check_localization(widget)
    assert(localization[widget.setting_id], "missing setting localization: " .. widget.setting_id)
    for _, option in ipairs(widget.options or {}) do
        assert(localization[option.text], "missing option localization: " .. option.text)
    end
    for _, child in ipairs(widget.sub_widgets or {}) do check_localization(child) end
end

for _, widget in ipairs(widgets) do check_localization(widget) end
local percentage_labels = {
    aim_fov_opacity = "FOV Circle Opacity (%)",
    stamina_reserve = "Push Stamina Reserve (%)",
    peril_target = "Peril Safety Target (%)",
    heat_target = "Heat Safety Target (%)",
}
for key, expected in pairs(percentage_labels) do
    local ok, formatted = pcall(string.format, localization[key].en)
    assert(ok and formatted == expected, "invalid percentage localization for " .. key)
end
print("BallHammer settings smoke: ok")
