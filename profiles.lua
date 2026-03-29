local LS = _G.LootSuggestionAddon
local GetItemStats = rawget(_G, "GetItemStats")
local GetInventoryItemLink = _G.GetInventoryItemLink

local function copyTable(source)
    local target = {}
    for key, value in pairs(source or {}) do
        target[key] = value
    end
    return target
end

LS.statDefinitions = {
    { key = "strength", label = "Strength", keys = { "ITEM_MOD_STRENGTH_SHORT" } },
    { key = "agility", label = "Agility", keys = { "ITEM_MOD_AGILITY_SHORT" } },
    { key = "stamina", label = "Stamina", keys = { "ITEM_MOD_STAMINA_SHORT" } },
    { key = "intellect", label = "Intellect", keys = { "ITEM_MOD_INTELLECT_SHORT" } },
    { key = "spirit", label = "Spirit", keys = { "ITEM_MOD_SPIRIT_SHORT" } },
    { key = "armor", label = "Armor", keys = { "RESISTANCE0_NAME", "ARMOR", "ITEM_MOD_ARMOR_SHORT" } },
    { key = "attackPower", label = "Attack Power", keys = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" } },
    { key = "spellPower", label = "Spell Power", keys = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_HEALING_DONE_SHORT" } },
    { key = "spellPen", label = "Spell Penetration", keys = { "ITEM_MOD_SPELL_PENETRATION_SHORT", "ITEM_MOD_TARGET_RESISTANCE_SHORT" } },
    { key = "hitRating", label = "Hit Rating", keys = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_MELEE_RATING_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT", "ITEM_MOD_HIT_RANGED_RATING_SHORT" } },
    { key = "critRating", label = "Crit Rating", keys = { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRIT_MELEE_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "ITEM_MOD_CRIT_RANGED_RATING_SHORT" } },
    { key = "hasteRating", label = "Haste Rating", keys = { "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_HASTE_MELEE_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT", "ITEM_MOD_HASTE_RANGED_RATING_SHORT" } },
    { key = "expertiseRating", label = "Expertise Rating", keys = { "ITEM_MOD_EXPERTISE_RATING_SHORT" } },
    { key = "armorPen", label = "Armor Penetration", keys = { "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT" } },
    { key = "defenseRating", label = "Defense Rating", keys = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_DEFENSE_RATING_SHORT" } },
    { key = "dodgeRating", label = "Dodge Rating", keys = { "ITEM_MOD_DODGE_RATING_SHORT" } },
    { key = "parryRating", label = "Parry Rating", keys = { "ITEM_MOD_PARRY_RATING_SHORT" } },
    { key = "blockRating", label = "Block Rating", keys = { "ITEM_MOD_BLOCK_RATING_SHORT" } },
    { key = "blockValue", label = "Block Value", keys = { "ITEM_MOD_BLOCK_VALUE_SHORT", "SHIELD_BLOCK" } },
    { key = "mp5", label = "MP5", keys = { "ITEM_MOD_MANA_REGENERATION_SHORT" } },
}

LS.statLookup = {}
LS.statLabels = {}

for _, definition in ipairs(LS.statDefinitions) do
    LS.statLookup[definition.key] = definition
    LS.statLabels[definition.key] = definition.label
end

LS.scalingChoices = {
    strength = {
        label = "Strength-based",
        description = "For builds where strength remains the main stat driver.",
    },
    agility = {
        label = "Agility-based",
        description = "For builds that scale more from agility than from strength.",
    },
}

LS.tankStyleChoices = {
    evasion = {
        label = "Evasion",
        description = "For tanks that lean on agility, dodge and avoidance.",
    },
    block = {
        label = "Block",
        description = "For shield tanks where blocking is a major part of mitigation.",
    },
    health = {
        label = "Health/Armor",
        description = "For tanks that value bigger health pools and raw armor first.",
    },
}

LS.scalingModifiers = {
    physical = {
        strength = {},
        agility = {
            strength = -0.55,
            agility = 0.55,
            critRating = 0.10,
        },
    },
    tank = {
        strength = {},
        agility = {
            strength = -0.45,
            agility = 0.95,
            dodgeRating = 0.20,
            critRating = 0.15,
            parryRating = -0.20,
            blockRating = -0.20,
        },
    },
}

LS.tankStyleModifiers = {
    evasion = {
        agility = 0.30,
        stamina = -0.10,
        dodgeRating = 0.35,
        critRating = 0.10,
        blockRating = -0.35,
        blockValue = -0.30,
        parryRating = -0.15,
    },
    block = {
        strength = 0.30,
        defenseRating = 0.15,
        dodgeRating = -0.15,
        parryRating = 0.10,
        blockRating = 0.95,
        blockValue = 0.90,
    },
    health = {
        stamina = 0.45,
        armor = 0.55,
        defenseRating = 0.15,
        dodgeRating = -0.10,
        parryRating = -0.10,
        blockRating = -0.10,
    },
}

LS.priorityWizardPools = {
    physical = { "strength", "agility", "attackPower", "hitRating", "critRating", "hasteRating", "expertiseRating", "armorPen", "stamina" },
    spell = { "spellPower", "hitRating", "intellect", "hasteRating", "critRating", "spirit", "spellPen", "mp5", "stamina" },
    healer = { "spellPower", "intellect", "spirit", "hasteRating", "critRating", "mp5", "stamina" },
    tank = { "stamina", "armor", "defenseRating", "dodgeRating", "parryRating", "blockRating", "blockValue", "strength", "agility", "hitRating", "expertiseRating" },
}

LS.priorityWizardWeightCurve = { 1.80, 1.55, 1.35, 1.15, 1.00, 0.85, 0.70, 0.55, 0.40, 0.28, 0.18 }

LS.profileOrder = {
    "physical_dps",
    "physical_crit",
    "physical_haste",
    "spell_dps",
    "spell_crit",
    "healer_throughput",
    "healer_efficiency",
    "tank_mitigation",
    "tank_threat",
}

LS.profiles = {
    physical_dps = {
        name = "Physical DPS",
        role = "physical",
        scalingGroup = "physical",
        summary = "Good starting point for general melee or ranged physical damage builds.",
        playstyle = "Balanced damage with hit, crit and attack power all contributing.",
        capRules = {
            hitRating = { cap = 80, postCapWeight = 0.18, label = "Melee hit cap" },
            expertiseRating = { cap = 44, postCapWeight = 0.15, label = "Expertise rating target (26 expertise)" },
            armorPen = { cap = 60, postCapWeight = 0.10, label = "Armor penetration target" },
        },
        weights = {
            strength = 1.60,
            agility = 1.30,
            attackPower = 1.00,
            hitRating = 1.45,
            critRating = 1.25,
            hasteRating = 1.05,
            expertiseRating = 1.20,
            armorPen = 1.00,
            stamina = 0.15,
        },
    },
    physical_crit = {
        name = "Physical Crit Focus",
        role = "physical",
        scalingGroup = "physical",
        summary = "For builds that spike harder from crit than from haste.",
        playstyle = "Prioritizes crit-heavy items without fully ignoring hit and expertise.",
        capRules = {
            hitRating = { cap = 80, postCapWeight = 0.15, label = "Melee hit cap" },
            expertiseRating = { cap = 44, postCapWeight = 0.12, label = "Expertise rating target (26 expertise)" },
            armorPen = { cap = 60, postCapWeight = 0.12, label = "Armor penetration target" },
        },
        weights = {
            strength = 1.50,
            agility = 1.40,
            attackPower = 0.95,
            hitRating = 1.35,
            critRating = 1.50,
            hasteRating = 0.90,
            expertiseRating = 1.10,
            armorPen = 1.05,
            stamina = 0.10,
        },
    },
    physical_haste = {
        name = "Physical Haste Focus",
        role = "physical",
        scalingGroup = "physical",
        summary = "For fast-swinging or proc-driven physical builds.",
        playstyle = "Pushes haste ahead of crit while keeping the rest of the stat package healthy.",
        capRules = {
            hitRating = { cap = 80, postCapWeight = 0.15, label = "Melee hit cap" },
            expertiseRating = { cap = 44, postCapWeight = 0.12, label = "Expertise rating target (26 expertise)" },
            armorPen = { cap = 60, postCapWeight = 0.10, label = "Armor penetration target" },
        },
        weights = {
            strength = 1.55,
            agility = 1.20,
            attackPower = 1.00,
            hitRating = 1.35,
            critRating = 1.05,
            hasteRating = 1.45,
            expertiseRating = 1.10,
            armorPen = 0.95,
            stamina = 0.10,
        },
    },
    spell_dps = {
        name = "Spell DPS",
        role = "spell",
        summary = "Strong default profile for casters who mostly care about raw throughput.",
        playstyle = "Spell power and hit lead, with crit and haste providing secondary value.",
        capRules = {
            hitRating = { cap = 136, postCapWeight = 0.12, label = "Spell hit cap" },
            spellPen = { cap = 60, postCapWeight = 0.05, label = "Spell penetration target" },
        },
        weights = {
            spellPower = 1.70,
            spellPen = 0.55,
            intellect = 0.85,
            spirit = 0.35,
            hitRating = 1.55,
            critRating = 1.15,
            hasteRating = 1.20,
            mp5 = 0.20,
            stamina = 0.10,
        },
    },
    spell_crit = {
        name = "Spell Crit Focus",
        role = "spell",
        summary = "For builds that gain extra value from caster crit synergy.",
        playstyle = "Leans into big crit windows and crit-based passive effects.",
        capRules = {
            hitRating = { cap = 136, postCapWeight = 0.10, label = "Spell hit cap" },
            spellPen = { cap = 60, postCapWeight = 0.05, label = "Spell penetration target" },
        },
        weights = {
            spellPower = 1.55,
            spellPen = 0.60,
            intellect = 0.95,
            spirit = 0.25,
            hitRating = 1.35,
            critRating = 1.50,
            hasteRating = 1.00,
            mp5 = 0.15,
            stamina = 0.10,
        },
    },
    healer_throughput = {
        name = "Healer Throughput",
        role = "healer",
        summary = "For healers who want larger output first and mana later.",
        playstyle = "Favors spell power and haste so heals land bigger and faster.",
        capRules = {
            spellPen = { cap = 60, postCapWeight = 0.00, label = "Spell penetration target" },
        },
        weights = {
            spellPower = 1.65,
            spellPen = 0.20,
            intellect = 1.00,
            spirit = 0.65,
            critRating = 0.95,
            hasteRating = 1.25,
            mp5 = 0.85,
            stamina = 0.20,
        },
    },
    healer_efficiency = {
        name = "Healer Efficiency",
        role = "healer",
        summary = "For longer fights or builds where mana stability matters most.",
        playstyle = "Moves intellect, spirit and mp5 ahead of pure output stats.",
        capRules = {
            spellPen = { cap = 60, postCapWeight = 0.00, label = "Spell penetration target" },
        },
        weights = {
            spellPower = 1.30,
            spellPen = 0.10,
            intellect = 1.20,
            spirit = 1.05,
            critRating = 0.70,
            hasteRating = 0.85,
            mp5 = 1.20,
            stamina = 0.20,
        },
    },
    tank_mitigation = {
        name = "Tank Mitigation",
        role = "tank",
        scalingGroup = "tank",
        summary = "For players who want safer, more durable gear choices.",
        playstyle = "Heavy focus on stamina and defensive ratings.",
        capRules = {
            hitRating = { cap = 80, postCapWeight = 0.05, label = "Tank hit target" },
            expertiseRating = { cap = 44, postCapWeight = 0.05, label = "Tank expertise rating target (26 expertise)" },
        },
        weights = {
            stamina = 1.60,
            strength = 0.45,
            agility = 0.55,
            armor = 0.45,
            defenseRating = 1.35,
            dodgeRating = 1.20,
            parryRating = 1.05,
            blockRating = 0.85,
            blockValue = 0.45,
            hitRating = 0.45,
            expertiseRating = 0.35,
        },
    },
    tank_threat = {
        name = "Tank Threat",
        role = "tank",
        scalingGroup = "tank",
        summary = "For tanks who still need survivability but want stronger threat generation.",
        playstyle = "Balances survivability with hit, expertise and offensive stats.",
        capRules = {
            hitRating = { cap = 80, postCapWeight = 0.12, label = "Tank hit target" },
            expertiseRating = { cap = 44, postCapWeight = 0.10, label = "Tank expertise rating target (26 expertise)" },
        },
        weights = {
            stamina = 1.20,
            strength = 0.95,
            agility = 0.50,
            armor = 0.25,
            defenseRating = 0.95,
            dodgeRating = 0.80,
            parryRating = 0.70,
            blockRating = 0.55,
            blockValue = 0.35,
            hitRating = 1.10,
            expertiseRating = 1.15,
            critRating = 0.60,
        },
    },
}

local function copyCapRules(source)
    local target = {}
    for statKey, rule in pairs(source or {}) do
        target[statKey] = copyTable(rule)
    end
    return target
end

local function applyWeightModifiers(weights, modifiers)
    for statKey, delta in pairs(modifiers or {}) do
        local currentValue = weights[statKey] or 0
        local updatedValue = currentValue + delta
        if updatedValue < 0 then
            updatedValue = 0
        end
        weights[statKey] = updatedValue
    end
end

local function buildSlotLookup(slotIds)
    if not slotIds then
        return nil
    end

    local lookup = {}
    for _, slotId in ipairs(slotIds) do
        lookup[slotId] = true
    end

    return lookup
end

function LS:GetStatValue(stats, statKey)
    local definition = self.statLookup[statKey]
    if not definition or not stats then
        return 0
    end

    local total = 0

    for _, token in ipairs(definition.keys) do
        local value = stats[token]
        if value then
            total = total + value
        end
    end

    return total
end

function LS:GetEquippedStatTotal(statKey, excludedSlots)
    if not statKey then
        return 0
    end

    local total = 0
    local excludedLookup = buildSlotLookup(excludedSlots)

    for slotId = 1, 19 do
        if not excludedLookup or not excludedLookup[slotId] then
            local equippedLink = GetInventoryItemLink("player", slotId)
            if equippedLink then
                local equippedStats = GetItemStats and GetItemStats(equippedLink)
                total = total + self:GetStatValue(equippedStats, statKey)
            end
        end
    end

    return total
end

function LS:RoleUsesScaling(role)
    return role == "physical" or role == "tank"
end

function LS:RoleUsesTankStyle(role)
    return role == "tank"
end

function LS:GetWizardStepCount(answers)
    local role = answers and answers.role
    if self:RoleUsesTankStyle(role) then
        return 4
    end

    if self:RoleUsesScaling(role) then
        return 3
    end

    return 2
end

function LS:GetSelectedScaling(profileId, answers)
    local profile = self.profiles and self.profiles[profileId]
    if not profile or not profile.scalingGroup then
        return nil
    end

    local source = answers or (self.db and self.db.setup)
    if not source or source.role ~= profile.scalingGroup then
        return nil
    end

    local scaling = source and source.scaling or nil
    if scaling == "strength" or scaling == "agility" then
        return scaling
    end

    return nil
end

function LS:GetSelectedTankStyle(profileId, answers)
    local profile = self.profiles and self.profiles[profileId]
    if not profile or profile.scalingGroup ~= "tank" then
        return nil
    end

    local source = answers or (self.db and self.db.setup)
    if not source or source.role ~= "tank" then
        return nil
    end

    local tankStyle = source.tankStyle
    if tankStyle and self.tankStyleChoices[tankStyle] then
        return tankStyle
    end

    return nil
end

function LS:GetScalingLabel(scaling)
    local choice = scaling and self.scalingChoices and self.scalingChoices[scaling]
    return choice and choice.label or nil
end

function LS:GetTankStyleLabel(tankStyle)
    local choice = tankStyle and self.tankStyleChoices and self.tankStyleChoices[tankStyle]
    return choice and choice.label or nil
end

local function joinLabels(parts)
    local labels = {}

    for _, part in ipairs(parts or {}) do
        if part and part ~= "" then
            table.insert(labels, part)
        end
    end

    return table.concat(labels, " / ")
end

function LS:GetProfileContextLabel(profileId, answers)
    local labels = {}
    local tankStyleLabel = self:GetTankStyleLabel(self:GetSelectedTankStyle(profileId, answers))
    local scalingLabel = self:GetScalingLabel(self:GetSelectedScaling(profileId, answers))

    if tankStyleLabel then
        table.insert(labels, tankStyleLabel)
    end

    if scalingLabel then
        table.insert(labels, scalingLabel)
    end

    local combined = joinLabels(labels)
    return combined ~= "" and combined or nil
end

function LS:GetProfileRole(profileId)
    local profile = self.profiles and self.profiles[profileId]
    return profile and profile.role or nil
end

function LS:GetPriorityWizardEntries(profileId)
    local role = self:GetProfileRole(profileId)
    local pool = role and self.priorityWizardPools[role] or nil
    if not pool then
        return {}
    end

    local weights = self:GetEffectiveWeights(profileId)
    local entries = {}

    for _, statKey in ipairs(pool) do
        table.insert(entries, {
            statKey = statKey,
            label = self.statLabels[statKey] or statKey,
            currentWeight = weights[statKey] or 0,
        })
    end

    table.sort(entries, function(left, right)
        if left.currentWeight == right.currentWeight then
            return left.label < right.label
        end
        return left.currentWeight > right.currentWeight
    end)

    return entries
end

function LS:GetPriorityOrderText(profileId, orderedStats)
    local labels = {}

    for _, statKey in ipairs(orderedStats or {}) do
        table.insert(labels, self.statLabels[statKey] or statKey)
    end

    if #labels == 0 then
        local role = self:GetProfileRole(profileId)
        return role and ("Choose your top stats for the " .. role .. " build in the order you want them weighted.") or "Choose your top stats in the order you want them weighted."
    end

    return table.concat(labels, " > ")
end

function LS:ApplyPriorityWizardWeights(profileId, orderedStats)
    if not self.profiles or not self.profiles[profileId] then
        return false, "Unknown profile."
    end

    if type(orderedStats) ~= "table" or #orderedStats == 0 then
        return false, "Pick at least one stat."
    end

    local entries = self:GetPriorityWizardEntries(profileId)
    local orderedLookup = {}
    local finalOrder = {}

    for _, statKey in ipairs(orderedStats) do
        if self.statLookup[statKey] and not orderedLookup[statKey] then
            orderedLookup[statKey] = true
            table.insert(finalOrder, statKey)
        end
    end

    for _, entry in ipairs(entries) do
        if not orderedLookup[entry.statKey] then
            table.insert(finalOrder, entry.statKey)
        end
    end

    self:ClearCustomWeights(profileId)

    for index, statKey in ipairs(finalOrder) do
        local weight = self.priorityWizardWeightCurve[index]
        if not weight then
            local tailIndex = index - #self.priorityWizardWeightCurve
            weight = math.max(0.05, self.priorityWizardWeightCurve[#self.priorityWizardWeightCurve] - (tailIndex * 0.05))
        end
        self:SetCustomWeight(profileId, statKey, weight)
    end

    return true
end

function LS:GetProfileDisplayName(profileId, answers)
    local profile = self.profiles and self.profiles[profileId]
    if not profile then
        return nil
    end

    local contextLabel = self:GetProfileContextLabel(profileId, answers)
    if contextLabel then
        return profile.name .. " - " .. contextLabel
    end

    return profile.name
end

function LS:GetProfileSummaryText(profileId, profile, answers)
    if not profile then
        return ""
    end

    local lines = { profile.summary }
    local tankStyleLabel = self:GetTankStyleLabel(self:GetSelectedTankStyle(profileId, answers))
    local scalingLabel = self:GetScalingLabel(self:GetSelectedScaling(profileId, answers))

    if tankStyleLabel then
        table.insert(lines, "Current tank style: " .. tankStyleLabel .. ".")
    end

    if scalingLabel then
        table.insert(lines, "Current scaling: " .. scalingLabel .. ".")
    end

    return table.concat(lines, "\n")
end

function LS:GetEffectiveCapRules(profileId)
    local profile = self.profiles and self.profiles[profileId]
    if not profile then
        return {}
    end

    local capRules = copyCapRules(profile.capRules)
    local customCaps = self.db and self.db.customCaps and self.db.customCaps[profileId]

    if customCaps then
        for statKey, rule in pairs(customCaps) do
            if type(rule) == "table" then
                capRules[statKey] = copyTable(rule)
            end
        end
    end

    return capRules
end

function LS:GetCustomCapRules(profileId)
    if not self.db or not self.db.customCaps then
        return nil
    end

    return self.db.customCaps[profileId]
end

function LS:GetCustomCapCount(profileId)
    local customCaps = self:GetCustomCapRules(profileId)
    if not customCaps then
        return 0
    end

    local count = 0
    for _ in pairs(customCaps) do
        count = count + 1
    end

    return count
end

function LS:SetCustomCapRule(profileId, statKey, cap, postCapWeight)
    if not self.profiles or not self.profiles[profileId] then
        return false, "Unknown profile."
    end

    if not self.statLookup[statKey] then
        return false, "Unknown stat. Use /ls stats to see valid keys."
    end

    if type(cap) ~= "number" then
        return false, "Cap must be a number."
    end

    if postCapWeight ~= nil and type(postCapWeight) ~= "number" then
        return false, "Post-cap weight must be a number."
    end

    if not self.db.customCaps then
        self.db.customCaps = {}
    end

    if not self.db.customCaps[profileId] then
        self.db.customCaps[profileId] = {}
    end

    local existing = self:GetEffectiveCapRules(profileId)[statKey] or {}
    self.db.customCaps[profileId][statKey] = {
        cap = cap,
        postCapWeight = postCapWeight ~= nil and postCapWeight or existing.postCapWeight or 0,
        label = existing.label or (self.statLabels[statKey] .. " cap"),
    }

    return true
end

function LS:ClearCustomCapRule(profileId, statKey)
    if not self.db or not self.db.customCaps or not self.db.customCaps[profileId] then
        return
    end

    self.db.customCaps[profileId][statKey] = nil
    if not next(self.db.customCaps[profileId]) then
        self.db.customCaps[profileId] = nil
    end
end

function LS:ClearCustomCapRules(profileId)
    if self.db and self.db.customCaps then
        self.db.customCaps[profileId] = nil
    end
end

function LS:GetCapListText(profileId)
    local capRules = self:GetEffectiveCapRules(profileId)
    local customCaps = self:GetCustomCapRules(profileId) or {}
    local entries = {}

    for statKey, rule in pairs(capRules) do
        table.insert(entries, {
            statKey = statKey,
            cap = rule.cap,
            postCapWeight = rule.postCapWeight or 0,
            customized = customCaps[statKey] ~= nil,
        })
    end

    table.sort(entries, function(left, right)
        return (self.statLabels[left.statKey] or left.statKey) < (self.statLabels[right.statKey] or right.statKey)
    end)

    local parts = {}
    for _, entry in ipairs(entries) do
        local suffix = entry.customized and "*" or ""
        table.insert(parts, string.format("%s cap=%0.0f post=%0.2f%s", entry.statKey, entry.cap, entry.postCapWeight, suffix))
    end

    return table.concat(parts, ", ")
end

function LS:GetCappedContribution(statKey, value, weight, capRule, context)
    local equippedTotal = self:GetEquippedStatTotal(statKey, context and context.excludedSlots)
    local remainingBeforeCap = (capRule.cap or 0) - equippedTotal
    local preCapValue = value
    local postCapValue = 0
    local postCapWeight = capRule.postCapWeight or 0

    if remainingBeforeCap <= 0 then
        preCapValue = 0
        postCapValue = value
    elseif value > remainingBeforeCap then
        preCapValue = remainingBeforeCap
        postCapValue = value - remainingBeforeCap
    end

    local weightedValue = (preCapValue * weight) + (postCapValue * postCapWeight)
    local breakdownText

    if postCapValue > 0 then
        breakdownText = string.format(
            "%d x %.2f + %d x %.2f = %.1f",
            preCapValue,
            weight,
            postCapValue,
            postCapWeight,
            weightedValue
        )
    else
        breakdownText = string.format("%d x %.2f = %.1f", preCapValue, weight, weightedValue)
    end

    return weightedValue, {
        cap = capRule.cap,
        label = capRule.label,
        equippedTotal = equippedTotal,
        preCapValue = preCapValue,
        postCapValue = postCapValue,
        postCapWeight = postCapWeight,
        breakdownText = breakdownText,
    }
end

function LS:GetItemScore(itemLink, context)
    if not itemLink then
        return nil
    end

    local profileId, profile = self:GetActiveProfile()
    if not profile then
        return nil
    end

    if not GetItemStats then
        return nil
    end

    local stats = GetItemStats(itemLink)
    if not stats then
        return nil
    end

    local score = 0
    local contributions = {}
    local weights = self:GetEffectiveWeights(profileId)
    local capRules = self:GetEffectiveCapRules(profileId)

    for statKey, weight in pairs(weights) do
        local value = self:GetStatValue(stats, statKey)
        if value > 0 and weight ~= 0 then
            local weightedValue = value * weight
            local capInfo = nil

            if capRules[statKey] then
                weightedValue, capInfo = self:GetCappedContribution(statKey, value, weight, capRules[statKey], context)
            end

            score = score + weightedValue
            table.insert(contributions, {
                key = statKey,
                label = self.statLabels[statKey] or statKey,
                value = value,
                weight = weight,
                weightedValue = weightedValue,
                capInfo = capInfo,
                breakdownText = capInfo and capInfo.breakdownText or string.format("%d x %.2f = %.1f", value, weight, weightedValue),
            })
        end
    end

    table.sort(contributions, function(left, right)
        return left.weightedValue > right.weightedValue
    end)

    return score, contributions, stats
end

function LS:GetProfilePriorityText(profile, answers)
    if not profile or not profile.weights then
        return ""
    end

    local profileId = nil
    for candidateProfileId, candidateProfile in pairs(self.profiles) do
        if candidateProfile == profile then
            profileId = candidateProfileId
            break
        end
    end

    local weights = profileId and self:GetEffectiveWeights(profileId, answers) or profile.weights
    local ordered = {}

    for statKey, weight in pairs(weights) do
        if weight > 0 then
            table.insert(ordered, {
                key = statKey,
                label = self.statLabels[statKey] or statKey,
                weight = weight,
            })
        end
    end

    table.sort(ordered, function(left, right)
        return left.weight > right.weight
    end)

    local labels = {}
    local limit = math.min(5, #ordered)

    for index = 1, limit do
        table.insert(labels, ordered[index].label)
    end

    return table.concat(labels, " > ")
end

function LS:GetTopWeightEntries(profileId, answers, limit)
    local weights = self:GetEffectiveWeights(profileId, answers)
    local ordered = {}

    for statKey, weight in pairs(weights) do
        if weight > 0 then
            table.insert(ordered, {
                statKey = statKey,
                label = self.statLabels[statKey] or statKey,
                weight = weight,
            })
        end
    end

    table.sort(ordered, function(left, right)
        if left.weight == right.weight then
            return left.label < right.label
        end
        return left.weight > right.weight
    end)

    if limit and limit > 0 and #ordered > limit then
        local trimmed = {}
        for index = 1, limit do
            trimmed[index] = ordered[index]
        end
        return trimmed
    end

    return ordered
end

function LS:GetTopWeightText(profileId, answers, limit)
    local entries = self:GetTopWeightEntries(profileId, answers, limit)
    local parts = {}

    for _, entry in ipairs(entries) do
        table.insert(parts, string.format("%s %.2f", entry.label, entry.weight))
    end

    return table.concat(parts, " | ")
end

function LS:GetCapDebugText(profileId)
    local capRules = self:GetEffectiveCapRules(profileId)
    local entries = {}

    for statKey, rule in pairs(capRules) do
        table.insert(entries, {
            label = self.statLabels[statKey] or statKey,
            cap = rule.cap or 0,
            postCapWeight = rule.postCapWeight or 0,
        })
    end

    table.sort(entries, function(left, right)
        return left.label < right.label
    end)

    local parts = {}
    for _, entry in ipairs(entries) do
        table.insert(parts, string.format("%s %d/%.2f", entry.label, entry.cap, entry.postCapWeight))
    end

    return table.concat(parts, " | ")
end

function LS:GetModelDebugLines(profileId, answers)
    local profile = self.profiles and self.profiles[profileId]
    if not profile then
        return {}
    end

    local lines = {
        "Model: " .. (self:GetProfileDisplayName(profileId, answers) or profile.name),
    }

    local priorityText = self:GetProfilePriorityText(profile, answers)
    if priorityText ~= "" then
        table.insert(lines, "Priority: " .. priorityText)
    end

    local topWeightsText = self:GetTopWeightText(profileId, answers, 5)
    if topWeightsText ~= "" then
        table.insert(lines, "Top weights: " .. topWeightsText)
    end

    local capText = self:GetCapDebugText(profileId)
    if capText ~= "" then
        table.insert(lines, "Caps: " .. capText)
    end

    return lines
end

function LS:GetEffectiveWeights(profileId, answers)
    local profile = self.profiles and self.profiles[profileId]
    if not profile or not profile.weights then
        return {}
    end

    local weights = copyTable(profile.weights)
    local scalingGroup = profile.scalingGroup
    local scaling = self:GetSelectedScaling(profileId, answers)

    if scalingGroup and scaling and self.scalingModifiers[scalingGroup] then
        applyWeightModifiers(weights, self.scalingModifiers[scalingGroup][scaling])
    end

    local tankStyle = self:GetSelectedTankStyle(profileId, answers)
    if tankStyle and self.tankStyleModifiers[tankStyle] then
        applyWeightModifiers(weights, self.tankStyleModifiers[tankStyle])
    end

    local customWeights = self.db and self.db.customWeights and self.db.customWeights[profileId]

    if customWeights then
        for statKey, value in pairs(customWeights) do
            weights[statKey] = value
        end
    end

    return weights
end

function LS:GetCustomWeights(profileId)
    if not self.db or not self.db.customWeights then
        return nil
    end

    return self.db.customWeights[profileId]
end

function LS:GetCustomWeightCount(profileId)
    local customWeights = self:GetCustomWeights(profileId)
    if not customWeights then
        return 0
    end

    local count = 0
    for _ in pairs(customWeights) do
        count = count + 1
    end

    return count
end

function LS:SetCustomWeight(profileId, statKey, value)
    if not self.profiles or not self.profiles[profileId] then
        return false, "Unknown profile."
    end

    if not self.statLookup[statKey] then
        return false, "Unknown stat. Use /ls stats to see valid keys."
    end

    if type(value) ~= "number" then
        return false, "Weight must be a number."
    end

    if not self.db.customWeights then
        self.db.customWeights = {}
    end

    if not self.db.customWeights[profileId] then
        self.db.customWeights[profileId] = {}
    end

    self.db.customWeights[profileId][statKey] = value
    return true
end

function LS:ClearCustomWeights(profileId)
    if self.db and self.db.customWeights then
        self.db.customWeights[profileId] = nil
    end
end

function LS:ClearCustomWeight(profileId, statKey)
    if not self.db or not self.db.customWeights or not self.db.customWeights[profileId] then
        return
    end

    self.db.customWeights[profileId][statKey] = nil
    if not next(self.db.customWeights[profileId]) then
        self.db.customWeights[profileId] = nil
    end
end

function LS:GetWeightListText(profileId)
    local profile = self.profiles and self.profiles[profileId]
    if not profile then
        return nil
    end

    local weights = self:GetEffectiveWeights(profileId)
    local ordered = {}
    local customWeights = self:GetCustomWeights(profileId) or {}

    for statKey, weight in pairs(weights) do
        table.insert(ordered, {
            statKey = statKey,
            label = self.statLabels[statKey] or statKey,
            weight = weight,
            customized = customWeights[statKey] ~= nil,
        })
    end

    table.sort(ordered, function(left, right)
        return left.weight > right.weight
    end)

    local parts = {}
    for _, entry in ipairs(ordered) do
        local suffix = entry.customized and "*" or ""
        table.insert(parts, string.format("%s=%0.2f%s", entry.statKey, entry.weight, suffix))
    end

    return table.concat(parts, ", ")
end

function LS:GetEditableWeightEntries(profileId)
    local profile = self.profiles and self.profiles[profileId]
    if not profile or not profile.weights then
        return {}
    end

    local effectiveWeights = self:GetEffectiveWeights(profileId)
    local customWeights = self:GetCustomWeights(profileId) or {}
    local entries = {}
    local seen = {}

    for statKey, baseWeight in pairs(profile.weights) do
        table.insert(entries, {
            statKey = statKey,
            label = self.statLabels[statKey] or statKey,
            baseWeight = baseWeight,
            effectiveWeight = effectiveWeights[statKey] or baseWeight,
            customized = customWeights[statKey] ~= nil,
        })
        seen[statKey] = true
    end

    for statKey, customValue in pairs(customWeights) do
        if not seen[statKey] then
            table.insert(entries, {
                statKey = statKey,
                label = self.statLabels[statKey] or statKey,
                baseWeight = profile.weights[statKey] or 0,
                effectiveWeight = customValue,
                customized = true,
            })
        end
    end

    table.sort(entries, function(left, right)
        if left.effectiveWeight == right.effectiveWeight then
            return left.label < right.label
        end
        return left.effectiveWeight > right.effectiveWeight
    end)

    return entries
end

function LS:GetEditableCapEntries(profileId)
    local profile = self.profiles and self.profiles[profileId]
    if not profile then
        return {}
    end

    local baseRules = profile.capRules or {}
    local effectiveRules = self:GetEffectiveCapRules(profileId)
    local customRules = self:GetCustomCapRules(profileId) or {}
    local entries = {}
    local seen = {}

    for statKey, baseRule in pairs(baseRules) do
        local effectiveRule = effectiveRules[statKey] or {}
        table.insert(entries, {
            statKey = statKey,
            label = self.statLabels[statKey] or statKey,
            baseCap = baseRule.cap or 0,
            basePostCapWeight = baseRule.postCapWeight or 0,
            effectiveCap = effectiveRule.cap or baseRule.cap or 0,
            effectivePostCapWeight = effectiveRule.postCapWeight or baseRule.postCapWeight or 0,
            customized = customRules[statKey] ~= nil,
        })
        seen[statKey] = true
    end

    for statKey, customRule in pairs(customRules) do
        if not seen[statKey] then
            table.insert(entries, {
                statKey = statKey,
                label = self.statLabels[statKey] or statKey,
                baseCap = 0,
                basePostCapWeight = 0,
                effectiveCap = customRule.cap or 0,
                effectivePostCapWeight = customRule.postCapWeight or 0,
                customized = true,
            })
        end
    end

    table.sort(entries, function(left, right)
        return left.label < right.label
    end)

    return entries
end

function LS:GetWizardStepData(stepIndex, answers)
    if stepIndex == 1 then
        return {
            title = "Step 1: What kind of build is this?",
            description = "Pick the broad role first. You can fine-tune the exact preset in the next step.",
            options = {
                {
                    value = "physical",
                    title = "Physical DPS",
                    description = "Weapons, attack power, crit, haste and similar offensive stats.",
                },
                {
                    value = "spell",
                    title = "Spell DPS",
                    description = "Spell power, caster hit, crit, haste and mana-related caster stats.",
                },
                {
                    value = "healer",
                    title = "Healer",
                    description = "Healing output or mana stability for support-focused builds.",
                },
                {
                    value = "tank",
                    title = "Tank",
                    description = "Mitigation, stamina and threat generation for front-line builds.",
                },
            },
        }
    end

    if not answers or not answers.role then
        return nil
    end

    if stepIndex == 3 and answers.role == "physical" then
        return {
            title = "Step 3: Which main stat drives this build?",
            description = "Pick the primary stat scaling that best matches how this build actually gets value from gear.",
            options = {
                { value = "strength", title = "Strength-based", description = "Use this for builds that still want strength as the main stat driver." },
                { value = "agility", title = "Agility-based", description = "Use this for setups that scale more from agility, dodge and crit." },
            },
        }
    end

    if stepIndex == 3 and answers.role == "tank" then
        return {
            title = "Step 3: Which tank style fits best?",
            description = "Pick the mitigation style that best matches how this tank survives incoming damage.",
            options = {
                { value = "evasion", title = "Evasion", description = "Best for tanks that lean on agility, dodge and avoidance." },
                { value = "block", title = "Block", description = "Best for shield tanks where block rating and block value matter a lot." },
                { value = "health", title = "Health/Armor", description = "Best for tanks that want larger health pools and more raw armor." },
            },
        }
    end

    if stepIndex == 4 and answers.role == "tank" then
        return {
            title = "Step 4: Which main stat drives this build?",
            description = "Pick the primary stat scaling that best matches how this tank gets value from gear.",
            options = {
                { value = "strength", title = "Strength-based", description = "Use this for shield or weapon-focused tanks that still want strength as the main stat driver." },
                { value = "agility", title = "Agility-based", description = "Use this for tanks that scale more from agility, dodge and crit than from strength." },
            },
        }
    end

    if stepIndex ~= 2 then
        return nil
    end

    if answers.role == "physical" then
        return {
            title = "Step 2: What should the gear lean toward?",
            description = "Choose the version that best matches how the build actually deals damage.",
            options = {
                { value = "balanced", title = "Balanced", description = "General all-round physical DPS." },
                { value = "crit", title = "Crit Focus", description = "Best when crit interactions matter more than raw speed." },
                { value = "haste", title = "Haste Focus", description = "Best for fast swings, procs and speed-driven gameplay." },
            },
        }
    end

    if answers.role == "spell" then
        return {
            title = "Step 2: What kind of caster profile fits best?",
            description = "Most casters should start with balanced unless crit synergies are central to the build.",
            options = {
                { value = "balanced", title = "Balanced Throughput", description = "Default caster profile with spell power, hit and haste." },
                { value = "crit", title = "Crit Focus", description = "For builds that gain unusual value from spell crit." },
            },
        }
    end

    if answers.role == "healer" then
        return {
            title = "Step 2: What do you want your healing gear to solve?",
            description = "Choose whether you care most about bigger heals now or lasting longer in mana-heavy fights.",
            options = {
                { value = "throughput", title = "Throughput", description = "More raw healing output and faster casts." },
                { value = "efficiency", title = "Efficiency", description = "Stronger mana longevity and steadier sustain." },
            },
        }
    end

    if answers.role == "tank" then
        return {
            title = "Step 2: What is the tank gear priority?",
            description = "Pick the style that better reflects your current need in groups or raids.",
            options = {
                { value = "mitigation", title = "Mitigation", description = "Safer, sturdier gearing for survival first." },
                { value = "threat", title = "Threat", description = "More aggressive gearing while keeping core durability." },
            },
        }
    end

    return nil
end

function LS:GetRecommendedProfileFromAnswers(answers)
    if not answers or not answers.role then
        return nil
    end

    if answers.role == "physical" then
        if answers.focus == "crit" then
            return "physical_crit"
        end
        if answers.focus == "haste" then
            return "physical_haste"
        end
        return "physical_dps"
    end

    if answers.role == "spell" then
        if answers.focus == "crit" then
            return "spell_crit"
        end
        return "spell_dps"
    end

    if answers.role == "healer" then
        if answers.focus == "efficiency" then
            return "healer_efficiency"
        end
        return "healer_throughput"
    end

    if answers.role == "tank" then
        if answers.focus == "threat" then
            return "tank_threat"
        end
        return "tank_mitigation"
    end

    return nil
end