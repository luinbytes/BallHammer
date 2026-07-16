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
