local LS = _G.LootSuggestionAddon

local THEME = {
    panel = { 0.06, 0.05, 0.04, 0.94 },
    inset = { 0.10, 0.08, 0.06, 0.96 },
    header = { 0.15, 0.11, 0.07, 0.98 },
    accent = { 0.92, 0.67, 0.18, 1.00 },
    accentMuted = { 0.45, 0.32, 0.10, 1.00 },
    button = { 0.18, 0.10, 0.08, 0.96 },
    buttonHover = { 0.26, 0.15, 0.10, 0.98 },
    buttonSelected = { 0.40, 0.18, 0.10, 0.98 },
    border = { 0.58, 0.42, 0.18, 1.00 },
    dimText = { 0.76, 0.71, 0.60, 1.00 },
    brightText = { 0.98, 0.92, 0.78, 1.00 },
}

local function applyBackdrop(frame, backgroundColor, borderColor, insets)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = insets or { left = 4, right = 4, top = 4, bottom = 4 },
    })

    if backgroundColor then
        frame:SetBackdropColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    end

    if borderColor then
        frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    end
end

local function createPanel(parent, anchor, relativeTo, relativePoint, xOffset, yOffset, width, height, backgroundColor)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint(anchor, relativeTo, relativePoint, xOffset, yOffset)
    if width then
        panel:SetWidth(width)
    end
    if height then
        panel:SetHeight(height)
    end
    applyBackdrop(panel, backgroundColor or THEME.inset, THEME.border)
    return panel
end

local function createSectionTitle(parent, text, anchor, relativeTo, relativePoint, xOffset, yOffset)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint(anchor, relativeTo, relativePoint, xOffset, yOffset)
    title:SetText(text)
    title:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])
    return title
end

local function createBodyText(parent, width, fontObject)
    local text = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWidth(width)
    text:SetTextColor(THEME.dimText[1], THEME.dimText[2], THEME.dimText[3])
    return text
end

local function createAccentLine(parent, anchor, relativeTo, relativePoint, xOffset, yOffset, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 0.85)
    line:SetPoint(anchor, relativeTo, relativePoint, xOffset, yOffset)
    line:SetWidth(width)
    line:SetHeight(2)
    return line
end

local function setCustomButtonState(button, selected)
    local color = THEME.button
    if selected then
        color = THEME.buttonSelected
    elseif button.isHovering then
        color = THEME.buttonHover
    end

    button:SetBackdropColor(color[1], color[2], color[3], color[4])
    if button.accent then
        if selected then
            button.accent:SetVertexColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1.0)
        else
            button.accent:SetVertexColor(THEME.accentMuted[1], THEME.accentMuted[2], THEME.accentMuted[3], 0.85)
        end
    end

    if button.text then
        if selected then
            button.text:SetTextColor(1.00, 0.95, 0.80)
        else
            button.text:SetTextColor(0.92, 0.88, 0.77)
        end
    end

    if button.detail then
        if selected then
            button.detail:SetTextColor(0.96, 0.84, 0.55)
        else
            button.detail:SetTextColor(0.74, 0.69, 0.58)
        end
    end
end

local function createCustomButton(parent, width, height, title, detail)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    applyBackdrop(button, THEME.button, THEME.border)

    button.accent = button:CreateTexture(nil, "ARTWORK")
    button.accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.accent:SetPoint("TOPLEFT", 6, -6)
    button.accent:SetPoint("BOTTOMLEFT", 6, 6)
    button.accent:SetWidth(4)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("TOPLEFT", 18, -7)
    button.text:SetPoint("TOPRIGHT", -10, -7)
    button.text:SetJustifyH("LEFT")
    button.text:SetText(title)

    if detail then
        button.detail = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.detail:SetPoint("TOPLEFT", button.text, "BOTTOMLEFT", 0, -2)
        button.detail:SetPoint("TOPRIGHT", -10, 0)
        button.detail:SetJustifyH("LEFT")
        button.detail:SetText(detail)
    end

    button:SetScript("OnEnter", function(current)
        current.isHovering = true
        setCustomButtonState(current, current.isSelected)
    end)
    button:SetScript("OnLeave", function(current)
        current.isHovering = false
        setCustomButtonState(current, current.isSelected)
    end)

    setCustomButtonState(button, false)
    return button
end

local function createProfileButton(parent, profile)
    local button = createCustomButton(parent, 232, 24, profile.name, nil)
    button.profileId = nil
    return button
end

local function createActionButton(parent, width, height, title, detail)
    return createCustomButton(parent, width, height, title, detail)
end

local function createPriorityOptionButton(parent, width, height)
    local button = createCustomButton(parent, width, height, "", "")
    if button.detail then
        button.detail:SetWidth(width - 28)
    end
    return button
end

local function createWeightEditorRow(parent, previousRow)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(720)
    row:SetHeight(28)

    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -8)
    end

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", 0, 0)
    row.label:SetWidth(170)
    row.label:SetJustifyH("LEFT")

    row.current = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.current:SetPoint("LEFT", 175, 0)
    row.current:SetWidth(165)
    row.current:SetJustifyH("LEFT")

    row.input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.input:SetAutoFocus(false)
    row.input:SetWidth(72)
    row.input:SetHeight(24)
    row.input:SetPoint("LEFT", 348, 0)
    row.input:SetTextInsets(6, 6, 0, 0)

    row.applyButton = createCustomButton(row, 58, 22, "Apply")
    row.applyButton:SetPoint("LEFT", row.input, "RIGHT", 10, 0)
    row.applyButton.text:ClearAllPoints()
    row.applyButton.text:SetPoint("CENTER", 0, 0)

    row.resetButton = createCustomButton(row, 58, 22, "Reset")
    row.resetButton:SetPoint("LEFT", row.applyButton, "RIGHT", 8, 0)
    row.resetButton.text:ClearAllPoints()
    row.resetButton.text:SetPoint("CENTER", 0, 0)

    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.note:SetPoint("LEFT", row.resetButton, "RIGHT", 10, 0)
    row.note:SetWidth(130)
    row.note:SetJustifyH("LEFT")
    row.note:SetTextColor(THEME.dimText[1], THEME.dimText[2], THEME.dimText[3])

    return row
end

local function createCapEditorRow(parent, previousRow)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(720)
    row:SetHeight(28)

    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -8)
    end

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", 0, 0)
    row.label:SetWidth(150)
    row.label:SetJustifyH("LEFT")

    row.current = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.current:SetPoint("LEFT", 155, 0)
    row.current:SetWidth(180)
    row.current:SetJustifyH("LEFT")

    row.capInput = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.capInput:SetAutoFocus(false)
    row.capInput:SetWidth(58)
    row.capInput:SetHeight(24)
    row.capInput:SetPoint("LEFT", 345, 0)
    row.capInput:SetTextInsets(6, 6, 0, 0)

    row.postInput = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.postInput:SetAutoFocus(false)
    row.postInput:SetWidth(58)
    row.postInput:SetHeight(24)
    row.postInput:SetPoint("LEFT", row.capInput, "RIGHT", 10, 0)
    row.postInput:SetTextInsets(6, 6, 0, 0)

    row.applyButton = createCustomButton(row, 52, 22, "Apply")
    row.applyButton:SetPoint("LEFT", row.postInput, "RIGHT", 10, 0)
    row.applyButton.text:ClearAllPoints()
    row.applyButton.text:SetPoint("CENTER", 0, 0)

    row.resetButton = createCustomButton(row, 52, 22, "Reset")
    row.resetButton:SetPoint("LEFT", row.applyButton, "RIGHT", 8, 0)
    row.resetButton.text:ClearAllPoints()
    row.resetButton.text:SetPoint("CENTER", 0, 0)

    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.note:SetPoint("LEFT", row.resetButton, "RIGHT", 10, 0)
    row.note:SetWidth(110)
    row.note:SetJustifyH("LEFT")
    row.note:SetTextColor(THEME.dimText[1], THEME.dimText[2], THEME.dimText[3])

    return row
end

local function createModalFrame(parent, titleText, descriptionText, width, height)
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:Hide()

    overlay.dimmer = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.dimmer:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.dimmer:SetAllPoints(overlay)
    overlay.dimmer:SetVertexColor(0.00, 0.00, 0.00, 0.55)

    local modal = CreateFrame("Frame", nil, overlay)
    modal:SetWidth(width)
    modal:SetHeight(height)
    modal:SetPoint("CENTER", 0, 0)
    applyBackdrop(modal, THEME.panel, THEME.border)
    overlay.modal = modal

    modal.header = CreateFrame("Frame", nil, modal)
    modal.header:SetPoint("TOPLEFT", 12, -12)
    modal.header:SetPoint("TOPRIGHT", -12, -12)
    modal.header:SetHeight(42)
    applyBackdrop(modal.header, THEME.header, THEME.border)

    modal.title = modal.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    modal.title:SetPoint("TOPLEFT", 14, -10)
    modal.title:SetText(titleText)
    modal.title:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])

    modal.description = createBodyText(modal, width - 48)
    modal.description:SetPoint("TOPLEFT", modal.header, "BOTTOMLEFT", 2, -16)
    modal.description:SetText(descriptionText)

    return overlay, modal
end

function LS:CreateMainFrame()
    if self.mainFrame then
        return
    end

    local frame = CreateFrame("Frame", "LootSuggestionMainFrame", UIParent)
    frame:SetWidth(930)
    frame:SetHeight(760)
    frame:SetPoint(
        self.db.framePosition.point,
        UIParent,
        self.db.framePosition.relativePoint,
        self.db.framePosition.x,
        self.db.framePosition.y
    )
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(current)
        current:StopMovingOrSizing()
        local point, _, relativePoint, x, y = current:GetPoint(1)
        LS.db.framePosition.point = point
        LS.db.framePosition.relativePoint = relativePoint
        LS.db.framePosition.x = x
        LS.db.framePosition.y = y
    end)
    applyBackdrop(frame, THEME.panel, THEME.border)
    frame:Hide()

    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 12, -12)
    frame.header:SetPoint("TOPRIGHT", -12, -12)
    frame.header:SetHeight(52)
    applyBackdrop(frame.header, THEME.header, THEME.border)

    local title = frame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -10)
    title:SetText("LootSuggestion")
    title:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])

    local subtitle = frame.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Pick a profile, tune weights and caps, then hover items to compare upgrades.")
    subtitle:SetTextColor(THEME.dimText[1], THEME.dimText[2], THEME.dimText[3])

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -8, -8)

    frame.leftPanel = createPanel(frame, "TOPLEFT", frame.header, "BOTTOMLEFT", 0, -12, 260, 672, THEME.inset)
    frame.rightPanel = createPanel(frame, "TOPLEFT", frame.leftPanel, "TOPRIGHT", 14, 0, 632, 672, THEME.inset)

    local leftTitle = createSectionTitle(frame.leftPanel, "Preset Profiles", "TOPLEFT", frame.leftPanel, "TOPLEFT", 14, -14)
    local leftText = createBodyText(frame.leftPanel, 228, "GameFontHighlightSmall")
    leftText:SetPoint("TOPLEFT", leftTitle, "BOTTOMLEFT", 0, -6)
    leftText:SetText("Choose the profile that best matches how the character plays. The right side explains what each preset values most.")

    frame.profileButtons = {}
    local previousButton = leftText
    for _, profileId in ipairs(self.profileOrder) do
        local profile = self.profiles[profileId]
        local button = createProfileButton(frame.leftPanel, profile)
        button.profileId = profileId
        if previousButton == leftText then
            button:SetPoint("TOPLEFT", leftText, "BOTTOMLEFT", 0, -14)
        else
            button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -4)
        end
        button.text:SetText(profile.name)
        button:SetScript("OnClick", function()
            LS:SetSelectedProfile(profileId)
        end)
        frame.profileButtons[profileId] = button
        previousButton = button
    end

    frame.utilityPanel = createPanel(frame.leftPanel, "BOTTOMLEFT", frame.leftPanel, "BOTTOMLEFT", 12, 12, 236, 190, THEME.panel)

    frame.recommendationText = createBodyText(frame.utilityPanel, 212, "GameFontHighlightSmall")
    frame.recommendationText:SetPoint("TOPLEFT", frame.utilityPanel, "TOPLEFT", 12, -12)
    frame.recommendationText:SetText("")

    frame.utilityDivider = createAccentLine(frame.utilityPanel, "TOPLEFT", frame.utilityPanel, "TOPLEFT", 12, -40, 212)

    frame.setupButton = createActionButton(frame.utilityPanel, 212, 28, "Run Setup Wizard")
    frame.setupButton:SetPoint("TOPLEFT", frame.utilityPanel, "TOPLEFT", 12, -52)
    frame.setupButton:SetScript("OnClick", function()
        LS:StartSetupWizard()
    end)

    frame.editWeightsButton = createActionButton(frame.utilityPanel, 212, 28, "Edit Active Weights")
    frame.editWeightsButton:SetPoint("TOPLEFT", frame.setupButton, "BOTTOMLEFT", 0, -5)
    frame.editWeightsButton:SetScript("OnClick", function()
        LS:OpenWeightEditor()
    end)

    frame.editCapsButton = createActionButton(frame.utilityPanel, 212, 28, "Edit Active Caps")
    frame.editCapsButton:SetPoint("TOPLEFT", frame.editWeightsButton, "BOTTOMLEFT", 0, -5)
    frame.editCapsButton:SetScript("OnClick", function()
        LS:OpenCapEditor()
    end)

    frame.priorityWizardButton = createActionButton(frame.utilityPanel, 212, 28, "Priority Wizard")
    frame.priorityWizardButton:SetPoint("TOPLEFT", frame.editCapsButton, "BOTTOMLEFT", 0, -5)
    frame.priorityWizardButton:SetScript("OnClick", function()
        LS:OpenPriorityWizard()
    end)

    frame.profileCard = createPanel(frame.rightPanel, "TOPLEFT", frame.rightPanel, "TOPLEFT", 12, -12, 608, 92, THEME.panel)
    frame.profileName = frame.profileCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.profileName:SetPoint("TOPLEFT", 14, -12)
    frame.profileName:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])

    frame.profileSummary = createBodyText(frame.profileCard, 580)
    frame.profileSummary:SetPoint("TOPLEFT", frame.profileName, "BOTTOMLEFT", 0, -8)

    frame.metricsCard = createPanel(frame.rightPanel, "TOPLEFT", frame.profileCard, "BOTTOMLEFT", 0, -12, 608, 72, THEME.panel)
    frame.metricsTitle = createSectionTitle(frame.metricsCard, "Priority Snapshot", "TOPLEFT", frame.metricsCard, "TOPLEFT", 14, -12)
    frame.profilePriority = createBodyText(frame.metricsCard, 580)
    frame.profilePriority:SetPoint("TOPLEFT", frame.metricsTitle, "BOTTOMLEFT", 0, -8)

    frame.playstyleCard = createPanel(frame.rightPanel, "TOPLEFT", frame.metricsCard, "BOTTOMLEFT", 0, -12, 608, 88, THEME.panel)
    frame.playstyleTitle = createSectionTitle(frame.playstyleCard, "Playstyle", "TOPLEFT", frame.playstyleCard, "TOPLEFT", 14, -12)
    frame.profilePlaystyle = createBodyText(frame.playstyleCard, 580)
    frame.profilePlaystyle:SetPoint("TOPLEFT", frame.playstyleTitle, "BOTTOMLEFT", 0, -8)

    frame.optionsCard = createPanel(frame.rightPanel, "TOPLEFT", frame.playstyleCard, "BOTTOMLEFT", 0, -12, 608, 190, THEME.panel)
    frame.optionsTitle = createSectionTitle(frame.optionsCard, "Scoring Options", "TOPLEFT", frame.optionsCard, "TOPLEFT", 14, -12)
    frame.optionsHint = createBodyText(frame.optionsCard, 580, "GameFontHighlightSmall")
    frame.optionsHint:SetPoint("TOPLEFT", frame.optionsTitle, "BOTTOMLEFT", 0, -6)
    frame.optionsHint:SetText("These affect what appears in tooltips and how comparison details are shown while you play.")

    local showScores = CreateFrame("CheckButton", "LootSuggestionShowScoresCheck", frame.optionsCard, "OptionsCheckButtonTemplate")
    showScores:SetPoint("TOPLEFT", frame.optionsHint, "BOTTOMLEFT", -2, -12)
    _G[showScores:GetName() .. "Text"]:SetText("Show tooltip score")
    showScores:SetScript("OnClick", function(button)
        LS.db.showTooltipScores = button:GetChecked() and true or false
    end)
    frame.showScoresCheck = showScores

    local compareItems = CreateFrame("CheckButton", "LootSuggestionCompareItemsCheck", frame.optionsCard, "OptionsCheckButtonTemplate")
    compareItems:SetPoint("TOPLEFT", showScores, "BOTTOMLEFT", 0, -8)
    _G[compareItems:GetName() .. "Text"]:SetText("Compare against equipped gear")
    compareItems:SetScript("OnClick", function(button)
        LS.db.compareEquipped = button:GetChecked() and true or false
    end)
    frame.compareItemsCheck = compareItems

    local showBreakdown = CreateFrame("CheckButton", "LootSuggestionShowBreakdownCheck", frame.optionsCard, "OptionsCheckButtonTemplate")
    showBreakdown:SetPoint("TOPLEFT", compareItems, "BOTTOMLEFT", 0, -8)
    _G[showBreakdown:GetName() .. "Text"]:SetText("Show top stat breakdown")
    showBreakdown:SetScript("OnClick", function(button)
        LS.db.showBreakdown = button:GetChecked() and true or false
    end)
    frame.showBreakdownCheck = showBreakdown

    local showDebug = CreateFrame("CheckButton", "LootSuggestionShowDebugCheck", frame.optionsCard, "OptionsCheckButtonTemplate")
    showDebug:SetPoint("TOPLEFT", showBreakdown, "BOTTOMLEFT", 0, -8)
    _G[showDebug:GetName() .. "Text"]:SetText("Show tuning debug info")
    showDebug:SetScript("OnClick", function(button)
        LS.db.showDebugDetails = button:GetChecked() and true or false
    end)
    frame.showDebugCheck = showDebug

    frame.resetButton = createActionButton(frame.optionsCard, 154, 28, "Reset Settings")
    frame.resetButton:SetPoint("BOTTOMRIGHT", frame.optionsCard, "BOTTOMRIGHT", -14, 12)
    frame.resetButton:SetScript("OnClick", function()
        LS:ResetSettings()
    end)

    frame.footerCard = createPanel(frame.rightPanel, "TOPLEFT", frame.optionsCard, "BOTTOMLEFT", 0, -12, 608, 45, THEME.panel)
    frame.footerText = createBodyText(frame.footerCard, 580, "GameFontHighlightSmall")
    frame.footerText:SetPoint("TOPLEFT", frame.footerCard, "TOPLEFT", 14, -13)
    frame.footerText:SetText("Slash commands: /ls, /ls setup, /ls edit, /ls capedit, /ls weights, /ls caps")

    frame.headerAccent = createAccentLine(frame.header, "BOTTOMLEFT", frame.header, "BOTTOMLEFT", 14, 6, 220)

    local setupModeOverlay, setupModeModal = createModalFrame(frame, "Setup Mode", "Choose whether you want the normal guided setup or jump straight into advanced stat ordering.", 560, 300)
    local setupMode = setupModeOverlay
    setupMode:SetFrameLevel(frame:GetFrameLevel() + 31)
    setupMode.title = setupModeModal.title
    setupMode.description = setupModeModal.description
    setupMode.simpleButton = createCustomButton(setupModeModal, 512, 56, "Simple Setup", "Uses the normal guided wizard with role, focus and build-specific questions.")
    setupMode.simpleButton:SetPoint("TOPLEFT", setupMode.description, "BOTTOMLEFT", 0, -24)
    setupMode.advancedButton = createCustomButton(setupModeModal, 512, 56, "Advanced Priority Wizard", "Jumps directly to manual stat priority ordering for the active profile.")
    setupMode.advancedButton:SetPoint("TOPLEFT", setupMode.simpleButton, "BOTTOMLEFT", 0, -12)
    setupMode.noteText = createBodyText(setupModeModal, 512, "GameFontHighlightSmall")
    setupMode.noteText:SetPoint("TOPLEFT", setupMode.advancedButton, "BOTTOMLEFT", 0, -16)
    setupMode.noteText:SetText("Advanced mode starts from the active profile and creates custom weight overrides from your chosen stat order.")
    setupMode.closeButton = createActionButton(setupModeModal, 120, 28, "Close")
    setupMode.closeButton:SetPoint("BOTTOMRIGHT", setupModeModal, "BOTTOMRIGHT", -16, 14)
    setupMode.simpleButton:SetScript("OnClick", function()
        LS:StartGuidedSetupWizard()
    end)
    setupMode.advancedButton:SetScript("OnClick", function()
        LS:StartAdvancedSetupWizard()
    end)
    setupMode.closeButton:SetScript("OnClick", function()
        LS:CloseSetupModeSelector()
    end)
    self.setupModeFrame = setupMode

    local wizardOverlay, wizardModal = createModalFrame(frame, "Setup Wizard", "Answer a few simple questions and LootSuggestion will recommend a starting profile for you.", 788, 470)
    local wizard = wizardOverlay
    wizard:SetFrameLevel(frame:GetFrameLevel() + 30)
    wizard.progress = wizardModal.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    wizard.progress:SetPoint("TOPRIGHT", -14, -14)
    wizard.progress:SetTextColor(THEME.dimText[1], THEME.dimText[2], THEME.dimText[3])

    wizard.title = wizardModal.title
    wizard.description = wizardModal.description
    wizard.optionButtons = {}
    local previousOption
    for index = 1, 4 do
        local button = createCustomButton(wizardModal, 730, 42, "", "")
        if index == 1 then
            button:SetPoint("TOPLEFT", wizard.description, "BOTTOMLEFT", 0, -18)
        else
            button:SetPoint("TOPLEFT", previousOption, "BOTTOMLEFT", 0, -10)
        end
        button.detail:SetWidth(700)
        wizard.optionButtons[index] = button
        previousOption = button
    end

    wizard.summaryPanel = createPanel(wizardModal, "TOPLEFT", previousOption, "BOTTOMLEFT", 0, -18, 730, 102, THEME.inset)
    wizard.summaryHeader = createSectionTitle(wizard.summaryPanel, "Recommended Result", "TOPLEFT", wizard.summaryPanel, "TOPLEFT", 14, -12)
    wizard.summaryText = createBodyText(wizard.summaryPanel, 700)
    wizard.summaryText:SetPoint("TOPLEFT", wizard.summaryHeader, "BOTTOMLEFT", 0, -8)

    wizard.backButton = createActionButton(wizardModal, 120, 28, "Back")
    wizard.backButton:SetPoint("BOTTOMLEFT", wizardModal, "BOTTOMLEFT", 16, 14)
    wizard.cancelButton = createActionButton(wizardModal, 140, 28, "Close Wizard")
    wizard.cancelButton:SetPoint("BOTTOMRIGHT", wizardModal, "BOTTOMRIGHT", -16, 14)
    wizard.backButton:SetScript("OnClick", function()
        if not LS.wizardStep or LS.wizardStep <= 1 then
            LS.wizardStep = 1
            return
        end

        local previousStep = LS.wizardStep
        LS.wizardStep = LS.wizardStep - 1
        if LS.wizardAnswers then
            if previousStep == 2 then
                LS.wizardAnswers.focus = nil
                LS.wizardAnswers.tankStyle = nil
                LS.wizardAnswers.scaling = nil
            elseif previousStep == 3 then
                LS.wizardAnswers.tankStyle = nil
                LS.wizardAnswers.scaling = nil
            elseif previousStep == 4 then
                LS.wizardAnswers.scaling = nil
            end
        end
        LS:RefreshUI()
    end)
    wizard.cancelButton:SetScript("OnClick", function()
        LS.wizardStep = nil
        LS:RefreshUI()
    end)
    self.wizardFrame = wizard

    local weightOverlay, weightModal = createModalFrame(frame, "Weight Editor", "Adjust the active preset without slash commands. Apply stores a custom override for this profile.", 812, 700)
    local editor = weightOverlay
    editor:SetFrameLevel(frame:GetFrameLevel() + 29)
    editor.title = weightModal.title
    editor.description = weightModal.description
    editor.profileText = weightModal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editor.profileText:SetPoint("TOPLEFT", editor.description, "BOTTOMLEFT", 0, -14)
    editor.profileText:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])
    editor.rows = {}
    for index = 1, 14 do
        local row = createWeightEditorRow(weightModal, editor.rows[index - 1])
        if index == 1 then
            row:SetPoint("TOPLEFT", editor.profileText, "BOTTOMLEFT", 0, -18)
        end
        editor.rows[index] = row
    end
    editor.helpText = createBodyText(weightModal, 740, "GameFontHighlightSmall")
    editor.helpText:SetPoint("TOPLEFT", editor.rows[#editor.rows], "BOTTOMLEFT", 0, -14)
    editor.helpText:SetText("Base is the preset value. Live is the scoring value now. Reset removes only that one override.")
    editor.resetAllButton = createActionButton(weightModal, 154, 28, "Reset All Overrides")
    editor.resetAllButton:SetPoint("BOTTOMLEFT", weightModal, "BOTTOMLEFT", 16, 14)
    editor.closeButton = createActionButton(weightModal, 120, 28, "Close Editor")
    editor.closeButton:SetPoint("BOTTOMRIGHT", weightModal, "BOTTOMRIGHT", -16, 14)
    editor.resetAllButton:SetScript("OnClick", function()
        local profileId = select(1, LS:GetActiveProfile())
        if profileId then
            LS:ClearCustomWeights(profileId)
            LS:RefreshUI()
        end
    end)
    editor.closeButton:SetScript("OnClick", function()
        LS:CloseWeightEditor()
    end)
    self.weightEditorFrame = editor

    local capOverlay, capModal = createModalFrame(frame, "Cap Editor", "Edit cap targets and post-cap weights for the active profile. Post-cap is the reduced weight used after the threshold is reached.", 812, 430)
    local capEditor = capOverlay
    capEditor:SetFrameLevel(frame:GetFrameLevel() + 28)
    capEditor.title = capModal.title
    capEditor.description = capModal.description
    capEditor.profileText = capModal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    capEditor.profileText:SetPoint("TOPLEFT", capEditor.description, "BOTTOMLEFT", 0, -14)
    capEditor.profileText:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])
    capEditor.rows = {}
    for index = 1, 6 do
        local row = createCapEditorRow(capModal, capEditor.rows[index - 1])
        if index == 1 then
            row:SetPoint("TOPLEFT", capEditor.profileText, "BOTTOMLEFT", 0, -18)
        end
        capEditor.rows[index] = row
    end
    capEditor.helpText = createBodyText(capModal, 740, "GameFontHighlightSmall")
    capEditor.helpText:SetPoint("TOPLEFT", capEditor.rows[6], "BOTTOMLEFT", 0, -14)
    capEditor.helpText:SetText("Example: hit cap 80 with post-cap 0.15 means hit still counts above 80, but much less.")
    capEditor.resetAllButton = createActionButton(capModal, 132, 28, "Reset All Caps")
    capEditor.resetAllButton:SetPoint("BOTTOMLEFT", capModal, "BOTTOMLEFT", 16, 14)
    capEditor.closeButton = createActionButton(capModal, 120, 28, "Close Editor")
    capEditor.closeButton:SetPoint("BOTTOMRIGHT", capModal, "BOTTOMRIGHT", -16, 14)
    capEditor.resetAllButton:SetScript("OnClick", function()
        local profileId = select(1, LS:GetActiveProfile())
        if profileId then
            LS:ClearCustomCapRules(profileId)
            LS:RefreshUI()
        end
    end)
    capEditor.closeButton:SetScript("OnClick", function()
        LS:CloseCapEditor()
    end)
    self.capEditorFrame = capEditor

    local priorityOverlay, priorityModal = createModalFrame(frame, "Priority Wizard", "Pick your top stats in order. Applying this will replace the custom weight overrides for the active profile.", 812, 520)
    local priorityWizard = priorityOverlay
    priorityWizard:SetFrameLevel(frame:GetFrameLevel() + 27)
    priorityWizard.title = priorityModal.title
    priorityWizard.description = priorityModal.description
    priorityWizard.profileText = priorityModal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    priorityWizard.profileText:SetPoint("TOPLEFT", priorityWizard.description, "BOTTOMLEFT", 0, -14)
    priorityWizard.profileText:SetTextColor(THEME.brightText[1], THEME.brightText[2], THEME.brightText[3])
    priorityWizard.selectionHeader = createSectionTitle(priorityModal, "Selected Order", "TOPLEFT", priorityWizard.profileText, "BOTTOMLEFT", 0, -16)
    priorityWizard.selectionText = createBodyText(priorityModal, 748, "GameFontHighlightSmall")
    priorityWizard.selectionText:SetPoint("TOPLEFT", priorityWizard.selectionHeader, "BOTTOMLEFT", 0, -8)

    priorityWizard.optionButtons = {}
    local columns = { 0, 372 }
    for index = 1, 10 do
        local button = createPriorityOptionButton(priorityModal, 356, 36)
        local column = ((index - 1) % 2) + 1
        local row = math.floor((index - 1) / 2)
        button:SetPoint("TOPLEFT", priorityWizard.selectionText, "BOTTOMLEFT", columns[column], -18 - (row * 46))
        priorityWizard.optionButtons[index] = button
    end

    priorityWizard.helpText = createBodyText(priorityModal, 748, "GameFontHighlightSmall")
    priorityWizard.helpText:SetPoint("TOPLEFT", priorityWizard.optionButtons[9], "BOTTOMLEFT", 0, -18)
    priorityWizard.helpText:SetText("Click stats in the order you want them weighted. The rest of the role's stats will be filled in automatically below your chosen order.")
    priorityWizard.removeLastButton = createActionButton(priorityModal, 128, 28, "Remove Last")
    priorityWizard.removeLastButton:SetPoint("BOTTOMLEFT", priorityModal, "BOTTOMLEFT", 16, 14)
    priorityWizard.resetButton = createActionButton(priorityModal, 118, 28, "Clear Order")
    priorityWizard.resetButton:SetPoint("LEFT", priorityWizard.removeLastButton, "RIGHT", 8, 0)
    priorityWizard.applyButton = createActionButton(priorityModal, 154, 28, "Apply Priorities")
    priorityWizard.applyButton:SetPoint("BOTTOMRIGHT", priorityModal, "BOTTOMRIGHT", -144, 14)
    priorityWizard.closeButton = createActionButton(priorityModal, 120, 28, "Close")
    priorityWizard.closeButton:SetPoint("LEFT", priorityWizard.applyButton, "RIGHT", 8, 0)
    priorityWizard.removeLastButton:SetScript("OnClick", function()
        if LS.priorityWizardSelection and #LS.priorityWizardSelection > 0 then
            table.remove(LS.priorityWizardSelection)
            LS:RefreshUI()
        end
    end)
    priorityWizard.resetButton:SetScript("OnClick", function()
        LS.priorityWizardSelection = {}
        LS:RefreshUI()
    end)
    priorityWizard.applyButton:SetScript("OnClick", function()
        local profileId = LS.priorityWizardProfileId or select(1, LS:GetActiveProfile())
        local success, errorMessage = LS:ApplyPriorityWizardWeights(profileId, LS.priorityWizardSelection)
        if success then
            LS:ClosePriorityWizard()
        else
            priorityWizard.helpText:SetText(errorMessage or "Unable to apply priorities.")
        end
        LS:RefreshUI()
    end)
    priorityWizard.closeButton:SetScript("OnClick", function()
        LS:ClosePriorityWizard()
    end)
    self.priorityWizardFrame = priorityWizard

    self.mainFrame = frame
end

function LS:OpenWeightEditor()
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    self.weightEditorOpen = true
    self.capEditorOpen = false
    self.priorityWizardOpen = false
    self.setupModeOpen = false
    self.wizardStep = nil
    self.mainFrame:Show()
    self:RefreshUI()
end

function LS:CloseWeightEditor()
    self.weightEditorOpen = false
    self:RefreshUI()
end

function LS:OpenCapEditor()
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    self.capEditorOpen = true
    self.weightEditorOpen = false
    self.priorityWizardOpen = false
    self.setupModeOpen = false
    self.wizardStep = nil
    self.mainFrame:Show()
    self:RefreshUI()
end

function LS:CloseCapEditor()
    self.capEditorOpen = false
    self:RefreshUI()
end

function LS:OpenPriorityWizard()
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    self.priorityWizardOpen = true
    self.weightEditorOpen = false
    self.capEditorOpen = false
    self.setupModeOpen = false
    self.wizardStep = nil
    self.priorityWizardProfileId = select(1, self:GetActiveProfile())
    self.priorityWizardSelection = {}
    self.mainFrame:Show()
    self:RefreshUI()
end

function LS:ClosePriorityWizard()
    self.priorityWizardOpen = false
    self.priorityWizardProfileId = nil
    self.priorityWizardSelection = nil
    self:RefreshUI()
end

function LS:OpenSetupModeSelector()
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    self.setupModeOpen = true
    self.weightEditorOpen = false
    self.capEditorOpen = false
    self.priorityWizardOpen = false
    self.wizardStep = nil
    self.mainFrame:Show()
    self:RefreshUI()
end

function LS:CloseSetupModeSelector()
    self.setupModeOpen = false
    self:RefreshUI()
end

function LS:RefreshSetupModeSelector()
    if not self.setupModeFrame then
        return
    end

    if self.setupModeOpen then
        self.setupModeFrame:Show()
    else
        self.setupModeFrame:Hide()
    end
end

function LS:RefreshWizard()
    if not self.wizardFrame then
        return
    end

    local step = self.wizardStep
    if not step then
        self.wizardFrame:Hide()
        return
    end

    local answers = self.wizardAnswers or {}
    local stepData = self:GetWizardStepData(step, answers)
    if not stepData then
        self.wizardFrame:Hide()
        return
    end

    self.wizardFrame:Show()
    self.wizardFrame.title:SetText(stepData.title)
    self.wizardFrame.description:SetText(stepData.description)
    self.wizardFrame.progress:SetText(step .. " / " .. self:GetWizardStepCount(answers))

    for index, button in ipairs(self.wizardFrame.optionButtons) do
        local option = stepData.options[index]
        if option then
            button:Show()
            button.text:SetText(option.title)
            button.detail:SetText(option.description)
            button:SetScript("OnClick", function()
                if step == 1 then
                    LS.wizardAnswers.role = option.value
                    LS.wizardAnswers.focus = nil
                    LS.wizardAnswers.tankStyle = nil
                    LS.wizardAnswers.scaling = nil
                    LS.wizardStep = 2
                    LS:RefreshUI()
                    return
                end

                if step == 2 then
                    LS.wizardAnswers.focus = option.value
                    LS.wizardAnswers.tankStyle = nil
                    LS.wizardAnswers.scaling = nil
                    if LS:RoleUsesTankStyle(LS.wizardAnswers.role) then
                        LS.wizardStep = 3
                        LS:RefreshUI()
                        return
                    end

                    if LS:RoleUsesScaling(LS.wizardAnswers.role) then
                        LS.wizardAnswers.scaling = nil
                        LS.wizardStep = 3
                        LS:RefreshUI()
                        return
                    end

                    LS:FinishSetupWizard(LS:GetRecommendedProfileFromAnswers(LS.wizardAnswers))
                    return
                end

                if step == 3 and LS:RoleUsesTankStyle(LS.wizardAnswers.role) then
                    LS.wizardAnswers.tankStyle = option.value
                    LS.wizardAnswers.scaling = nil
                    LS.wizardStep = 4
                    LS:RefreshUI()
                    return
                end

                LS.wizardAnswers.scaling = option.value
                LS:FinishSetupWizard(LS:GetRecommendedProfileFromAnswers(LS.wizardAnswers))
            end)
        else
            button:Hide()
            button:SetScript("OnClick", nil)
        end
    end

    local recommendedProfileId = self:GetRecommendedProfileFromAnswers(answers)
    if recommendedProfileId and self.profiles[recommendedProfileId] then
        local profile = self.profiles[recommendedProfileId]
        self.wizardFrame.summaryText:SetText(
            self:GetProfileDisplayName(recommendedProfileId, answers) ..
            "\n" .. self:GetProfileSummaryText(recommendedProfileId, profile, answers) ..
            "\nPriority: " .. self:GetProfilePriorityText(profile, answers)
        )
    else
        self.wizardFrame.summaryText:SetText("Your answers will recommend a preset here as soon as enough information is selected.")
    end

    if step == 1 then
        self.wizardFrame.backButton:Disable()
        setCustomButtonState(self.wizardFrame.backButton, false)
        self.wizardFrame.backButton.text:SetTextColor(0.50, 0.48, 0.44)
    else
        self.wizardFrame.backButton:Enable()
        setCustomButtonState(self.wizardFrame.backButton, false)
    end
end

function LS:RefreshWeightEditor()
    if not self.weightEditorFrame then
        return
    end

    if not self.weightEditorOpen then
        self.weightEditorFrame:Hide()
        return
    end

    local profileId, profile = self:GetActiveProfile()
    if not profileId or not profile then
        self.weightEditorFrame:Hide()
        return
    end

    local entries = self:GetEditableWeightEntries(profileId)
    self.weightEditorFrame:Show()
    self.weightEditorFrame.profileText:SetText(self:GetProfileDisplayName(profileId) .. "  -  custom overrides: " .. self:GetCustomWeightCount(profileId))

    for index, row in ipairs(self.weightEditorFrame.rows) do
        local entry = entries[index]
        if entry then
            row:Show()
            row.statKey = entry.statKey
            row.label:SetText(entry.label)
            row.current:SetText(string.format("Base %.2f  /  Live %.2f", entry.baseWeight, entry.effectiveWeight))
            row.input:SetText(string.format("%.2f", entry.effectiveWeight))
            row.note:SetText(entry.customized and "custom override" or "preset value")
            row.applyButton:SetScript("OnClick", function()
                local value = tonumber(row.input:GetText())
                if not value then
                    row.note:SetText("enter a number")
                    return
                end

                local success, errorMessage = LS:SetCustomWeight(profileId, entry.statKey, value)
                if success then
                    LS:RefreshUI()
                else
                    row.note:SetText(errorMessage or "failed")
                end
            end)
            row.resetButton:SetScript("OnClick", function()
                LS:ClearCustomWeight(profileId, entry.statKey)
                LS:RefreshUI()
            end)
            row.input:SetScript("OnEnterPressed", function()
                row.applyButton:Click()
            end)
        else
            row:Hide()
            row.input:SetScript("OnEnterPressed", nil)
            row.applyButton:SetScript("OnClick", nil)
            row.resetButton:SetScript("OnClick", nil)
        end
    end
end

function LS:RefreshCapEditor()
    if not self.capEditorFrame then
        return
    end

    if not self.capEditorOpen then
        self.capEditorFrame:Hide()
        return
    end

    local profileId, profile = self:GetActiveProfile()
    if not profileId or not profile then
        self.capEditorFrame:Hide()
        return
    end

    local entries = self:GetEditableCapEntries(profileId)
    self.capEditorFrame:Show()
    self.capEditorFrame.profileText:SetText(self:GetProfileDisplayName(profileId) .. "  -  custom cap overrides: " .. self:GetCustomCapCount(profileId))

    for index, row in ipairs(self.capEditorFrame.rows) do
        local entry = entries[index]
        if entry then
            row:Show()
            row.statKey = entry.statKey
            row.label:SetText(entry.label)
            row.current:SetText(string.format("Base %.0f / %.2f  Live %.0f / %.2f", entry.baseCap, entry.basePostCapWeight, entry.effectiveCap, entry.effectivePostCapWeight))
            row.capInput:SetText(string.format("%.0f", entry.effectiveCap))
            row.postInput:SetText(string.format("%.2f", entry.effectivePostCapWeight))
            row.note:SetText(entry.customized and "custom cap" or "preset cap")
            row.applyButton:SetScript("OnClick", function()
                local capValue = tonumber(row.capInput:GetText())
                local postValue = tonumber(row.postInput:GetText())
                if not capValue or not postValue then
                    row.note:SetText("enter cap + post")
                    return
                end

                local success, errorMessage = LS:SetCustomCapRule(profileId, entry.statKey, capValue, postValue)
                if success then
                    LS:RefreshUI()
                else
                    row.note:SetText(errorMessage or "failed")
                end
            end)
            row.resetButton:SetScript("OnClick", function()
                LS:ClearCustomCapRule(profileId, entry.statKey)
                LS:RefreshUI()
            end)
            row.capInput:SetScript("OnEnterPressed", function()
                row.applyButton:Click()
            end)
            row.postInput:SetScript("OnEnterPressed", function()
                row.applyButton:Click()
            end)
        else
            row:Hide()
            row.capInput:SetScript("OnEnterPressed", nil)
            row.postInput:SetScript("OnEnterPressed", nil)
            row.applyButton:SetScript("OnClick", nil)
            row.resetButton:SetScript("OnClick", nil)
        end
    end
end

function LS:RefreshPriorityWizard()
    if not self.priorityWizardFrame then
        return
    end

    if not self.priorityWizardOpen then
        self.priorityWizardFrame:Hide()
        return
    end

    local profileId = self.priorityWizardProfileId or select(1, self:GetActiveProfile())
    local profile = profileId and self.profiles and self.profiles[profileId] or nil
    if not profile then
        self.priorityWizardFrame:Hide()
        return
    end

    if not self.priorityWizardSelection then
        self.priorityWizardSelection = {}
    end

    local entries = self:GetPriorityWizardEntries(profileId)
    local selectedLookup = {}
    for orderIndex, statKey in ipairs(self.priorityWizardSelection) do
        selectedLookup[statKey] = orderIndex
    end

    self.priorityWizardFrame:Show()
    self.priorityWizardFrame.profileText:SetText(self:GetProfileDisplayName(profileId))
    self.priorityWizardFrame.selectionText:SetText(self:GetPriorityOrderText(profileId, self.priorityWizardSelection))
    self.priorityWizardFrame.helpText:SetText("Click stats in the order you want them weighted. The rest of the role's stats will be filled in automatically below your chosen order.")

    for index, button in ipairs(self.priorityWizardFrame.optionButtons) do
        local entry = entries[index]
        if entry then
            button:Show()
            local selectedIndex = selectedLookup[entry.statKey]
            button.text:SetText((selectedIndex and (selectedIndex .. ". ") or "") .. entry.label)
            button.detail:SetText(string.format("Current %.2f", entry.currentWeight or 0))
            button.isSelected = selectedIndex ~= nil
            setCustomButtonState(button, button.isSelected)
            button:SetScript("OnClick", function()
                if selectedLookup[entry.statKey] then
                    return
                end

                table.insert(LS.priorityWizardSelection, entry.statKey)
                LS:RefreshUI()
            end)
        else
            button:Hide()
            button:SetScript("OnClick", nil)
        end
    end
end

function LS:RefreshUI()
    if self.InvalidateTooltipCaches then
        self:InvalidateTooltipCaches()
    end

    if not self.mainFrame then
        return
    end

    local profileId, profile = self:GetActiveProfile()
    if not profile then
        return
    end

    self.mainFrame.profileName:SetText(self:GetProfileDisplayName(profileId))
    self.mainFrame.profileSummary:SetText(self:GetProfileSummaryText(profileId, profile))
    self.mainFrame.profilePlaystyle:SetText(profile.playstyle)
    self.mainFrame.profilePriority:SetText(self:GetProfilePriorityText(profile))

    local recommendedProfileId = self.db.setup and self.db.setup.recommendedProfile
    local customWeightCount = self:GetCustomWeightCount(profileId)
    local customCapCount = self:GetCustomCapCount(profileId)
    if recommendedProfileId and self.profiles[recommendedProfileId] then
        local text = "Recommended: " .. self:GetProfileDisplayName(recommendedProfileId)
        if customWeightCount > 0 then
            text = text .. "\nWeight overrides: " .. customWeightCount
        end
        if customCapCount > 0 then
            text = text .. "\nCap overrides: " .. customCapCount
        end
        self.mainFrame.recommendationText:SetText(text)
    else
        local text = "Run setup for a guided starting profile."
        if customWeightCount > 0 then
            text = text .. "\nWeight overrides: " .. customWeightCount
        end
        if customCapCount > 0 then
            text = text .. "\nCap overrides: " .. customCapCount
        end
        self.mainFrame.recommendationText:SetText(text)
    end

    for buttonProfileId, button in pairs(self.mainFrame.profileButtons) do
        local selected = buttonProfileId == profileId
        button.isSelected = selected
        if selected then
            button:Disable()
        else
            button:Enable()
        end
        setCustomButtonState(button, selected)
    end

    self.mainFrame.showScoresCheck:SetChecked(self.db.showTooltipScores)
    self.mainFrame.compareItemsCheck:SetChecked(self.db.compareEquipped)
    self.mainFrame.showBreakdownCheck:SetChecked(self.db.showBreakdown)
    self.mainFrame.showDebugCheck:SetChecked(self.db.showDebugDetails)

    self:RefreshWizard()
    self:RefreshWeightEditor()
    self:RefreshCapEditor()
    self:RefreshPriorityWizard()
    self:RefreshSetupModeSelector()
end
