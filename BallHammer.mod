return {
    run = function()
        fassert(rawget(_G, "new_mod"), "`BallHammer` mod requires the Darktide Mod Framework!")
        new_mod("BallHammer", {
            mod_script       = [[BallHammer/scripts/mods/BallHammer/BallHammer]],
            mod_data         = [[BallHammer/scripts/mods/BallHammer/BallHammer_data]],
            mod_localization = [[BallHammer/scripts/mods/BallHammer/BallHammer_localization]],
        })
    end,
    packages = {},
}