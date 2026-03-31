local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("PALADIN", {
    { value = "holy", title = "Holy", description = "Healing-focused setup with intellect, crit and sustain.", role = "healer" },
    { value = "protection", title = "Protection", description = "Shield tank setup with block and durability focus.", role = "tank" },
    { value = "retribution", title = "Retribution", description = "Two-hand melee damage with strength and crit value.", role = "physical" },
})

LS:RegisterSourcePreset("paladin_holy", {
    class = "PALADIN", spec = "holy", specLabel = "Holy", role = "healer", label = "Paladin Holy", description = "Imported Holy weights from the attached Bisbeard setup.", profileId = "healer_efficiency",
    weights = { strength = 0.00, agility = 0.00, stamina = 0.00, intellect = 2.00, spirit = 0.50, weaponDps = 0.00, attackSpeed = 0.00, attackPower = 0.00, spellPower = 1.00, armorPen = 0.00, spellPen = 0.00, expertiseRating = 0.00, hitRating = 0.00, critRating = 0.40, hasteRating = 1.00, mp5 = 0.20 },
})

LS:RegisterSourcePreset("paladin_protection", {
    class = "PALADIN", spec = "protection", specLabel = "Protection", role = "tank", label = "Paladin Protection", description = "Imported Protection weights from the attached Bisbeard setup.", profileId = "tank_mitigation",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, stamina = 2.50, strength = 1.00, agility = 0.50, intellect = 0.00, spirit = 0.00, armor = 0.10, attackPower = 1.00, spellPower = 0.80, armorPen = 0.00, spellPen = 0.00, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.10, hasteRating = 0.10, defenseRating = 2.00, dodgeRating = 0.50, parryRating = 0.50, blockRating = 2.00, blockValue = 2.00, mp5 = 0.00 },
})

LS:RegisterSourcePreset("paladin_retribution", {
    class = "PALADIN", spec = "retribution", specLabel = "Retribution", role = "physical", label = "Paladin Retribution", description = "Imported Retribution weights from the attached Bisbeard setup.", profileId = "physical_crit",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 2.50, agility = 1.00, stamina = 0.00, intellect = 0.10, spirit = 0.00, attackPower = 1.00, spellPower = 0.70, armorPen = 0.10, spellPen = 0.00, expertiseRating = 0.50, hitRating = 1.00, critRating = 1.00, hasteRating = 0.40, mp5 = 0.00 },
})

LS:RegisterSourcePresetAlias("paladin_healer", "paladin_holy")
LS:RegisterSourcePresetAlias("paladin_tank", "paladin_protection")
LS:RegisterSourcePresetAlias("paladin_physical", "paladin_retribution")