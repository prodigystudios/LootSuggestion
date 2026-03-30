local LS = _G.LootSuggestionAddon

local tooltipTargets = {
    GameTooltip,
    ItemRefTooltip,
    ShoppingTooltip1,
    ShoppingTooltip2,
}

local function addScoreLine(tooltip, label, value, red, green, blue)
    tooltip:AddDoubleLine(label, value, 1, 1, 1, red, green, blue)
end

local function addSectionTitle(tooltip, text)
    tooltip:AddLine(text, 0.95, 0.82, 0.28)
end

local function addMutedLine(tooltip, text)
    tooltip:AddLine(text, 0.72, 0.72, 0.72, true)
end

local function formatCustomizationText(weightCount, capCount)
    local parts = {}

    if weightCount > 0 then
        table.insert(parts, string.format("%d weight override%s", weightCount, weightCount == 1 and "" or "s"))
    end

    if capCount > 0 then
        table.insert(parts, string.format("%d cap override%s", capCount, capCount == 1 and "" or "s"))
    end

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, " | ")
end

local function formatDelta(delta)
    if delta > 0 then
        return string.format("Better than equipped (+%.1f)", delta), 0.20, 1.00, 0.20
    end

    if delta < 0 then
        return string.format("Worse than equipped (%.1f)", delta), 1.00, 0.25, 0.25
    end

    return "Same as equipped (0.0)", 0.85, 0.85, 0.85
end

local function getCapDetailText(capInfo)
    if not capInfo then
        return nil
    end

    local equippedValue = capInfo.equippedTotal or 0
    local capValue = capInfo.cap or 0
    local preCapValue = capInfo.preCapValue or 0
    local postCapValue = capInfo.postCapValue or 0
    local postCapWeight = capInfo.postCapWeight or 0

    if postCapValue > 0 and preCapValue > 0 then
        return string.format(
            "%d/%d equipped, +%d full, +%d over at %.2f",
            equippedValue,
            capValue,
            preCapValue,
            postCapValue,
            postCapWeight
        )
    end

    if postCapValue > 0 then
        return string.format(
            "%d/%d equipped, item is already over cap, +%d at %.2f",
            equippedValue,
            capValue,
            postCapValue,
            postCapWeight
        )
    end

    return nil
end

local function formatContributionLine(entry)
    if not entry then
        return nil, nil
    end

    local value = entry.value or 0
    local displayValue = math.abs(value - math.floor(value + 0.5)) < 0.001 and string.format("%.0f", value) or string.format("%.2f", value)
    local label = string.format("%s +%s", entry.label, displayValue)

    if entry.capInfo and entry.capInfo.breakdownText then
        return label, entry.capInfo.breakdownText
    end

    return label, string.format("x %.2f = %.1f", entry.weight or 0, entry.weightedValue or 0)
end

function LS:AddTooltipScore(tooltip)
    if not self.db or not self.db.showTooltipScores then
        return
    end

    if tooltip.LootSuggestionProcessed then
        return
    end

    local _, itemLink = tooltip:GetItem()
    if not itemLink then
        return
    end

    local score, contributions = self:GetItemScore(itemLink)
    if not score then
        return
    end

    local profileId, profile = self:GetActiveProfile()
    local customWeightCount = self:GetCustomWeightCount(profileId)
    local customCapCount = self:GetCustomCapCount(profileId)
    local customizationText = formatCustomizationText(customWeightCount, customCapCount)
    local profileDisplayName = self.GetProfileDisplayName and self:GetProfileDisplayName(profileId) or nil

    tooltip:AddLine(" ")
    tooltip:AddLine("|cff5fb0ffLootSuggestion|r")
    addScoreLine(tooltip, "Profile", profileDisplayName or profile.name, 0.60, 0.80, 1.00)
    addScoreLine(tooltip, "Score", string.format("%.1f", score), 0.20, 1.00, 0.20)

    if customizationText then
        addMutedLine(tooltip, customizationText)
    end

    if self.db.showDebugDetails and self.GetModelDebugLines then
        addSectionTitle(tooltip, "Tuning")
        local modelLines = self:GetModelDebugLines(profileId)
        for _, line in ipairs(modelLines) do
            addMutedLine(tooltip, line)
        end
    end

    if self.db.compareEquipped then
        local comparison = self:GetEquippedComparison(itemLink, score)
        if comparison then
            addSectionTitle(tooltip, "Comparison")
            local deltaText, red, green, blue = formatDelta(comparison.delta)
            addScoreLine(tooltip, comparison.label, deltaText, red, green, blue)
        end
    end

    if self.db.showBreakdown and contributions and contributions[1] then
        addSectionTitle(tooltip, "Top contributors")

        local maxRows = math.min(3, #contributions)
        for index = 1, maxRows do
            local entry = contributions[index]
            local labelText, valueText = formatContributionLine(entry)
            addScoreLine(tooltip, labelText, valueText, 0.90, 0.90, 0.90)

            local capDetailText = getCapDetailText(entry.capInfo)
            if capDetailText then
                addMutedLine(tooltip, string.format("  %s: %s", entry.capInfo.label or "Cap", capDetailText))
            end
        end
    end

    tooltip.LootSuggestionProcessed = true
    tooltip:Show()
end

for _, tooltip in ipairs(tooltipTargets) do
    tooltip:HookScript("OnTooltipCleared", function(current)
        current.LootSuggestionProcessed = nil
    end)

    tooltip:HookScript("OnTooltipSetItem", function(current)
        LS:AddTooltipScore(current)
    end)
end