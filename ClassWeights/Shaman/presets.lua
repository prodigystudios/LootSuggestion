local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("SHAMAN", {
    { value = "elemental", title = "Elemental", description = "Caster damage with spell power, hit and crit value.", role = "spell" },
    { value = "enhancement", title = "Enhancement", description = "Hybrid melee with weapon throughput and haste value.", role = "physical" },
    { value = "restoration", title = "Restoration", description = "Healing with balanced haste, crit and sustain.", role = "healer" },
    { value = "tank", title = "Tank", description = "Shield tank setup with mitigation and durability focus.", role = "tank" },
})

LS:RegisterSourcePreset("shaman_elemental", {
    class = "SHAMAN", spec = "elemental", specLabel = "Elemental", role = "spell", label = "Shaman Elemental", description = "Imported Elemental weights from the attached Bisbeard setup.", profileId = "spell_crit",
    weights = { strength = 0.00, agility = 0.00, stamina = 0.00, intellect = 0.20, spirit = 0.00, attackPower = 0.00, spellPower = 1.00, armorPen = 0.00, spellPen = 0.50, expertiseRating = 0.00, hitRating = 0.50, critRating = 0.90, hasteRating = 1.00, mp5 = 0.00 },
})

LS:RegisterSourcePreset("shaman_enhancement", {
    class = "SHAMAN", spec = "enhancement", specLabel = "Enhancement", role = "physical", label = "Shaman Enhancement", description = "Imported Enhancement weights from the attached Bisbeard setup.", profileId = "physical_haste",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 1.00, agility = 1.00, stamina = 0.00, intellect = 1.00, spirit = 0.00, attackPower = 1.00, spellPower = 0.40, armorPen = 0.50, spellPen = 0.00, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.50, hasteRating = 0.50, mp5 = 0.00 },
})

LS:RegisterSourcePreset("shaman_restoration", {
    class = "SHAMAN", spec = "restoration", specLabel = "Restoration", role = "healer", label = "Shaman Restoration", description = "Imported Restoration weights from the attached Bisbeard setup.", profileId = "healer_throughput",
    weights = { strength = 0.00, agility = 0.00, stamina = 0.00, intellect = 1.00, spirit = 0.10, attackPower = 0.00, spellPower = 1.00, healingPower = 1.00, armorPen = 0.00, spellPen = 0.00, expertiseRating = 0.00, hitRating = 0.00, critRating = 0.50, hasteRating = 0.50, mp5 = 0.10 },
})

LS:RegisterSourcePreset("shaman_tank_bisbeard", {
    class = "SHAMAN", spec = "tank", specLabel = "Tank", role = "tank", label = "Shaman Tank", description = "Imported Tank weights from the attached Bisbeard setup.", profileId = "tank_mitigation",
    weights = { strength = 1.00, agility = 1.50, stamina = 2.50, intellect = 1.00, spirit = 0.00, critRating = 0.20, hitRating = 0.50, hasteRating = 0.30, mp5 = 0.00, weaponDps = 14.00, attackPower = 0.50, spellPower = 0.50, armorPen = 0.30, spellPen = 0.00, expertiseRating = 0.50, armor = 0.10, defenseRating = 2.00, dodgeRating = 0.80, parryRating = 0.80, blockRating = 1.30, blockValue = 1.00 },
    caps = { hitRating = { cap = 80, postCapWeight = 0.05, label = "Tank hit target" }, expertiseRating = { cap = 44, postCapWeight = 0.05, label = "Tank expertise rating target (26 expertise)" } },
})

LS:RegisterSourcePresetAlias("shaman_spell", "shaman_elemental")
LS:RegisterSourcePresetAlias("shaman_physical", "shaman_enhancement")
LS:RegisterSourcePresetAlias("shaman_healer", "shaman_restoration")
LS:RegisterSourcePresetAlias("shaman_tank", "shaman_tank_bisbeard")