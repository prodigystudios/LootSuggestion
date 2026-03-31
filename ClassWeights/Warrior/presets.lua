local LS = _G.LootSuggestionAddon

if not LS then
    return
end

LS:RegisterClassSpecs("WARRIOR", {
    { value = "arms", title = "Arms", description = "Slow weapon pressure with crit and armor penetration value.", role = "physical" },
    { value = "fury", title = "Fury", description = "Fast dual-wield pressure with haste and hit value.", role = "physical" },
    { value = "protection", title = "Protection", description = "Shield tanking with block and mitigation focus.", role = "tank" },
})

LS:RegisterSourcePreset("warrior_arms", {
    class = "WARRIOR", spec = "arms", specLabel = "Arms", role = "physical", label = "Warrior Arms", description = "Imported Arms weights from the attached Bisbeard setup.", profileId = "physical_crit",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 2.00, agility = 1.00, stamina = 0.00, attackPower = 1.00, armorPen = 1.00, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.50, hasteRating = 0.50 },
})

LS:RegisterSourcePreset("warrior_fury", {
    class = "WARRIOR", spec = "fury", specLabel = "Fury", role = "physical", label = "Warrior Fury", description = "Imported Fury weights from the attached Bisbeard setup.", profileId = "physical_haste",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 2.00, agility = 1.00, stamina = 0.00, attackPower = 1.00, armorPen = 1.00, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.50, hasteRating = 0.60 },
})

LS:RegisterSourcePreset("warrior_protection", {
    class = "WARRIOR", spec = "protection", specLabel = "Protection", role = "tank", label = "Warrior Protection", description = "Imported Protection weights from the attached Bisbeard setup.", profileId = "tank_mitigation",
    weights = { weaponDps = 14.00, attackSpeed = 0.00, strength = 1.00, agility = 1.00, stamina = 2.00, attackPower = 1.00, armorPen = 0.50, expertiseRating = 0.50, hitRating = 0.50, critRating = 0.20, hasteRating = 0.20, armor = 0.10, defenseRating = 1.00, dodgeRating = 1.00, parryRating = 1.00, blockRating = 1.00, blockValue = 1.00 },
})

LS:RegisterSourcePresetAlias("warrior_physical", "warrior_arms")
LS:RegisterSourcePresetAlias("warrior_tank", "warrior_protection")