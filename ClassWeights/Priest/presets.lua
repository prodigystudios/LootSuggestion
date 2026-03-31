local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("PRIEST", {
    { value = "discipline", title = "Discipline", description = "Healing with mana stability and crit support.", role = "healer" },
    { value = "holy", title = "Holy", description = "Throughput healing with spell power and spirit value.", role = "healer" },
    { value = "shadow", title = "Shadow", description = "Caster DPS with spell power, hit and haste focus.", role = "spell" },
})

LS:RegisterSourcePreset("priest_discipline", {
    class = "PRIEST", spec = "discipline", specLabel = "Discipline", role = "healer", label = "Priest Discipline", description = "Imported Discipline weights from the attached Bisbeard setup.", profileId = "healer_efficiency",
    weights = { strength = 0.00, agility = 0.00, stamina = 0.01, intellect = 0.40, spirit = 0.10, weaponDps = 0.00, attackSpeed = 0.00, attackPower = 0.00, spellPower = 1.00, healingPower = 1.00, armorPen = 0.00, spellPen = 0.00, expertiseRating = 0.00, hitRating = 0.00, critRating = 0.20, hasteRating = 0.60, mp5 = 0.30 },
})

LS:RegisterSourcePreset("priest_holy", {
    class = "PRIEST", spec = "holy", specLabel = "Holy", role = "healer", label = "Priest Holy", description = "Imported Holy weights from the attached Bisbeard setup.", profileId = "healer_throughput",
    weights = { strength = 0.00, agility = 0.00, stamina = 0.00, intellect = 0.50, spirit = 0.90, weaponDps = 0.00, attackSpeed = 0.00, attackPower = 0.00, spellPower = 1.00, healingPower = 1.00, armorPen = 0.00, spellPen = 0.00, expertiseRating = 0.00, hitRating = 0.00, critRating = 0.60, hasteRating = 0.50, mp5 = 0.30 },
})

LS:RegisterSourcePreset("priest_shadow", {
    class = "PRIEST", spec = "shadow", specLabel = "Shadow", role = "spell", label = "Priest Shadow", description = "Imported Shadow weights from the attached Bisbeard setup.", profileId = "spell_dps",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.10, spirit = 0.80, hitRating = 0.50, critRating = 0.60, hasteRating = 0.70, mp5 = 0.00, stamina = 0.00 },
})

LS:RegisterSourcePresetAlias("priest_healer", "priest_holy")
LS:RegisterSourcePresetAlias("priest_spell", "priest_shadow")