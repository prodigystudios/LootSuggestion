local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("ROGUE", {
    { value = "assassination", title = "Assassination", description = "Crit and proc-based dagger or poison-oriented damage.", role = "physical" },
    { value = "combat", title = "Combat", description = "Sustained weapon pressure with hit, expertise and haste value.", role = "physical" },
    { value = "subtlety", title = "Subtlety", description = "Burst-oriented agility damage with crit support.", role = "physical" },
})

LS:RegisterSourcePreset("rogue_assassination", {
    class = "ROGUE", spec = "assassination", specLabel = "Assassination", role = "physical", label = "Rogue Assassination", description = "Imported Assassination weights from the attached Bisbeard setup.", profileId = "physical_crit",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 1.00, agility = 2.00, stamina = 0.00, attackPower = 1.00, armorPen = 0.50, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.80, hasteRating = 0.60 },
})

LS:RegisterSourcePreset("rogue_combat", {
    class = "ROGUE", spec = "combat", specLabel = "Combat", role = "physical", label = "Rogue Combat", description = "Imported Combat weights from the attached Bisbeard setup.", profileId = "physical_haste",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 1.00, agility = 2.00, stamina = 0.00, attackPower = 1.00, armorPen = 1.00, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.60, hasteRating = 1.00 },
})

LS:RegisterSourcePreset("rogue_subtlety", {
    class = "ROGUE", spec = "subtlety", specLabel = "Subtlety", role = "physical", label = "Rogue Subtlety", description = "Imported Subtlety weights from the attached Bisbeard setup.", profileId = "physical_crit",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 1.00, agility = 2.00, stamina = 0.00, attackPower = 1.00, armorPen = 0.50, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.70, hasteRating = 0.60 },
})

LS:RegisterSourcePresetAlias("rogue_physical", "rogue_combat")