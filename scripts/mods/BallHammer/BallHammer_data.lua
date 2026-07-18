local mod = get_mod("BallHammer")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "esp_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_outlines",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "outline_distance",
                        type = "numeric",
                        default_value = 30,
                        range = { 5, 100 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "enable_nameplates",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "max_distance",
                        type = "numeric",
                        default_value = 80,
                        range = { 10, 200 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "enable_horde_esp",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "horde_distance",
                        type = "numeric",
                        default_value = 80,
                        range = { 10, 200 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "toggle_key",
                        type = "keybind",
                        keybind_trigger = "pressed",
                        keybind_type = "function_call",
                        default_value = {},
                        function_name = "toggle_esp",
                    },
                },
            },
            {
                setting_id = "pickup_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_pickup_esp",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "pickup_distance",
                        type = "numeric",
                        default_value = 80,
                        range = { 10, 200 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "pickup_filter",
                        type = "dropdown",
                        default_value = "all",
                        options = {
                            { text = "pickup_filter_all", value = "all" },
                            { text = "pickup_filter_supplies", value = "supplies" },
                            { text = "pickup_filter_stimms", value = "stimms" },
                            { text = "pickup_filter_materials", value = "materials" },
                            { text = "pickup_filter_mission", value = "mission" },
                            { text = "pickup_filter_custom", value = "custom",
                                show_widgets = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 } },
                        },
                        sub_widgets = {
                            { setting_id = "pickup_show_plasteel", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_diamantine", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_ammo", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_ammo_crate", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_grenade", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_medkit", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_med_stimm", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_concentration_stimm", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_combat_stimm", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_celerity_stimm", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_grimoire", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_scripture", type = "checkbox", default_value = true },
                            { setting_id = "pickup_show_other", type = "checkbox", default_value = true },
                        },
                    },
                },
            },
            {
                setting_id = "aimbot_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "aim_activation",
                        type = "dropdown",
                        default_value = "left_mouse",
                        options = {
                            { text = "aim_activation_off", value = "off" },
                            { text = "aim_activation_left", value = "left_mouse" },
                            { text = "aim_activation_right", value = "right_mouse" },
                            { text = "aim_activation_both", value = "both_mouse" },
                            { text = "aim_activation_custom", value = "custom", show_widgets = { 1 } },
                        },
                        sub_widgets = {
                            {
                                setting_id = "aim_key",
                                type = "keybind",
                                keybind_trigger = "held",
                                keybind_type = "function_call",
                                default_value = {},
                                function_name = "aimbot_held",
                            },
                        },
                    },
                    {
                        setting_id = "aim_location",
                        type = "dropdown",
                        default_value = "head",
                        options = {
                            { text = "aim_location_head", value = "head" },
                            { text = "aim_location_torso", value = "torso" },
                        },
                    },
                    {
                        setting_id = "aim_distance",
                        type = "numeric",
                        default_value = 80,
                        range = { 5, 200 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "aim_fov",
                        type = "numeric",
                        default_value = 30,
                        range = { 1, 89 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "show_aim_fov",
                        type = "checkbox",
                        default_value = true,
                        sub_widgets = {
                            {
                                setting_id = "aim_fov_opacity",
                                type = "numeric",
                                default_value = 60,
                                range = { 0, 100 },
                                decimals_number = 0,
                            },
                            {
                                setting_id = "aim_fov_red",
                                type = "numeric",
                                default_value = 255,
                                range = { 0, 255 },
                                decimals_number = 0,
                            },
                            {
                                setting_id = "aim_fov_green",
                                type = "numeric",
                                default_value = 158,
                                range = { 0, 255 },
                                decimals_number = 0,
                            },
                            {
                                setting_id = "aim_fov_blue",
                                type = "numeric",
                                default_value = 181,
                                range = { 0, 255 },
                                decimals_number = 0,
                            },
                        },
                    },
                    {
                        setting_id = "aim_smoothness",
                        type = "numeric",
                        default_value = 55,
                        range = { 0, 100 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "aim_curve",
                        type = "numeric",
                        default_value = 20,
                        range = { 0, 100 },
                        decimals_number = 0,
                    },
                },
            },
            {
                setting_id = "triggerbot_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "trigger_activation",
                        type = "dropdown",
                        default_value = "off",
                        options = {
                            { text = "aim_activation_off", value = "off" },
                            { text = "aim_activation_left", value = "left_mouse" },
                            { text = "aim_activation_right", value = "right_mouse" },
                            { text = "aim_activation_both", value = "both_mouse" },
                            { text = "aim_activation_custom", value = "custom", show_widgets = { 1 } },
                        },
                        sub_widgets = {
                            {
                                setting_id = "trigger_key",
                                type = "keybind",
                                keybind_trigger = "held",
                                keybind_type = "function_call",
                                default_value = {},
                                function_name = "triggerbot_held",
                            },
                        },
                    },
                    {
                        setting_id = "trigger_fov",
                        type = "numeric",
                        default_value = 5,
                        range = { 1, 30 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "trigger_fire_fov",
                        type = "numeric",
                        default_value = 0.8,
                        range = { 0.1, 3 },
                        decimals_number = 1,
                    },
                    {
                        setting_id = "trigger_smoothness",
                        type = "numeric",
                        default_value = 35,
                        range = { 0, 100 },
                        decimals_number = 0,
                    },
                },
            },
            {
                setting_id = "rage_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "rage_key",
                        type = "keybind",
                        keybind_trigger = "held",
                        keybind_type = "function_call",
                        default_value = {},
                        function_name = "rage_held",
                    },
                    {
                        setting_id = "rage_distance",
                        type = "numeric",
                        default_value = 120,
                        range = { 5, 200 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "rage_smoothness",
                        type = "numeric",
                        default_value = 10,
                        range = { 0, 100 },
                        decimals_number = 0,
                    },
                },
            },
            {
                setting_id = "director_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_aim_director",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "threat_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_threat_markers",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "enable_threat_reactions",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "reaction_timing",
                        type = "numeric",
                        default_value = 50,
                        range = { 0, 100 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "emergency_override",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "enable_survival_debug",
                        type = "checkbox",
                        default_value = false,
                    },
                },
            },
            {
                setting_id = "guard_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_guard_brain",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "enable_emergency_switch",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "stamina_reserve",
                        type = "numeric",
                        default_value = 25,
                        range = { 20, 60 },
                        decimals_number = 0,
                    },
                },
            },
            {
                setting_id = "governor_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_resource_governor",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "enable_auto_vent",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "peril_target",
                        type = "numeric",
                        default_value = 90,
                        range = { 80, 95 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "heat_target",
                        type = "numeric",
                        default_value = 90,
                        range = { 80, 95 },
                        decimals_number = 0,
                    },
                },
            },
            {
                setting_id = "weapon_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_auto_fire",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "enable_no_recoil",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "enable_no_spread",
                        type = "checkbox",
                        default_value = false,
                    },
                },
            },
            {
                setting_id = "companion_settings",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "enable_companion_target",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "companion_distance",
                        type = "numeric",
                        default_value = 60,
                        range = { 10, 120 },
                        decimals_number = 0,
                    },
                    {
                        setting_id = "enable_auto_whistle",
                        type = "checkbox",
                        default_value = false,
                    },
                },
            },
        },
    },
}
