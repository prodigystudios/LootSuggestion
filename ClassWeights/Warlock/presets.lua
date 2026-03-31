local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("WARLOCK", {
    { value = "affliction", title = "Affliction", description = "Damage-over-time caster pressure with hit and spell power value.", role = "spell" },
    { value = "demonology", title = "Demonology", description = "Steady caster throughput with stamina and spell power support.", role = "spell" },
    { value = "destruction", title = "Destruction", description = "Burst caster damage with crit-heavy scaling.", role = "spell" },
})

LS:RegisterSourcePreset("warlock_affliction", {
    class = "WARLOCK", spec = "affliction", specLabel = "Affliction", role = "spell", label = "Warlock Affliction", description = "Imported Affliction weights from the attached Bisbeard setup.", profileId = "spell_dps",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.10, spirit = 0.10, hitRating = 0.50, critRating = 0.80, hasteRating = 1.00, mp5 = 0.00, stamina = 0.00 },
})

LS:RegisterSourcePreset("warlock_demonology", {
    class = "WARLOCK", spec = "demonology", specLabel = "Demonology", role = "spell", label = "Warlock Demonology", description = "Imported Demonology weights from the attached Bisbeard setup.", profileId = "spell_dps",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.10, spirit = 0.10, hitRating = 0.50, critRating = 0.50, hasteRating = 0.50, mp5 = 0.00, stamina = 0.01 },
})

LS:RegisterSourcePreset("warlock_destruction", {
    class = "WARLOCK", spec = "destruction", specLabel = "Destruction", role = "spell", label = "Warlock Destruction", description = "Imported Destruction weights from the attached Bisbeard setup.", profileId = "spell_crit",
    weights = { spellPower = 1.00, spellPen = 0.50, intellect = 0.10, spirit = 0.10, hitRating = 0.50, critRating = 0.70, hasteRating = 0.80, mp5 = 0.00, stamina = 0.00 },
})

LS:RegisterSourcePresetAlias("warlock_spell", "warlock_affliction")