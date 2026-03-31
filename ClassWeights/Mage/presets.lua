local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("MAGE", {
    { value = "arcane", title = "Arcane", description = "Mana-driven caster damage with crit and intellect value.", role = "spell" },
    { value = "fire", title = "Fire", description = "Crit-heavy spell damage with strong burst windows.", role = "spell" },
    { value = "frost", title = "Frost", description = "Steady spell damage with haste and control-friendly pacing.", role = "spell" },
})

LS:RegisterSourcePreset("mage_arcane", {
    class = "MAGE", spec = "arcane", specLabel = "Arcane", role = "spell", label = "Mage Arcane", description = "Imported Arcane weights from the attached Bisbeard setup.", profileId = "spell_crit",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.80, spirit = 0.30, hitRating = 0.50, critRating = 0.60, hasteRating = 0.60, mp5 = 0.05, stamina = 0.00 },
})

LS:RegisterSourcePreset("mage_fire", {
    class = "MAGE", spec = "fire", specLabel = "Fire", role = "spell", label = "Mage Fire", description = "Imported Fire weights from the attached Bisbeard setup.", profileId = "spell_crit",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.10, spirit = 0.30, hitRating = 0.50, critRating = 0.90, hasteRating = 0.60, mp5 = 0.01, stamina = 0.00 },
})

LS:RegisterSourcePreset("mage_frost", {
    class = "MAGE", spec = "frost", specLabel = "Frost", role = "spell", label = "Mage Frost", description = "Imported Frost weights from the attached Bisbeard setup.", profileId = "spell_dps",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.10, spirit = 0.30, hitRating = 0.50, critRating = 0.50, hasteRating = 0.80, mp5 = 0.01, stamina = 0.00 },
})

LS:RegisterSourcePresetAlias("mage_spell", "mage_arcane")