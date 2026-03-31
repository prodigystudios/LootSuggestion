local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("DRUID", {
    { value = "balance", title = "Balance", description = "Caster throughput with spell power, hit and haste value.", role = "spell" },
    { value = "feral", title = "Feral", description = "Melee damage with agility, crit and weapon throughput focus.", role = "physical" },
    { value = "guardian", title = "Guardian", description = "Tank durability with armor, stamina and avoidance focus.", role = "tank" },
    { value = "restoration", title = "Restoration", description = "Healing with haste, spirit and spell power support.", role = "healer" },
})

LS:RegisterSourcePreset("druid_balance", {
    class = "DRUID", spec = "balance", specLabel = "Balance", role = "spell", label = "Druid Balance", description = "Imported Balance weights from the attached Bisbeard setup.", profileId = "spell_dps",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.60, spirit = 0.10, hitRating = 0.50, critRating = 0.60, hasteRating = 0.70, mp5 = 0.00, stamina = 0.00 },
})

LS:RegisterSourcePreset("druid_feral", {
    class = "DRUID", spec = "feral", specLabel = "Feral", role = "physical", label = "Druid Feral", description = "Imported Feral weights from the attached Bisbeard setup.", profileId = "physical_crit",
    weights = { weaponDps = 0.00, attackSpeed = 0.00, strength = 2.00, agility = 2.00, attackPower = 1.00, hitRating = 0.50, critRating = 0.60, hasteRating = 0.40, expertiseRating = 0.50, armorPen = 1.00, stamina = 0.00 },
})

LS:RegisterSourcePreset("druid_guardian", {
    class = "DRUID", spec = "guardian", specLabel = "Guardian", role = "tank", label = "Druid Guardian", description = "Imported Guardian weights from the attached Bisbeard setup.", profileId = "tank_mitigation",
    weights = { weaponDps = 0.00, attackSpeed = 0.00, stamina = 3.00, strength = 1.00, agility = 2.00, intellect = 0.00, spirit = 0.00, armor = 0.10, attackPower = 1.00, defenseRating = 2.00, dodgeRating = 0.90, parryRating = 0.00, blockRating = 0.00, blockValue = 0.00, hitRating = 0.50, critRating = 0.30, hasteRating = 0.50, expertiseRating = 0.50, armorPen = 0.50, mp5 = 0.00 },
})

LS:RegisterSourcePreset("druid_restoration", {
    class = "DRUID", spec = "restoration", specLabel = "Restoration", role = "healer", label = "Druid Restoration", description = "Imported Restoration weights from the attached Bisbeard setup.", profileId = "healer_throughput",
    weights = { strength = 0.00, agility = 0.00, stamina = 0.00, intellect = 0.10, spirit = 0.90, attackPower = 0.00, weaponDps = 0.00, attackSpeed = 0.00, spellPower = 1.00, armorPen = 0.00, spellPen = 0.00, expertiseRating = 0.00, hitRating = 0.00, critRating = 0.50, hasteRating = 0.80, mp5 = 0.00 },
})

LS:RegisterSourcePresetAlias("druid_spell", "druid_balance")
LS:RegisterSourcePresetAlias("druid_physical", "druid_feral")
LS:RegisterSourcePresetAlias("druid_tank", "druid_guardian")
LS:RegisterSourcePresetAlias("druid_healer", "druid_restoration")