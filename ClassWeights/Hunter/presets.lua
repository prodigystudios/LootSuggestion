local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("HUNTER", {
    { value = "beast_mastery", title = "Beast Mastery", description = "Stable ranged throughput with agility and crit support.", role = "physical" },
    { value = "marksmanship", title = "Marksmanship", description = "Ranged burst and precision with crit and armor penetration value.", role = "physical" },
    { value = "survival", title = "Survival", description = "Agility-heavy ranged damage with haste and proc lean.", role = "physical" },
})

LS:RegisterSourcePreset("hunter_beast_mastery", {
    class = "HUNTER", spec = "beast_mastery", specLabel = "Beast Mastery", role = "physical", label = "Hunter Beast Mastery", description = "Beast Mastery baseline with steady agility and crit-focused ranged value.", profileId = "physical_dps",
    weights = { weaponDps = 14, attackSpeed = 0.00, strength = 0.00, agility = 2.0, intellect = 0.10, attackPower = 1.0, hitRating = 0.5, critRating = 0.5, hasteRating = 0.4, expertiseRating = 0.00, armorPen = 0.5, stamina = 0.10 },
})

LS:RegisterSourcePreset("hunter_marksmanship", {
    class = "HUNTER", spec = "marksmanship", specLabel = "Marksmanship", role = "physical", label = "Hunter Marksmanship", description = "Marksmanship baseline with crit, hit and weapon throughput prioritized.", profileId = "physical_crit",
    weights = { weaponDps = 14, attackSpeed = 0.00, strength = 0.00, agility = 2, intellect = 1.1, attackPower = 1, hitRating = 0.5, critRating = 0.8, hasteRating = 0.5, expertiseRating = 0.00, armorPen = 1.0, stamina = 0.1 },
})

LS:RegisterSourcePreset("hunter_survival", {
    class = "HUNTER", spec = "survival", specLabel = "Survival", role = "physical", label = "Hunter Survival", description = "Survival baseline with agility, haste and proc-friendly pacing.", profileId = "physical_haste",
    weights = { weaponDps = 14, attackSpeed = 0.00, strength = 1, agility = 2.5, intellect = 0.10, attackPower = 1.0, hitRating = 0.5, critRating = 0.4, hasteRating = 0.8, expertiseRating = 0.00, armorPen = 1, stamina = 0.1 },
})

LS:RegisterSourcePresetAlias("hunter_physical", "hunter_marksmanship")