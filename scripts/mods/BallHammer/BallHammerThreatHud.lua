local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local mod = get_mod("BallHammer")

local function visible(content)
    return content.visible
end

local Definitions = {
    scenegraph_definition = {
        screen = UIWorkspaceSettings.screen,
        threat = {
            parent = "screen",
            size = { 108, 20 },
            vertical_alignment = "center",
            horizontal_alignment = "center",
            position = { 0, 52, 1 },
        },
    },
    widget_definitions = {
        threat = UIWidget.create_definition({
            {
                pass_type = "rect",
                visibility_function = visible,
                style = { color = { 150, 8, 10, 12 }, offset = { 0, 0, 1 } },
            },
            {
                pass_type = "rect",
                visibility_function = visible,
                style = {
                    size = { 2, 20 },
                    offset = { 0, 0, 2 },
                    color = { 255, 255, 90, 90 },
                },
            },
            {
                pass_type = "text",
                value_id = "text",
                value = "",
                visibility_function = visible,
                style = {
                    font_type = "mono_tide_regular",
                    font_size = 13,
                    text_vertical_alignment = "center",
                    text_horizontal_alignment = "center",
                    text_color = { 255, 255, 225, 225 },
                    offset = { 2, 0, 3 },
                },
            },
        }, "threat"),
    },
}

BallHammerThreatHud = class("BallHammerThreatHud", "HudElementBase")

function BallHammerThreatHud:init(parent, draw_layer, start_scale)
    BallHammerThreatHud.super.init(self, parent, draw_layer, start_scale, Definitions)
end

function BallHammerThreatHud:update(dt, t, ui_renderer, render_settings, input_service)
    BallHammerThreatHud.super.update(self, dt, t, ui_renderer, render_settings, input_service)
    local content = self._widgets_by_name.threat.content
    local text = mod.get_threat_indicator()
    content.text = text or ""
    content.visible = mod.enabled and text ~= nil
end

return BallHammerThreatHud
