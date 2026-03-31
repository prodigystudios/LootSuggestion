local LS = _G.LootSuggestionAddon
local GetInventoryItemLink = _G.GetInventoryItemLink
local GetItemInfo = rawget(_G, "GetItemInfo")
local GetSpellInfo = rawget(_G, "GetSpellInfo")
local UnitClass = _G.UnitClass

if not LS then
    LS = {}
    _G.LootSuggestionAddon = LS
end

LS.addonName = "LootSuggestion"
LS.defaults = {
    selectedProfile = "physical_dps",
    showTooltipScores = true,
    compareEquipped = true,
    showBreakdown = true,
    showDebugDetails = false,
    customWeights = {},
    customCaps = {},
    manualPassives = {},
    caKnownSpellIDs = {},
    caKnownPassiveNames = {},
    setup = {
        completed = false,
        class = nil,
        spec = nil,
        role = nil,
        focus = nil,
        tankStyle = nil,
        scaling = nil,
        recommendedProfile = nil,
        sourcePreset = nil,
    },
    framePosition = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
    },
}

LS.slotNames = {
    [1] = "Head",
    [2] = "Neck",
    [3] = "Shoulder",
    [4] = "Shirt",
    [5] = "Chest",
    [6] = "Waist",
    [7] = "Legs",
    [8] = "Feet",
    [9] = "Wrist",
    [10] = "Hands",
    [11] = "Ring 1",
    [12] = "Ring 2",
    [13] = "Trinket 1",
    [14] = "Trinket 2",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand",
    [18] = "Ranged",
    [19] = "Tabard",
}

LS.equipLocToSlots = {
    INVTYPE_HEAD = { 1 },
    INVTYPE_NECK = { 2 },
    INVTYPE_SHOULDER = { 3 },
    INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_HOLDABLE = { 17 },
    INVTYPE_SHIELD = { 17 },
    INVTYPE_RANGED = { 18 },
    INVTYPE_THROWN = { 18 },
    INVTYPE_RELIC = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 },
    INVTYPE_TABARD = { 19 },
}

local function copyDefaults(source, destination)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(destination[key]) ~= "table" then
                destination[key] = {}
            end
            copyDefaults(value, destination[key])
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
end

local function countTableEntries(value)
    if type(value) ~= "table" then
        return 0
    end

    local count = 0
    for _ in pairs(value) do
        count = count + 1
    end
    return count
end

local function buildCharacterAdvancementCacheSignature(db)
    if type(db) ~= "table" then
        return ""
    end

    local entries = {}

    for spellId, isKnown in pairs(db.caKnownSpellIDs or {}) do
        if isKnown then
            table.insert(entries, "s:" .. tostring(spellId))
        end
    end

    for passiveName, isKnown in pairs(db.caKnownPassiveNames or {}) do
        if isKnown then
            table.insert(entries, "n:" .. tostring(passiveName))
        end
    end

    table.sort(entries)
    return table.concat(entries, "|")
end

function LS:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff5fb0ffLootSuggestion|r " .. tostring(message))
end

function LS:RefreshCharacterAdvancementCache(trigger)
    if not self.RefreshCharacterAdvancementSpellCache or not self.db then
        return false
    end

    local beforeSignature = buildCharacterAdvancementCacheSignature(self.db)
    self:RefreshCharacterAdvancementSpellCache()
    local afterSignature = buildCharacterAdvancementCacheSignature(self.db)

    if beforeSignature ~= afterSignature then
        if self.InvalidateTooltipCaches then
            self:InvalidateTooltipCaches()
        end
        if self.RefreshUI and self.mainFrame and self.mainFrame:IsShown() then
            self:RefreshUI()
        end
        return true
    end

    return false
end

function LS:TryInstallCharacterAdvancementHooks()
    if self.caHooksInstalled then
        return true
    end

    local ca = rawget(_G, "CharacterAdvancement")
    if not ca or type(ca.HookScript) ~= "function" then
        return false
    end

    ca:HookScript("OnShow", function()
        LS:RefreshCharacterAdvancementCache("show")
    end)

    self.caHooksInstalled = true
    return true
end

function LS:StartCharacterAdvancementMonitor()
    if self.caMonitorFrame then
        return
    end

    local monitorFrame = CreateFrame("Frame")
    local elapsedSinceRefresh = 0
    local installAttempts = 0

    monitorFrame:SetScript("OnUpdate", function(frame, elapsed)
        elapsedSinceRefresh = elapsedSinceRefresh + (elapsed or 0)
        if elapsedSinceRefresh < 5 then
            return
        end
        elapsedSinceRefresh = 0
        installAttempts = installAttempts + 1

        if LS:TryInstallCharacterAdvancementHooks() then
            frame:SetScript("OnUpdate", nil)
            return
        end

        if installAttempts >= 12 then
            frame:SetScript("OnUpdate", nil)
        end
    end)

    self.caMonitorFrame = monitorFrame
end

function LS:InitializeDatabase()
    if type(_G.LootSuggestion) ~= "table" then
        _G.LootSuggestion = {}
    end

    self.db = _G.LootSuggestion
    copyDefaults(self.defaults, self.db)

    if self.UpgradeSetupData then
        self:UpgradeSetupData()
    end
end

function LS:GetActiveProfile()
    if not self.profiles then
        return nil
    end

    local profileId = self.db and self.db.selectedProfile or self.defaults.selectedProfile
    local profile = self.profiles[profileId]

    if profile then
        return profileId, profile
    end

    return self.profileOrder[1], self.profiles[self.profileOrder[1]]
end

function LS:SetSelectedProfile(profileId)
    if not self.profiles or not self.profiles[profileId] then
        return
    end

    self.db.selectedProfile = profileId

    if self.InvalidateTooltipCaches then
        self:InvalidateTooltipCaches()
    end

    if self.RefreshUI then
        self:RefreshUI()
    end

    self:Print("Active profile: " .. (self.GetProfileDisplayName and self:GetProfileDisplayName(profileId) or self.profiles[profileId].name))
end

function LS:SetSelectedClassSpec(classToken, specToken)
    if not classToken or not specToken then
        return false, "Missing class or spec."
    end

    local role = self.GetRoleForSpec and self:GetRoleForSpec(classToken, specToken) or nil
    if not role then
        return false, "Unknown spec for class."
    end

    local answers = {
        class = classToken,
        spec = specToken,
        role = role,
    }
    answers.sourcePreset = self.GetSourcePresetKeyFromAnswers and self:GetSourcePresetKeyFromAnswers(answers) or nil

    local profileId = self.GetRecommendedProfileFromAnswers and self:GetRecommendedProfileFromAnswers(answers) or nil
    if not profileId or not self.profiles or not self.profiles[profileId] then
        return false, "Unable to resolve a profile for that spec."
    end

    self.db.setup.completed = true
    self.db.setup.class = classToken
    self.db.setup.spec = specToken
    self.db.setup.role = role
    self.db.setup.focus = nil
    self.db.setup.tankStyle = nil
    self.db.setup.scaling = nil
    self.db.setup.recommendedProfile = profileId
    self.db.setup.sourcePreset = answers.sourcePreset
    self.db.selectedProfile = profileId

    if self.InvalidateTooltipCaches then
        self:InvalidateTooltipCaches()
    end

    if self.RefreshUI then
        self:RefreshUI()
    end

    self:Print("Active build: " .. self:GetClassLabel(classToken) .. " / " .. self:GetSpecLabel(classToken, specToken))
    return true
end

function LS:StartSetupWizard()
    if self.OpenSetupModeSelector then
        self:OpenSetupModeSelector()
    end
end

function LS:StartGuidedSetupWizard()
    if self.CloseSetupModeSelector then
        self:CloseSetupModeSelector()
    end

    if not self.CreateMainFrame then
        return
    end

    if not self.mainFrame then
        self:CreateMainFrame()
    end

    self.wizardAnswers = {
        class = self.db.setup.class,
        spec = self.db.setup.spec,
        role = self.db.setup.role,
        sourcePreset = self.db.setup.sourcePreset,
    }

    if not self.wizardAnswers.class and UnitClass then
        local _, classToken = UnitClass("player")
        self.wizardAnswers.class = classToken
    end

    self.weightEditorOpen = false
    self.capEditorOpen = false
    self.priorityWizardOpen = false
    self.wizardStep = 1
    self.mainFrame:Show()

    if self.RefreshUI then
        self:RefreshUI()
    end
end

function LS:StartAdvancedSetupWizard()
    if self.CloseSetupModeSelector then
        self:CloseSetupModeSelector()
    end

    if self.OpenPriorityWizard then
        self:OpenPriorityWizard()
    end
end

function LS:FinishSetupWizard(profileId)
    if not profileId or not self.profiles[profileId] then
        return
    end

    self.db.setup.completed = true
    self.db.setup.class = self.wizardAnswers and self.wizardAnswers.class or nil
    self.db.setup.spec = self.wizardAnswers and self.wizardAnswers.spec or nil
    self.db.setup.role = self.wizardAnswers and self.wizardAnswers.role or nil
    self.db.setup.focus = nil
    self.db.setup.tankStyle = nil
    self.db.setup.scaling = nil
    self.db.setup.recommendedProfile = profileId
    self.db.setup.sourcePreset = self.wizardAnswers and self.wizardAnswers.sourcePreset or nil
    self.wizardStep = nil

    self:SetSelectedProfile(profileId)

    if self.RefreshUI then
        self:RefreshUI()
    end

    self:Print("Setup complete. Hover gear to see scores with your chosen profile.")
end

function LS:GetComparisonTarget(itemLink)
    if not itemLink then
        return nil
    end

    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    if not equipLoc or equipLoc == "" then
        return nil
    end

    if equipLoc == "INVTYPE_WEAPON" then
        local mainHandLoc = self:GetItemEquipLocation(GetInventoryItemLink("player", 16))
        local offHandLoc = self:GetItemEquipLocation(GetInventoryItemLink("player", 17))
        local candidateSlots = {}

        if mainHandLoc ~= "INVTYPE_2HWEAPON" then
            table.insert(candidateSlots, 16)
        end

        if not offHandLoc or offHandLoc == "INVTYPE_WEAPON" or offHandLoc == "INVTYPE_WEAPONOFFHAND" then
            table.insert(candidateSlots, 17)
        end

        if candidateSlots[1] then
            return candidateSlots
        end
    end

    return self.equipLocToSlots[equipLoc]
end

function LS:GetItemEquipLocation(itemLink)
    if not itemLink or not GetItemInfo then
        return nil
    end

    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    return equipLoc
end

function LS:IsTwoHandedSetupEquipped()
    local mainHandLink = GetInventoryItemLink("player", 16)
    return self:GetItemEquipLocation(mainHandLink) == "INVTYPE_2HWEAPON"
end

local function isGenericOneHandWeapon(equipLoc)
    return equipLoc == "INVTYPE_WEAPON"
end

local function isMainHandWeapon(equipLoc)
    return equipLoc == "INVTYPE_WEAPONMAINHAND"
end

local function isOffHandWeapon(equipLoc)
    return equipLoc == "INVTYPE_WEAPONOFFHAND"
end

local function isOffHandSupport(equipLoc)
    return equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE"
end

local function isDualWieldOffHand(equipLoc)
    return equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND"
end

function LS:GetWeaponComparisonCandidates(itemLink)
    local equipLoc = self:GetItemEquipLocation(itemLink)
    if not equipLoc then
        return nil
    end

    local mainHandLoc = self:GetItemEquipLocation(GetInventoryItemLink("player", 16))
    local offHandLoc = self:GetItemEquipLocation(GetInventoryItemLink("player", 17))
    local currentTwoHanded = mainHandLoc == "INVTYPE_2HWEAPON"
    local candidates = {}

    local function addCandidate(slotId, excludedSlots, label)
        candidates[#candidates + 1] = {
            slotId = slotId,
            excludedSlots = excludedSlots,
            label = label,
        }
    end

    if equipLoc == "INVTYPE_2HWEAPON" then
        addCandidate(16, { 16, 17 }, "Vs Main Hand + Off Hand")
        return candidates
    end

    if currentTwoHanded and (
        isGenericOneHandWeapon(equipLoc) or
        isMainHandWeapon(equipLoc) or
        isOffHandWeapon(equipLoc) or
        isOffHandSupport(equipLoc)
    ) then
        addCandidate(16, { 16, 17 }, "Vs current 2H setup")
        return candidates
    end

    if isMainHandWeapon(equipLoc) then
        addCandidate(16, { 16 }, "Vs Main Hand, keep Off Hand")
        return candidates
    end

    if isOffHandWeapon(equipLoc) then
        addCandidate(17, { 17 }, "Vs Off Hand, keep Main Hand")
        return candidates
    end

    if isOffHandSupport(equipLoc) then
        addCandidate(17, { 17 }, "Vs Off Hand")
        return candidates
    end

    if isGenericOneHandWeapon(equipLoc) then
        if isOffHandSupport(offHandLoc) then
            addCandidate(16, { 16 }, "Vs Main Hand, keep Off Hand")
            return candidates
        end

        addCandidate(16, { 16 }, "Vs Main Hand, keep Off Hand")

        if not offHandLoc or isDualWieldOffHand(offHandLoc) then
            addCandidate(17, { 17 }, "Vs Off Hand, keep Main Hand")
        end

        return candidates
    end

    return nil
end

function LS:GetCombinedEquippedScore(slotIds, comparisonContext)
    local totalScore = 0
    local labels = {}
    local links = {}

    for _, slotId in ipairs(slotIds) do
        local equippedLink = GetInventoryItemLink("player", slotId)
        local slotScore = equippedLink and (self:GetItemScore(equippedLink, comparisonContext) or 0) or 0
        totalScore = totalScore + slotScore
        links[slotId] = equippedLink
        table.insert(labels, self.slotNames[slotId] or ("Slot " .. slotId))
    end

    return totalScore, table.concat(labels, " + "), links
end

function LS:GetEquippedComparison(itemLink, itemScore)
    if not itemScore then
        return nil
    end

    local equipLoc = self:GetItemEquipLocation(itemLink)

    local weaponCandidates = self:GetWeaponComparisonCandidates(itemLink)
    if weaponCandidates and weaponCandidates[1] then
        local bestWeaponResult

        for _, candidate in ipairs(weaponCandidates) do
            local comparisonContext = { excludedSlots = candidate.excludedSlots }
            local contextualItemScore = self:GetItemScore(itemLink, comparisonContext) or itemScore
            local equippedScore = 0
            local equippedLink = nil

            if candidate.excludedSlots and candidate.excludedSlots[2] then
                local combinedScore, _, equippedLinks = self:GetCombinedEquippedScore(candidate.excludedSlots, comparisonContext)
                equippedScore = combinedScore
                equippedLink = equippedLinks[16] or equippedLinks[17]
            else
                equippedLink = GetInventoryItemLink("player", candidate.slotId)
                if equippedLink then
                    equippedScore = self:GetItemScore(equippedLink, comparisonContext) or 0
                end
            end

            local delta = contextualItemScore - equippedScore
            if not bestWeaponResult or delta > bestWeaponResult.delta then
                bestWeaponResult = {
                    slotId = candidate.slotId,
                    delta = delta,
                    equippedLink = equippedLink,
                    equippedScore = equippedScore,
                    itemScore = contextualItemScore,
                    label = candidate.label,
                }
            end
        end

        if bestWeaponResult then
            if not bestWeaponResult.equippedLink and bestWeaponResult.slotId == 17 and bestWeaponResult.label == "Vs Off Hand, keep Main Hand" then
                bestWeaponResult.label = "Vs empty Off Hand, keep Main Hand"
            elseif not bestWeaponResult.equippedLink and bestWeaponResult.slotId == 16 and bestWeaponResult.label == "Vs Main Hand, keep Off Hand" then
                bestWeaponResult.label = "Vs empty Main Hand, keep Off Hand"
            end
            return bestWeaponResult
        end
    end

    local candidateSlots = self:GetComparisonTarget(itemLink)
    if not candidateSlots then
        return nil
    end

    local bestResult

    for _, slotId in ipairs(candidateSlots) do
        local comparisonContext = { excludedSlots = { slotId } }
        local equippedLink = GetInventoryItemLink("player", slotId)
        local equippedScore = 0
        local contextualItemScore = self:GetItemScore(itemLink, comparisonContext) or itemScore
        local delta = contextualItemScore

        if equippedLink then
            equippedScore = self:GetItemScore(equippedLink, comparisonContext) or 0
            delta = contextualItemScore - equippedScore
        end

        if not bestResult or delta > bestResult.delta then
            bestResult = {
                slotId = slotId,
                delta = delta,
                equippedLink = equippedLink,
                equippedScore = equippedScore,
                itemScore = contextualItemScore,
            }
        end
    end

    if not bestResult then
        return nil
    end

    local slotName = self.slotNames[bestResult.slotId] or "Equipped"
    bestResult.label = bestResult.equippedLink and ("Vs " .. slotName) or ("Vs " .. slotName .. " (empty)")

    return bestResult
end

function LS:ToggleMainFrame()
    if not self.CreateMainFrame then
        return
    end

    if not self.mainFrame then
        self:CreateMainFrame()
    end

    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        if self.db and self.db.setup and not self.db.setup.completed then
            self:StartSetupWizard()
        else
            self.mainFrame:Show()
            self:RefreshUI()
        end
    end
end

function LS:ResetSettings()
    _G.LootSuggestion = {}
    self:InitializeDatabase()
    self.wizardAnswers = nil
    self.wizardStep = nil

    if self.RefreshUI then
        self:RefreshUI()
    end

    self:Print("Settings reset to defaults.")

    if self.CreateMainFrame then
        self:StartSetupWizard()
    end
end

function LS:SetDebugMode(enabled)
    self.db.showDebugDetails = enabled and true or false

    if self.RefreshUI then
        self:RefreshUI()
    end

    self:Print("Tuning debug info " .. (self.db.showDebugDetails and "enabled." or "disabled."))
end

function LS:PrintModelDebug(profileId, answers)
    local activeProfileId = profileId or select(1, self:GetActiveProfile())
    local lines = self.GetModelDebugLines and self:GetModelDebugLines(activeProfileId, answers) or nil

    if not lines or #lines == 0 then
        self:Print("No model summary available.")
        return
    end

    for _, line in ipairs(lines) do
        self:Print(line)
    end
end

function LS:PrintTalentApiProbe()
    local getNumTalentTabs = rawget(_G, "GetNumTalentTabs")
    local getNumTalents = rawget(_G, "GetNumTalents")
    local getTalentTabInfo = rawget(_G, "GetTalentTabInfo")
    local getTalentInfo = rawget(_G, "GetTalentInfo")
    local getActiveTalentGroup = rawget(_G, "GetActiveTalentGroup")

    self:Print("Talent API probe:")
    self:Print("GetNumTalentTabs=" .. tostring(getNumTalentTabs))
    self:Print("GetNumTalents=" .. tostring(getNumTalents))
    self:Print("GetTalentTabInfo=" .. tostring(getTalentTabInfo))
    self:Print("GetTalentInfo=" .. tostring(getTalentInfo))

    if not getNumTalentTabs or not getNumTalents or not getTalentInfo then
        self:Print("Blizzard talent functions are not available in this client context.")
        return
    end

    local tabCount = getNumTalentTabs() or 0
    self:Print("Talent tabs: " .. tostring(tabCount))

    if getActiveTalentGroup then
        self:Print("Active talent group: " .. tostring(getActiveTalentGroup()))
    end

    if tabCount <= 0 then
        self:Print("No Blizzard talent tabs reported. Ascension talents are likely not exposed through the normal WotLK talent API.")
        return
    end

    for tabIndex = 1, tabCount do
        local tabName = getTalentTabInfo and getTalentTabInfo(tabIndex) or ("Tab " .. tabIndex)
        local talentCount = getNumTalents(tabIndex) or 0
        self:Print(string.format("Tab %d: %s (%d talents)", tabIndex, tostring(tabName), talentCount))

        for talentIndex = 1, talentCount do
            local name, _, _, _, rank, maxRank = getTalentInfo(tabIndex, talentIndex, false, false, getActiveTalentGroup and getActiveTalentGroup() or nil)
            if rank and rank > 0 then
                self:Print(string.format("  %s %d/%d", tostring(name), rank, maxRank or 0))
            end
        end
    end
end

function LS:PrintCharacterAdvancementMatches(searchText)
    local query = string.lower(string.gsub(searchText or "", "^%s*(.-)%s*$", "%1"))
    if query == "" then
        self:Print("Use /ls cafind <text>")
        return
    end

    local visited = {}
    local reported = {}
    local matches = {}

    local function scanSource(source, sourceLabel, depth)
        if type(source) ~= "table" or visited[source] or (depth or 0) > 5 then
            return
        end

        visited[source] = true

        local spellId = self.GetCharacterAdvancementEntrySpellId and self:GetCharacterAdvancementEntrySpellId(source) or nil
        local name = self.GetCharacterAdvancementEntryName and self:GetCharacterAdvancementEntryName(source, spellId) or nil
        local nameText = string.lower(tostring(name or ""))
        local key = tostring(spellId or "-") .. "|" .. tostring(name or "?") .. "|" .. tostring(sourceLabel or "?")

        if nameText ~= "" and string.find(nameText, query, 1, true) and not reported[key] then
            reported[key] = true
            table.insert(matches, {
                source = sourceLabel or "?",
                name = tostring(name or "?"),
                spellId = tostring(spellId or "-"),
                known = tostring(self.IsCharacterAdvancementEntryKnown and self:IsCharacterAdvancementEntryKnown(source) or false),
                rank = tostring(source.rank or source.currentRank or source.selectedRank or source.points or source.pointsSpent or "-"),
            })
        end

        for childKey, childValue in pairs(source) do
            if type(childValue) == "table" then
                scanSource(childValue, tostring(sourceLabel or "root") .. "." .. tostring(childKey), (depth or 0) + 1)
            end
        end
    end

    local sidebarScroll = rawget(_G, "CharacterAdvancementSideBarSpellListScrollFrame")
    if sidebarScroll and type(sidebarScroll.buttons) == "table" then
        scanSource(sidebarScroll.buttons, "sidebar.buttons", 0)
    end

    local ca = rawget(_G, "CharacterAdvancement")
    if ca then
        local sources = {
            { label = "CharacterAdvancement.classTraits", value = ca.classTraits },
            { label = "CharacterAdvancement.classMasteries", value = ca.classMasteries },
            { label = "CharacterAdvancement.TalentPool", value = ca.TalentPool },
            { label = "CharacterAdvancement.SpellPool", value = ca.SpellPool },
        }

        for _, source in ipairs(sources) do
            if type(source.value) == "table" then
                scanSource(source.value, source.label, 0)
            end
        end
    end

    if #matches == 0 then
        self:Print("No Character Advancement matches found for '" .. query .. "'.")
        return
    end

    table.sort(matches, function(left, right)
        if left.name == right.name then
            return left.source < right.source
        end
        return left.name < right.name
    end)

    self:Print("Character Advancement matches for '" .. query .. "':")
    for index, match in ipairs(matches) do
        self:Print(string.format("%d. %s spell=%s known=%s rank=%s source=%s", index, match.name, match.spellId, match.known, match.rank, match.source))
        if index >= 12 then
            break
        end
    end
end

function LS:PrintCharacterAdvancementProbe()
    local ca = rawget(_G, "CharacterAdvancement")
    local sidebarScroll = rawget(_G, "CharacterAdvancementSideBarSpellListScrollFrame")
    local cachedSpellIDs = self.db and self.db.caKnownSpellIDs or nil
    local cachedPassiveNames = self.db and self.db.caKnownPassiveNames or nil
    local activeProfileId = self:GetActiveProfile()
    local passiveRules = self.GetRelevantPassiveRules and self:GetRelevantPassiveRules(activeProfileId) or nil

    self:Print("Character Advancement probe:")
    self:Print("CharacterAdvancement=" .. tostring(ca))
    self:Print("Cached CA spellIDs=" .. tostring(countTableEntries(cachedSpellIDs)))
    self:Print("Cached CA passive names=" .. tostring(countTableEntries(cachedPassiveNames)))

    if not ca then
        self:Print("Character Advancement frame is not available.")
    else
        self:Print("initialized=" .. tostring(ca.initialized))
        self:Print("shown=" .. tostring(ca.IsShown and ca:IsShown() or false))
        self:Print("mode=" .. tostring(ca.mode))
        self:Print("classTraits entries=" .. tostring(countTableEntries(ca.classTraits)))
        self:Print("classMasteries entries=" .. tostring(countTableEntries(ca.classMasteries)))
        self:Print("TalentPool=" .. tostring(ca.TalentPool))
        self:Print("SpellPool=" .. tostring(ca.SpellPool))
        self:Print("SideBar=" .. tostring(ca.SideBar))

        if sidebarScroll then
            self:Print("SideBarSpellListScrollFrame=" .. tostring(sidebarScroll))
            local buttons = sidebarScroll.buttons
            self:Print("Sidebar button entries=" .. tostring(countTableEntries(buttons)))

            local reported = 0
            for _, button in pairs(buttons or {}) do
                if type(button) == "table" and button.spellID then
                    local spellName = GetSpellInfo and GetSpellInfo(button.spellID) or nil
                    local knownText = tostring(button.known)
                    local rankText = tostring(button.rank)
                    local specText = tostring(button.spec)
                    self:Print(string.format("Sidebar: %s spell=%s known=%s rank=%s spec=%s", tostring(spellName or "?"), tostring(button.spellID), knownText, rankText, specText))
                    reported = reported + 1
                    if reported >= 12 then
                        break
                    end
                end
            end

            if reported == 0 then
                self:Print("No sidebar buttons with spellID were found in the current scroll frame snapshot.")
            end
        else
            self:Print("Sidebar scroll frame not found.")
        end
    end

    if passiveRules and #passiveRules > 0 then
        self:Print("Tracked passive detection:")
        for _, rule in ipairs(passiveRules) do
            local spellId = tonumber(rule.spellId)
            local caKnown = spellId and self.IsCharacterAdvancementSpellKnown and self:IsCharacterAdvancementSpellKnown(spellId) or false
            local caRuleKnown = self.IsCharacterAdvancementRuleKnown and self:IsCharacterAdvancementRuleKnown(rule) or false
            local spellbookKnown = false
            local isSpellKnown = rawget(_G, "IsSpellKnown")
            if spellId and isSpellKnown then
                local ok, result = pcall(isSpellKnown, spellId)
                spellbookKnown = ok and result and true or false
            end
            local active = self.IsPassiveModifierActive and self:IsPassiveModifierActive(rule, self:GetBuildContext(activeProfileId)) or false
            self:Print(string.format("Passive: %s spell=%s override=%s caSpell=%s caRule=%s spellbook=%s active=%s", tostring(rule.key), tostring(spellId or "-"), tostring(self:GetPassiveOverrideMode(rule.key)), tostring(caKnown), tostring(caRuleKnown), tostring(spellbookKnown), tostring(active)))
        end
    end
end

function LS:HandleSlashCommand(message)
    local normalized = string.lower(string.gsub(message or "", "^%s*(.-)%s*$", "%1"))

    if normalized == "" then
        self:ToggleMainFrame()
        return
    end

    if normalized == "reset" then
        self:ResetSettings()
        return
    end

    if normalized == "setup" or normalized == "wizard" then
        self:StartSetupWizard()
        return
    end

    if normalized == "edit" or normalized == "editor" then
        if self.OpenWeightEditor then
            self:OpenWeightEditor()
        end
        return
    end

    if normalized == "capedit" or normalized == "capeditor" then
        if self.OpenCapEditor then
            self:OpenCapEditor()
        end
        return
    end

    if normalized == "list" then
        for _, profileId in ipairs(self.profileOrder or {}) do
            self:Print(profileId .. " - " .. self.profiles[profileId].name)
        end
        return
    end

    local profileId = string.match(normalized, "^profile%s+([%w_]+)$")
    if profileId then
        if self.profiles and self.profiles[profileId] then
            self:SetSelectedProfile(profileId)
        else
            self:Print("Unknown profile. Use /ls list to see valid profile ids.")
        end
        return
    end

    if normalized == "stats" then
        local orderedStats = {}
        for statKey, label in pairs(self.statLabels or {}) do
            table.insert(orderedStats, statKey .. " (" .. label .. ")")
        end
        table.sort(orderedStats)
        self:Print("Stats: " .. table.concat(orderedStats, ", "))
        return
    end

    if normalized == "weights" then
        local activeProfileId, activeProfile = self:GetActiveProfile()
        local text = self:GetWeightListText(activeProfileId)
        if text and activeProfile then
            self:Print(activeProfile.name .. " weights: " .. text)
            self:Print("* means custom override")
        end
        return
    end

    if normalized == "caps" then
        local activeProfileId, activeProfile = self:GetActiveProfile()
        local text = self:GetCapListText(activeProfileId)
        if text and activeProfile then
            self:Print(activeProfile.name .. " caps: " .. text)
            self:Print("* means custom override")
        else
            self:Print("No active cap rules for this profile.")
        end
        return
    end

    if normalized == "model" or normalized == "report" then
        self:PrintModelDebug()
        return
    end

    if normalized == "talentprobe" or normalized == "talents" then
        self:PrintTalentApiProbe()
        return
    end

    if normalized == "ca" or normalized == "cadump" or normalized == "caprobe" then
        self:PrintCharacterAdvancementProbe()
        return
    end

    local caFindText = string.match(message or "", "^%s*[Cc][Aa][Ff][Ii][Nn][Dd]%s+(.+)$")
    if caFindText then
        self:PrintCharacterAdvancementMatches(caFindText)
        return
    end

    if normalized == "passives" then
        local activeProfileId = self:GetActiveProfile()
        local rules = self.GetRelevantPassiveRules and self:GetRelevantPassiveRules(activeProfileId) or {}
        if #rules == 0 then
            self:Print("No tracked passives for the active profile.")
            return
        end

        for _, rule in ipairs(rules) do
            self:Print(string.format("%s - %s (%s)", rule.key, rule.label or rule.key, self:GetPassiveOverrideMode(rule.key)))
        end
        self:Print("Use /ls passive <key> on, /ls passive <key> off, or /ls passive <key> auto")
        return
    end

    local passiveKey, passiveMode = string.match(normalized, "^passive%s+([%w_]+)%s+(%a+)$")
    if passiveKey and passiveMode then
        local desiredState = nil
        if passiveMode == "on" then
            desiredState = true
        elseif passiveMode == "off" then
            desiredState = false
        elseif passiveMode ~= "auto" then
            self:Print("Use /ls passive <key> on, /ls passive <key> off, or /ls passive <key> auto")
            return
        end

        local success, errorMessage = self:SetManualPassiveOverride(passiveKey, desiredState)
        if not success then
            self:Print(errorMessage)
            return
        end

        if self.RefreshUI then
            self:RefreshUI()
        end

        self:Print(string.format("Passive override set: %s = %s", passiveKey, passiveMode))
        return
    end

    if normalized == "debug" then
        self:SetDebugMode(not self.db.showDebugDetails)
        return
    end

    local debugValue = string.match(normalized, "^debug%s+(%a+)$")
    if debugValue then
        if debugValue == "on" then
            self:SetDebugMode(true)
        elseif debugValue == "off" then
            self:SetDebugMode(false)
        else
            self:Print("Use /ls debug, /ls debug on, or /ls debug off.")
        end
        return
    end

    local statKey, valueText = string.match(normalized, "^weight%s+([%w_]+)%s+([%-%d%.]+)$")
    if statKey and valueText then
        local activeProfileId = self:GetActiveProfile()
        local value = tonumber(valueText)
        local success, errorMessage = self:SetCustomWeight(activeProfileId, statKey, value)
        if success then
            if self.RefreshUI then
                self:RefreshUI()
            end
            self:Print(string.format("Custom weight set: %s = %.2f", statKey, value))
        else
            self:Print(errorMessage)
        end
        return
    end

    local clearStatKey = string.match(normalized, "^clearweight%s+([%w_]+)$")
    if clearStatKey then
        local activeProfileId = self:GetActiveProfile()
        if not self.statLookup or not self.statLookup[clearStatKey] then
            self:Print("Unknown stat. Use /ls stats to see valid keys.")
            return
        end
        self:ClearCustomWeight(activeProfileId, clearStatKey)
        if self.RefreshUI then
            self:RefreshUI()
        end
        self:Print("Removed custom weight for " .. clearStatKey)
        return
    end

    if normalized == "clearweights" then
        local activeProfileId = self:GetActiveProfile()
        self:ClearCustomWeights(activeProfileId)
        if self.RefreshUI then
            self:RefreshUI()
        end
        self:Print("Cleared custom weights for active profile.")
        return
    end

    local capStatKey, capText, postCapText = string.match(normalized, "^cap%s+([%w_]+)%s+([%-%d%.]+)%s*([%-%d%.]*)$")
    if capStatKey and capText then
        local activeProfileId = self:GetActiveProfile()
        local capValue = tonumber(capText)
        local postCapWeight = postCapText ~= "" and tonumber(postCapText) or nil
        local success, errorMessage = self:SetCustomCapRule(activeProfileId, capStatKey, capValue, postCapWeight)
        if success then
            if self.RefreshUI then
                self:RefreshUI()
            end
            if postCapWeight ~= nil then
                self:Print(string.format("Custom cap set: %s cap %.0f post-cap %.2f", capStatKey, capValue, postCapWeight))
            else
                self:Print(string.format("Custom cap set: %s cap %.0f", capStatKey, capValue))
            end
        else
            self:Print(errorMessage)
        end
        return
    end

    local clearCapStatKey = string.match(normalized, "^clearcap%s+([%w_]+)$")
    if clearCapStatKey then
        local activeProfileId = self:GetActiveProfile()
        if not self.statLookup or not self.statLookup[clearCapStatKey] then
            self:Print("Unknown stat. Use /ls stats to see valid keys.")
            return
        end
        self:ClearCustomCapRule(activeProfileId, clearCapStatKey)
        if self.RefreshUI then
            self:RefreshUI()
        end
        self:Print("Removed custom cap for " .. clearCapStatKey)
        return
    end

    if normalized == "clearcaps" then
        local activeProfileId = self:GetActiveProfile()
        self:ClearCustomCapRules(activeProfileId)
        if self.RefreshUI then
            self:RefreshUI()
        end
        self:Print("Cleared custom caps for active profile.")
        return
    end

    self:Print("Commands: /ls, /ls setup, /ls edit, /ls capedit, /ls list, /ls profile <id>, /ls stats, /ls weights, /ls caps, /ls passives, /ls passive <key> on|off|auto, /ls model, /ls report, /ls talents, /ls ca, /ls cafind <text>, /ls debug [on|off], /ls weight <stat> <value>, /ls clearweight <stat>, /ls clearweights, /ls cap <stat> <cap> [postcap], /ls clearcap <stat>, /ls clearcaps, /ls reset")
end

SLASH_LOOTSUGGESTION1 = "/ls"
SLASH_LOOTSUGGESTION2 = "/lootsuggestion"
SlashCmdList.LOOTSUGGESTION = function(message)
    LS:HandleSlashCommand(message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:SetScript("OnEvent", function(_, eventName)

    if eventName == "PLAYER_LOGIN" then
        LS:InitializeDatabase()
        if LS.InvalidateTooltipCaches then
            LS:InvalidateTooltipCaches()
        end
        LS:TryInstallCharacterAdvancementHooks()
        LS:StartCharacterAdvancementMonitor()

        if LS.CreateMainFrame then
            LS:CreateMainFrame()
        end

        if LS.RefreshUI then
            LS:RefreshUI()
        end

        if not LS.db.setup.completed then
            LS:Print("Loaded. First-time setup opened automatically.")
            LS:StartSetupWizard()
        else
            LS:Print("Loaded. Type /ls to review or change your profile.")
        end
        return
    end

    if eventName == "PLAYER_EQUIPMENT_CHANGED" then
        if LS.InvalidateTooltipCaches then
            LS:InvalidateTooltipCaches()
        end
        if LS.RefreshUI and LS.mainFrame and LS.mainFrame:IsShown() then
            LS:RefreshUI()
        end
    end
end)