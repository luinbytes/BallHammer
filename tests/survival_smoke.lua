local Survival = dofile("scripts/mods/BallHammer/BallHammerSurvival.lua")

local function eq(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function close(actual, expected, message)
    assert(math.abs(actual - expected) < 0.000001,
        message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

eq(Survival.safe_timing(10, 11, 0), 10, "early timing should use the start of the safe window")
eq(Survival.safe_timing(10, 11, 100), 11, "late timing should stay inside the safe window")
eq(Survival.safe_timing(11, 10, 50), nil, "invalid timing windows should fail closed")
eq(Survival.reaction_time("mutant", 10, 11.2, 0), 10.85,
    "early timing must stay inside the mutant dodge window")
eq(Survival.reaction_time("mutant", 10, 11.2, 100), 11.02,
    "late timing must leave enough time for Darktide to accept the dodge")
eq(Survival.reaction_time("overhead", 10, 11, 100), 10.82,
    "late timing must leave enough time for Darktide to accept the dodge")

local disabler = { category = "disabling", impact_t = 4 }
local lethal = { category = "lethal", impact_t = 3 }
local earlier_disabler = { category = "disabling", impact_t = 2 }
eq(Survival.prefer_threat(lethal, disabler), disabler, "disablers should outrank lethal damage")
eq(Survival.prefer_threat(disabler, earlier_disabler), earlier_disabler,
    "earlier impact should win inside a category")

eq(Survival.reaction({ kind = "trapper" }), "dodge", "trapper nets should dodge")
eq(Survival.reaction({ kind = "rager" }), "dodge",
    "rager combos should be escaped instead of held-blocked")
eq(Survival.reaction({ kind = "overhead", time_left = 0.8 }), "dodge",
    "a verified overhead should dodge because its damage bypasses block")
eq(Survival.reaction({ kind = "unknown" }), "marker", "unknown attacks should stay marker-only")

eq(Survival.charge_impact_time(-8, 0, -8, 0), 1,
    "a multiplayer mutant charge aimed through the player should predict impact")
eq(Survival.charge_impact_time(-8, 0, 8, 0), nil,
    "a mutant moving away from the player should not trigger a dodge")
eq(Survival.charge_impact_time(-8, 2, -8, 0), nil,
    "a mutant charge that will miss the player should not trigger a dodge")
eq(Survival.charge_impact_time(-6, 0, -6, 0), nil,
    "normal mutant running speed should not be mistaken for a charge")
eq(Survival.charge_impact_time(-10, 0, -12, 0, 10.5, 1, 1.5), 10 / 12,
    "a targeted hound leap should use its higher replicated speed threshold")
eq(Survival.charge_impact_time(-8, 0, -10, 0, 10.5, 1, 1.5), nil,
    "normal hound running speed should not be mistaken for a leap")

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

close(Survival.resource_increment(0.36, 0.35, 0.1), 0.09,
    "learned resource cost should decay after a cheaper update")
close(Survival.resource_increment(0.55, 0.35, 0.09), 0.2,
    "a larger observed resource cost should replace the estimate")
close(Survival.resource_increment(0.55, 0.55, 0.2), 0.2,
    "idle frames should preserve the last observed resource cost")

print("BallHammer survival smoke: ok")
