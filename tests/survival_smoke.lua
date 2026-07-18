local Survival = dofile("scripts/mods/BallHammer/BallHammerSurvival.lua")

local function eq(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

eq(Survival.safe_timing(10, 11, 0), 10, "early timing should use the start of the safe window")
eq(Survival.safe_timing(10, 11, 100), 11, "late timing should stay inside the safe window")
eq(Survival.safe_timing(11, 10, 50), nil, "invalid timing windows should fail closed")

local disabler = { category = "disabling", impact_t = 4 }
local lethal = { category = "lethal", impact_t = 3 }
local earlier_disabler = { category = "disabling", impact_t = 2 }
eq(Survival.prefer_threat(lethal, disabler), disabler, "disablers should outrank lethal damage")
eq(Survival.prefer_threat(disabler, earlier_disabler), earlier_disabler,
    "earlier impact should win inside a category")

eq(Survival.reaction({ kind = "trapper" }, {}), "dodge", "trapper nets should dodge")
eq(Survival.reaction({ kind = "overhead", time_left = 0.8 }, { can_block = true }), "block",
    "an equipped melee weapon should block a verified overhead")
eq(Survival.reaction({ kind = "overhead", time_left = 0.8 }, {
    can_switch = true,
    switch_lead = 0.4,
}), "switch_block", "a safe emergency switch should lead into block")
eq(Survival.reaction({ kind = "overhead", time_left = 0.2 }, {
    can_switch = true,
    switch_lead = 0.4,
}), "dodge", "a late emergency switch should fall back to dodge")
eq(Survival.reaction({ kind = "unknown" }, {}), "marker", "unknown attacks should stay marker-only")

eq(Survival.should_push({ 2, 3, 4 }, 0.5, 0.25, false), true,
    "three nearby enemies with stamina and no retreat should push")
eq(Survival.should_push({ 2, 3, 5 }, 0.5, 0.25, false), false,
    "enemies outside four metres should not count toward a surround")
eq(Survival.should_push({ 2, 3, 4 }, 0.25, 0.25, false), false,
    "pushes should preserve the stamina reserve")
eq(Survival.should_push({ 2, 3, 4 }, 0.5, 0.25, true), false,
    "a safe retreat should win over an automatic push")

local suppress, resume = Survival.govern(0.88, 0.9, 0.04, false)
eq(suppress, true, "predicted resource cost should stop an unsafe attack")
eq(resume, false, "an unsafe resource level should not resume")
suppress, resume = Survival.govern(0.79, 0.9, 0.04, true, 0.1)
eq(suppress, false, "a cooled resource should stop suppression")
eq(resume, true, "peril should resume ten points below its target")

print("BallHammer survival smoke: ok")
