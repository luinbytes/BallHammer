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
                        range = { 1, 180 },
                        decimals_number = 0,
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
                },
            },
        },
    },
}
